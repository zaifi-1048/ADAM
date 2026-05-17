import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:ai_voice_chat/models/task_model.dart';

/// Manages tasks and reminders in Firestore.
///
/// Firestore schema:
///   users/{uid}/tasks/{taskId}
class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _tasksRef(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<TaskModel> createTask({
    required String uid,
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    bool isReminder = false,
  }) async {
    final task = TaskModel(
      id: _uuid.v4(),
      uid: uid,
      title: title,
      description: description,
      priority: priority,
      status: TaskStatus.pending,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      isReminder: isReminder,
    );
    await _tasksRef(uid).doc(task.id).set(task.toMap());
    return task;
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Real-time stream of all tasks, newest first.
  Stream<List<TaskModel>> watchTasks(String uid) {
    return _tasksRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => TaskModel.fromMap(d.data())).toList(),
        );
  }

  /// Real-time stream of pending tasks only.
  Stream<List<TaskModel>> watchPendingTasks(String uid) {
    return _tasksRef(uid)
        .where('status', isEqualTo: TaskStatus.pending.name)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => TaskModel.fromMap(d.data())).toList(),
        );
  }

  /// Real-time stream of reminders only.
  Stream<List<TaskModel>> watchReminders(String uid) {
    return _tasksRef(uid)
        .where('isReminder', isEqualTo: true)
        .where('status', isEqualTo: TaskStatus.pending.name)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => TaskModel.fromMap(d.data())).toList(),
        );
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<void> updateTaskStatus(
    String uid,
    String taskId,
    TaskStatus status,
  ) async {
    await _tasksRef(uid).doc(taskId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTask(String uid, TaskModel task) async {
    await _tasksRef(uid).doc(task.id).update(
          task.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteTask(String uid, String taskId) async {
    await _tasksRef(uid).doc(taskId).delete();
  }
}
