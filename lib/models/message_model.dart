import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageRole { user, assistant }

enum MessageType { text, voice }

class MessageModel {
  final String id;
  final String? sessionId; // ← nullable for no-save mode
  final MessageRole role;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final bool isSynced;

  MessageModel({
    required this.id,
    this.sessionId, // ← optional now
    required this.role,
    this.type = MessageType.text, // ← default value
    required this.content,
    required this.timestamp,
    this.isSynced = true,
  });

  // ── Convenience getters ──
  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId ?? '',
      'role': role.name,
      'type': type.name,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSynced': isSynced,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String? ?? '',
      sessionId: map['sessionId'] as String?,
      role: MessageRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      type: MessageType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => MessageType.text,
      ),
      content: map['content'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isSynced: map['isSynced'] as bool? ?? true,
    );
  }

  // ── Quick constructor for local no-save messages ──
  factory MessageModel.local({
    required String content,
    required MessageRole role,
    String? sessionId,
  }) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      role: role,
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
      isSynced: false,
    );
  }

  MessageModel copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    bool? isSynced,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
