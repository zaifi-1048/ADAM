import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ai_voice_chat/models/task_model.dart';

class VoiceReminderService {
  static final VoiceReminderService instance = VoiceReminderService._();
  VoiceReminderService._();

  final FlutterTts _tts = FlutterTts();
  final Map<String, Timer> _timers = {};
  StreamSubscription? _sub;
  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  Future<void> init(FlutterLocalNotificationsPlugin plugin) async {
    if (_initialized) return;
    _initialized = true;
    _plugin = plugin;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startWatching(user.uid);
      } else {
        _stop();
      }
    });
  }

  void _startWatching(String uid) {
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.pending.name)
        .snapshots()
        .listen((snap) {
      final tasks = snap.docs
          .map((d) => TaskModel.fromMap(d.data()))
          .where((t) => t.dueDate != null)
          .toList();
      _reschedule(tasks);
    });
  }

  void _stop() {
    _sub?.cancel();
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  void _reschedule(List<TaskModel> tasks) {
    final currentIds = tasks.map((t) => t.id).toSet();

    // Cancel timers for removed/completed tasks
    for (final id in _timers.keys.where((id) => !currentIds.contains(id)).toList()) {
      _timers[id]?.cancel();
      _timers.remove(id);
      _cancelNotification(id);
    }

    for (final task in tasks) {
      final due = task.dueDate!;
      final now = DateTime.now();
      final diff = due.difference(now);

      // Skip if already overdue or more than 7 days away
      if (diff.isNegative || diff.inDays > 7) {
        _timers[task.id]?.cancel();
        _timers.remove(task.id);
        continue;
      }

      // Schedule push notification (fires even when app is closed)
      _scheduleNotification(task, due);

      // Schedule foreground TTS timer
      _timers[task.id]?.cancel();
      _timers[task.id] = Timer(diff, () => _speakForeground(task));
    }
  }

  Future<void> _scheduleNotification(TaskModel task, DateTime due) async {
    if (_plugin == null) return;
    try {
      final notifId = task.id.hashCode.abs() % 100000;
      final tzDue = tz.TZDateTime.from(due, tz.local);
      final isReminder = task.isReminder;
      final type = isReminder ? 'Reminder' : 'Task';

      await _plugin!.zonedSchedule(
        notifId,
        'Boss! $type Due 🔔',
        '"${task.title}" — Time\'s up!',
        tzDue,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'adam_reminders_ch',
            'ADAM Reminders',
            channelDescription: 'Task and reminder alerts from ADAM',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '${task.id}|||${task.title}|||${task.isReminder}',
      );
    } catch (_) {}
  }

  Future<void> _cancelNotification(String taskId) async {
    await _plugin?.cancel(taskId.hashCode.abs() % 100000);
  }

  // Called when app is open and timer fires
  Future<void> _speakForeground(TaskModel task) async {
    final type = task.isReminder ? 'reminder' : 'task';
    final messages = [
      'Boss! Time to get your $type done. ${task.title}!',
      'Boss! ${task.title} is due right now. Don\'t forget!',
      'Hey Boss! Your $type ${task.title} needs your attention right now!',
    ];
    final msg = messages[DateTime.now().second % messages.length];
    await _tts.speak(msg);
    _timers.remove(task.id);
  }

  // Called when user taps the notification (background or killed state)
  Future<void> speakFromNotificationTap(String payload) async {
    try {
      final parts = payload.split('|||');
      if (parts.length < 3) return;
      final title = parts[1];
      final isReminder = parts[2] == 'true';
      final type = isReminder ? 'reminder' : 'task';
      final text = 'Boss! Your $type "$title" is due now. Time to get it done!';

      // Use a fresh TTS instance to avoid audio focus issues
      final freshTts = FlutterTts();
      await freshTts.setLanguage('en-US');
      await freshTts.setSpeechRate(0.42);
      await freshTts.setVolume(1.0);
      await freshTts.setPitch(1.0);
      // Wait for app UI to settle
      await Future.delayed(const Duration(seconds: 2));
      await freshTts.speak(text);
    } catch (_) {}
  }

  void dispose() {
    _stop();
    _initialized = false;
  }
}
