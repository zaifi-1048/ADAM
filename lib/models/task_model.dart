import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed, cancelled }

class TaskModel {
  final String id;
  final String uid;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isReminder;
  final bool isSynced;

  TaskModel({
    required this.id,
    required this.uid,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.dueDate,
    required this.createdAt,
    this.updatedAt,
    this.isReminder = false,
    this.isSynced = true,
  });

  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != TaskStatus.completed;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
          updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isReminder': isReminder,
      'isSynced': isSynced,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      uid: map['uid'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isReminder: map['isReminder'] as bool? ?? false,
      isSynced: map['isSynced'] as bool? ?? true,
    );
  }

  TaskModel copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? updatedAt,
    bool? isReminder,
    bool? isSynced,
  }) {
    return TaskModel(
      id: id,
      uid: uid,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReminder: isReminder ?? this.isReminder,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
