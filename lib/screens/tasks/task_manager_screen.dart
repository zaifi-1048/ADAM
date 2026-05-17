import 'dart:convert';
import 'package:ai_voice_chat/config/api_keys.dart';
import 'package:ai_voice_chat/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});
  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen>
    with TickerProviderStateMixin {
  static const String _groqApiKey = openAiKey;
  static const String _groqUrl =
      'https://api.openai.com/v1/chat/completions';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final _uuid = const Uuid();
  final SpeechToText _speech = SpeechToText();

  late TabController _tabController;
  bool _speechAvailable = false;
  bool _isAiThinking = false;
  String _selectedFilter = 'All';
  int _selectedTabIndex = 0;

  final List<String> _filters = ['All', 'Today', 'Upcoming', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(
      () => setState(() => _selectedTabIndex = _tabController.index),
    );
    _initSpeech();
    _setupNotificationChannel();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  Future<void> _setupNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'adam_tasks_channel',
        'ADAM Task Reminders',
        description: 'Reminders for tasks, notes and events',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Channel setup error: $e');
    }
  }

  Future<void> _scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'adam_tasks_channel',
            'ADAM Task Reminders',
            channelDescription: 'Reminders for tasks, notes and events',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFF4FD8EB),
            enableLights: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          );
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id.hashCode.abs() % 100000,
        '⏰ ADAM Reminder: $title',
        body.isNotEmpty ? body : 'Time to complete your task!',
        scheduledDate,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  Future<void> _cancelNotification(String id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id.hashCode.abs() % 100000);
    } catch (e) {
      debugPrint('Cancel notification error: $e');
    }
  }

  Future<void> _saveToHistory({
    required String action,
    required String type,
    required String title,
  }) async {
    if (_uid == null) return;
    try {
      await _db.collection('users').doc(_uid).collection('task_history').add({
        'action': action,
        'type': type,
        'title': title,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('History save error: $e');
    }
  }

  void _showAddDialog({String type = 'task'}) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String priority = 'Medium';
    String category = 'Personal';
    bool isListeningLocal = false;
    bool isSaving = false;
    final categories = ['Personal', 'Work', 'Study', 'Health', 'Other'];
    final priorities = ['Low', 'Medium', 'High'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getTypeIcon(type),
                        color: _getTypeColor(type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'New ${type.capitalize}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        if (!_speechAvailable) return;
                        if (isListeningLocal) {
                          await _speech.stop();
                          setSheet(() => isListeningLocal = false);
                        } else {
                          setSheet(() => isListeningLocal = true);
                          await _speech.listen(
                            onResult: (result) {
                              titleCtrl.text = result.recognizedWords;
                              if (result.finalResult)
                                setSheet(() => isListeningLocal = false);
                            },
                            listenFor: const Duration(seconds: 15),
                            pauseFor: const Duration(seconds: 3),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isListeningLocal
                              ? const Color(0xFF4FD8EB)
                              : const Color(0xFF4FD8EB).withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4FD8EB).withOpacity(0.4),
                          ),
                        ),
                        child: Icon(
                          isListeningLocal ? Icons.stop : Icons.mic,
                          color: isListeningLocal
                              ? Colors.black
                              : const Color(0xFF4FD8EB),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildModalInputField(
                  controller: titleCtrl,
                  hint: type == 'note'
                      ? 'Note title...'
                      : type == 'event'
                      ? 'Event name...'
                      : 'Task title...',
                  icon: Icons.title,
                ),
                const SizedBox(height: 12),
                _buildModalInputField(
                  controller: descCtrl,
                  hint: type == 'note'
                      ? 'Write your note here...'
                      : 'Add description (optional)...',
                  icon: Icons.notes,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF4FD8EB),
                                  surface: Color(0xFF1C2229),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (date != null) setSheet(() => selectedDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF4FD8EB),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  selectedDate != null
                                      ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                      : 'Pick date',
                                  style: TextStyle(
                                    color: selectedDate != null
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF4FD8EB),
                                  surface: Color(0xFF1C2229),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (time != null) setSheet(() => selectedTime = time);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF4FD8EB),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedTime != null
                                    ? selectedTime!.format(context)
                                    : 'Pick time',
                                style: TextStyle(
                                  color: selectedTime != null
                                      ? Colors.white
                                      : Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (type != 'note') ...[
                  const Text(
                    'Priority',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: priorities.map((p) {
                      final isSel = priority == p;
                      return GestureDetector(
                        onTap: () => setSheet(() => priority = p),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? _getPriorityColor(p).withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? _getPriorityColor(p)
                                  : Colors.white12,
                            ),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              color: isSel
                                  ? _getPriorityColor(p)
                                  : Colors.white54,
                              fontSize: 11,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Category',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: categories.map((cat) {
                    final isSel = category == cat;
                    return GestureDetector(
                      onTap: () => setSheet(() => category = cat),
                      child: Chip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: isSel
                            ? const Color(0xFF4FD8EB)
                            : Colors.white.withOpacity(0.05),
                        side: BorderSide(
                          color: isSel
                              ? const Color(0xFF4FD8EB)
                              : Colors.white12,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // AI Suggest
                GestureDetector(
                  onTap: () async {
                    if (titleCtrl.text.isEmpty) {
                      Get.snackbar(
                        'Tip',
                        'Enter a title first',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange.withOpacity(0.8),
                        colorText: Colors.white,
                      );
                      return;
                    }
                    setSheet(() => _isAiThinking = true);
                    final suggestion = await _getAiSuggestion(
                      titleCtrl.text,
                      type,
                    );
                    setSheet(() {
                      _isAiThinking = false;
                      descCtrl.text = suggestion;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purpleAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isAiThinking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.purpleAccent,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.auto_awesome,
                                color: Colors.purpleAccent,
                                size: 16,
                              ),
                        const SizedBox(width: 8),
                        Text(
                          _isAiThinking
                              ? 'ADAM is thinking...'
                              : 'AI Suggest Description',
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Save button
                GestureDetector(
                  onTap: isSaving
                      ? null
                      : () async {
                          if (titleCtrl.text.trim().isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please enter a title',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red.withOpacity(0.8),
                              colorText: Colors.white,
                            );
                            return;
                          }
                          setSheet(() => isSaving = true);
                          try {
                            await _saveItem(
                              type: type,
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              date: selectedDate,
                              time: selectedTime,
                              priority: priority,
                              category: category,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setSheet(() => isSaving = false);
                            Get.snackbar(
                              'Error',
                              'Could not save: $e',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red.withOpacity(0.8),
                              colorText: Colors.white,
                            );
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSaving
                            ? [Colors.grey, Colors.grey]
                            : [
                                const Color(0xFF4FD8EB),
                                const Color(0xFF00C9FF),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSaving
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFF4FD8EB).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(
                      child: isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Saving...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Save ${type.capitalize}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _getAiSuggestion(String title, String type) async {
    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are ADAM, a smart AI assistant. Generate a brief, helpful description for a $type. Keep it under 50 words.',
            },
            {
              'role': 'user',
              'content': 'Generate description for $type: "$title"',
            },
          ],
          'max_tokens': 100,
          'temperature': 0.7,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<void> _saveItem({
    required String type,
    required String title,
    required String description,
    DateTime? date,
    TimeOfDay? time,
    String priority = 'Medium',
    String category = 'Personal',
  }) async {
    if (_uid == null) return;
    DateTime? reminderDateTime;
    if (date != null && time != null) {
      reminderDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    } else if (date != null) {
      reminderDateTime = DateTime(date.year, date.month, date.day, 9, 0);
    }
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.collection('users').doc(_uid).collection('tasks').doc(id).set({
      'id': id,
      'uid': _uid,
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      'category': category,
      'isCompleted': false,
      'reminderDateTime': reminderDateTime != null
          ? Timestamp.fromDate(reminderDateTime)
          : null,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    await _saveToHistory(action: 'Created', type: type, title: title);
    if (reminderDateTime != null && reminderDateTime.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: id,
        title: title,
        body: description.isNotEmpty ? description : 'Time for your $type!',
        scheduledTime: reminderDateTime,
      );
      Get.snackbar(
        '✅ Saved & Reminder Set!',
        'Reminder set for ${reminderDateTime.day}/${reminderDateTime.month} at ${time?.format(context) ?? "9:00 AM"}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4FD8EB).withOpacity(0.8),
        colorText: Colors.black,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        '✅ Saved!',
        '$type "$title" added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4FD8EB).withOpacity(0.8),
        colorText: Colors.black,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _toggleComplete(
    String id,
    bool current, {
    String title = '',
    String type = 'task',
  }) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).collection('tasks').doc(id).update({
      'isCompleted': !current,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    await _saveToHistory(
      action: !current ? 'Completed' : 'Reopened',
      type: type,
      title: title,
    );
  }

  Future<void> _deleteItem(
    String id, {
    String title = '',
    String type = 'task',
  }) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .doc(id)
        .delete();
    await _cancelNotification(id);
    await _saveToHistory(action: 'Deleted', type: type, title: title);
    Get.snackbar(
      '🗑️ Deleted',
      'Item removed',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.7),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _showHistorySheet() {
    if (_uid == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Activity History",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('users')
                    .doc(_uid)
                    .collection('task_history')
                    .orderBy('timestamp', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4FD8EB),
                      ),
                    );
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty)
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, color: Colors.white24, size: 60),
                          SizedBox(height: 16),
                          Text(
                            "No history yet",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final action = data['action'] as String? ?? '';
                      final type = data['type'] as String? ?? 'task';
                      final title = data['title'] as String? ?? '';
                      final ts = data['timestamp'] as Timestamp?;
                      final date = ts != null
                          ? _formatHistoryDate(ts.toDate())
                          : '';
                      Color actionColor;
                      IconData actionIcon;
                      switch (action) {
                        case 'Created':
                          actionColor = const Color(0xFF4FD8EB);
                          actionIcon = Icons.add_circle_outline;
                          break;
                        case 'Completed':
                          actionColor = Colors.greenAccent;
                          actionIcon = Icons.check_circle_outline;
                          break;
                        case 'Deleted':
                          actionColor = Colors.redAccent;
                          actionIcon = Icons.delete_outline;
                          break;
                        case 'Reopened':
                          actionColor = Colors.orangeAccent;
                          actionIcon = Icons.refresh;
                          break;
                        default:
                          actionColor = Colors.white54;
                          actionIcon = Icons.history;
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: actionColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: actionColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                actionIcon,
                                color: actionColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$action ${type.capitalize}',
                                    style: TextStyle(
                                      color: actionColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              date,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1C2229),
                      title: const Text(
                        'Clear History',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Delete all activity history?',
                        style: TextStyle(color: Colors.grey),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final snap = await _db
                        .collection('users')
                        .doc(_uid)
                        .collection('task_history')
                        .get();
                    for (final doc in snap.docs) await doc.reference.delete();
                    if (ctx.mounted) Navigator.pop(ctx);
                    Get.snackbar(
                      'Done',
                      'History cleared',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green.withOpacity(0.8),
                      colorText: Colors.white,
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_sweep,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Clear History',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHistoryDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}';
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'task':
        return const Color(0xFF4FD8EB);
      case 'note':
        return Colors.purpleAccent;
      case 'event':
        return Colors.orangeAccent;
      default:
        return const Color(0xFF4FD8EB);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'task':
        return Icons.check_circle_outline;
      case 'note':
        return Icons.sticky_note_2_outlined;
      case 'event':
        return Icons.event_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.orangeAccent;
      case 'Low':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  String _formatDateTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays == 0)
      return 'Today ${TimeOfDay.fromDateTime(dt).format(context)}';
    if (diff.inDays == 1)
      return 'Tomorrow ${TimeOfDay.fromDateTime(dt).format(context)}';
    if (diff.inDays < 0) return 'Overdue';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Stream<QuerySnapshot> _getStream(String type) => _db
      .collection('users')
      .doc(_uid)
      .collection('tasks')
      .where('type', isEqualTo: type)
      .snapshots();

  Widget _buildModalInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white38, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data) {
    final id = data['id'] as String;
    final title = data['title'] as String? ?? '';
    final desc = data['description'] as String? ?? '';
    final type = data['type'] as String? ?? 'task';
    final priority = data['priority'] as String? ?? 'Medium';
    final category = data['category'] as String? ?? 'Personal';
    final isCompleted = data['isCompleted'] as bool? ?? false;
    final reminderTs = data['reminderDateTime'] as Timestamp?;

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      confirmDismiss: (dir) async => await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1C2229),
          title: const Text('Delete', style: TextStyle(color: Colors.white)),
          content: Text(
            'Delete "$title"?',
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _deleteItem(id, title: title, type: type),
      child: GestureDetector(
        onTap: () => _showDetailDialog(data),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? Colors.white12
                  : _getTypeColor(type).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleComplete(
                      id,
                      isCompleted,
                      title: title,
                      type: type,
                    ),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.greenAccent.withOpacity(0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted
                              ? Colors.greenAccent
                              : _getTypeColor(type).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.greenAccent,
                              size: 14,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isCompleted ? Colors.white38 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (type != 'note')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: _getPriorityColor(priority),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    desc,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(type),
                            color: _getTypeColor(type),
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            type.capitalize!,
                            style: TextStyle(
                              color: _getTypeColor(type),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (reminderTs != null) ...[
                      Icon(
                        Icons.alarm,
                        color: reminderTs.toDate().isBefore(DateTime.now())
                            ? Colors.redAccent
                            : const Color(0xFF4FD8EB),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(reminderTs),
                        style: TextStyle(
                          color: reminderTs.toDate().isBefore(DateTime.now())
                              ? Colors.redAccent
                              : Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> data) {
    final title = data['title'] as String? ?? '';
    final desc = data['description'] as String? ?? '';
    final type = data['type'] as String? ?? 'task';
    final priority = data['priority'] as String? ?? 'Medium';
    final category = data['category'] as String? ?? 'Personal';
    final isCompleted = data['isCompleted'] as bool? ?? false;
    final reminderTs = data['reminderDateTime'] as Timestamp?;
    final id = data['id'] as String;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _detailChip(type.capitalize!, _getTypeColor(type)),
                _detailChip(category, Colors.white54),
                if (type != 'note')
                  _detailChip(priority, _getPriorityColor(priority)),
                if (isCompleted) _detailChip('Completed ✅', Colors.greenAccent),
                if (reminderTs != null)
                  _detailChip(
                    '⏰ ${_formatDateTime(reminderTs)}',
                    reminderTs.toDate().isBefore(DateTime.now())
                        ? Colors.redAccent
                        : const Color(0xFF4FD8EB),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleComplete(
                        id,
                        isCompleted,
                        title: title,
                        type: type,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isCompleted ? 'Mark Incomplete' : 'Mark Complete',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteItem(id, title: title, type: type);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
    ),
  );

  Widget _buildTabContent(String type) {
    if (_uid == null)
      return const Center(
        child: Text('Not logged in', style: TextStyle(color: Colors.white54)),
      );
    return StreamBuilder<QuerySnapshot>(
      stream: _getStream(type),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 50,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4FD8EB)),
          );
        List<QueryDocumentSnapshot> docs = List.from(snapshot.data?.docs ?? []);
        docs.sort((a, b) {
          final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTs == null || bTs == null) return 0;
          return bTs.compareTo(aTs);
        });
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));
        if (_selectedFilter == 'Completed') {
          docs = docs
              .where((d) => (d.data() as Map)['isCompleted'] == true)
              .toList();
        } else if (_selectedFilter == 'Today') {
          docs = docs.where((d) {
            final ts = (d.data() as Map)['reminderDateTime'] as Timestamp?;
            if (ts == null) return false;
            final dt = ts.toDate();
            return dt.isAfter(todayStart) && dt.isBefore(todayEnd);
          }).toList();
        } else if (_selectedFilter == 'Upcoming') {
          docs = docs.where((d) {
            final ts = (d.data() as Map)['reminderDateTime'] as Timestamp?;
            final isC = (d.data() as Map)['isCompleted'] as bool? ?? false;
            if (ts == null || isC) return false;
            return ts.toDate().isAfter(now);
          }).toList();
        }
        if (docs.isEmpty)
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type).withOpacity(0.3),
                  size: 70,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${type}s yet',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add a new $type',
                  style: const TextStyle(color: Colors.white24, fontSize: 13),
                ),
              ],
            ),
          );
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) =>
              _buildTaskCard(docs[index].data() as Map<String, dynamic>),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accentCyan = Color(0xFF4FD8EB);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Task Manager",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                "Powered by ADAM AI",
                                style: GoogleFonts.jetBrainsMono(
                                  color: accentCyan,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _showHistorySheet,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Icon(
                              Icons.history,
                              color: Colors.white54,
                              size: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StreamBuilder<QuerySnapshot>(
                          stream: _uid != null
                              ? _db
                                    .collection('users')
                                    .doc(_uid)
                                    .collection('tasks')
                                    .where('isCompleted', isEqualTo: false)
                                    .snapshots()
                              : null,
                          builder: (ctx, snap) {
                            final count = snap.data?.docs.length ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: accentCyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accentCyan.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.pending_actions,
                                    color: Color(0xFF4FD8EB),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$count',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: accentCyan,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 32,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        itemBuilder: (ctx, i) {
                          final isSel = _selectedFilter == _filters[i];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedFilter = _filters[i]),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? accentCyan
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel ? accentCyan : Colors.white12,
                                ),
                              ),
                              child: Text(
                                _filters[i],
                                style: TextStyle(
                                  color: isSel ? Colors.black : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: accentCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentCyan.withOpacity(0.5),
                          ),
                        ),
                        labelColor: accentCyan,
                        unselectedLabelColor: Colors.white38,
                        labelStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 15),
                                SizedBox(width: 4),
                                Text('Tasks'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sticky_note_2_outlined, size: 15),
                                SizedBox(width: 4),
                                Text('Notes'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_outlined, size: 15),
                                SizedBox(width: 4),
                                Text('Events'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent('task'),
                    _buildTabContent('note'),
                    _buildTabContent('event'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'voice',
            mini: true,
            backgroundColor: Colors.purpleAccent.withOpacity(0.9),
            onPressed: () {
              final type = _selectedTabIndex == 0
                  ? 'task'
                  : _selectedTabIndex == 1
                  ? 'note'
                  : 'event';
              _showAddDialog(type: type);
            },
            child: const Icon(Icons.mic, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add',
            backgroundColor: accentCyan,
            onPressed: () {
              final type = _selectedTabIndex == 0
                  ? 'task'
                  : _selectedTabIndex == 1
                  ? 'note'
                  : 'event';
              _showAddDialog(type: type);
            },
            icon: const Icon(Icons.add, color: Colors.black),
            label: Text(
              _selectedTabIndex == 0
                  ? 'New Task'
                  : _selectedTabIndex == 1
                  ? 'New Note'
                  : 'New Event',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

