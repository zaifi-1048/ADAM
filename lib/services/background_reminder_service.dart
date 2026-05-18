import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ai_voice_chat/firebase_options.dart';
import 'package:ai_voice_chat/models/task_model.dart';

// ── Entry point for background isolate ─────────────────────────────────────
@pragma('vm:entry-point')
Future<void> onBackgroundServiceStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final tts = FlutterTts();
  await tts.setLanguage('en-US');
  await tts.setSpeechRate(0.42);
  await tts.setVolume(1.0);
  await tts.setPitch(1.0);

  final Map<String, Timer> timers = {};
  StreamSubscription? sub;

  // Show a persistent notification so Android keeps the service alive
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'ADAM',
      content: 'Monitoring your tasks and reminders...',
    );
  }

  Future<void> scheduleTimers(List<TaskModel> tasks) async {
    final currentIds = tasks.map((t) => t.id).toSet();

    // Cancel removed tasks
    for (final id in timers.keys.where((id) => !currentIds.contains(id)).toList()) {
      timers[id]?.cancel();
      timers.remove(id);
    }

    for (final task in tasks) {
      final due = task.dueDate!;
      final now = DateTime.now();
      final diff = due.difference(now);

      if (diff.isNegative || diff.inDays > 7) {
        timers[task.id]?.cancel();
        timers.remove(task.id);
        continue;
      }

      timers[task.id]?.cancel();
      timers[task.id] = Timer(diff, () async {
        final type = task.isReminder ? 'reminder' : 'task';
        final msgs = [
          'Boss! Your $type ${task.title} is due now. Time to get it done!',
          'Hey Boss! ${task.title} needs your attention right now!',
          'Boss! Don\'t forget your $type ${task.title}. It\'s due now!',
        ];
        final msg = msgs[DateTime.now().second % msgs.length];
        await tts.speak(msg);
        timers.remove(task.id);
      });
    }
  }

  // Watch tasks from Firestore
  FirebaseAuth.instance.authStateChanges().listen((user) {
    sub?.cancel();
    if (user == null) return;

    sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.pending.name)
        .snapshots()
        .listen((snap) {
      final tasks = snap.docs
          .map((d) => TaskModel.fromMap(d.data()))
          .where((t) => t.dueDate != null)
          .toList();
      scheduleTimers(tasks);
    });
  });

  // Listen for stop signal
  service.on('stop').listen((_) {
    sub?.cancel();
    for (final t in timers.values) {
      t.cancel();
    }
    service.stopSelf();
  });
}

// ── Public API ──────────────────────────────────────────────────────────────
class BackgroundReminderService {
  static Future<void> init() async {
    final service = FlutterBackgroundService();

    // Create notification channel for the background service
    const channel = AndroidNotificationChannel(
      'adam_bg_service_ch',
      'ADAM Background Service',
      description: 'Keeps ADAM running to deliver voice reminders',
      importance: Importance.low,
    );
    final notifPlugin = FlutterLocalNotificationsPlugin();
    await notifPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'adam_bg_service_ch',
        initialNotificationTitle: 'ADAM',
        initialNotificationContent: 'Monitoring your reminders...',
        foregroundServiceNotificationId: 9001,
      ),
      iosConfiguration: IosConfiguration(autoStart: true),
    );

    await service.startService();
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
  }
}
