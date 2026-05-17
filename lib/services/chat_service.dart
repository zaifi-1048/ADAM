import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:ai_voice_chat/models/message_model.dart';
import 'package:ai_voice_chat/config/api_keys.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  static const String _apiKey = openAiKey;
  static const String _groqUrl =
      'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';

  // ─── Session helpers ──────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _sessionsRef(String uid) =>
      _db.collection('users').doc(uid).collection('sessions');

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String uid,
    String sessionId,
  ) => _sessionsRef(uid).doc(sessionId).collection('messages');

  // ─── Create session ───────────────────────────────────────────────────────

  Future<String> createSession(String uid, {String title = 'New Chat'}) async {
    final ref = _sessionsRef(uid).doc();
    await ref.set({
      'id': ref.id,
      'uid': uid,
      'title': title,
      'type': 'chat',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'messageCount': 0,
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSessions(String uid) {
    return _sessionsRef(uid).orderBy('updatedAt', descending: true).snapshots();
  }

  Future<void> deleteSession(String uid, String sessionId) async {
    final msgs = await _messagesRef(uid, sessionId).get();
    final batch = _db.batch();
    for (final doc in msgs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_sessionsRef(uid).doc(sessionId));
    await batch.commit();
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

  Stream<List<MessageModel>> watchMessages(String uid, String sessionId) {
    return _messagesRef(uid, sessionId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => MessageModel.fromMap(doc.data())).toList(),
        );
  }

  Future<void> _saveMessage(
    String uid,
    String sessionId,
    MessageModel message,
  ) async {
    final batch = _db.batch();
    batch.set(_messagesRef(uid, sessionId).doc(message.id), message.toMap());
    batch.update(_sessionsRef(uid).doc(sessionId), {
      'updatedAt': FieldValue.serverTimestamp(),
      'messageCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  // ─── Send message (with Firestore saving) ────────────────────────────────

  Future<String> sendMessage({
    required String uid,
    required String sessionId,
    required String userText,
    MessageType type = MessageType.text,
    bool saveHistory = true,
  }) async {
    if (saveHistory) {
      // 1. Save user message to Firestore
      final userMsg = MessageModel(
        id: _uuid.v4(),
        sessionId: sessionId,
        role: MessageRole.user,
        type: type,
        content: userText,
        timestamp: DateTime.now(),
      );
      await _saveMessage(uid, sessionId, userMsg);

      // 2. Update session title with first message
      final sessionDoc = await _sessionsRef(uid).doc(sessionId).get();
      final msgCount = sessionDoc.data()?['messageCount'] as int? ?? 0;
      if (msgCount <= 1) {
        final title = userText.length > 40
            ? '${userText.substring(0, 40)}...'
            : userText;
        await _sessionsRef(uid).doc(sessionId).update({'title': title});
      }

      // 3. Call OpenAI with history
      final aiText = await _callGroq(
        uid: uid,
        sessionId: sessionId,
        userText: userText,
      );

      // 4. Save AI response to Firestore
      final aiMsg = MessageModel(
        id: _uuid.v4(),
        sessionId: sessionId,
        role: MessageRole.assistant,
        type: MessageType.text,
        content: aiText,
        timestamp: DateTime.now(),
      );
      await _saveMessage(uid, sessionId, aiMsg);

      return aiText;
    } else {
      // Save history is OFF — just get AI response without saving
      return await _callGroqWithoutHistory(userText: userText);
    }
  }

  // ─── Send message WITHOUT saving (history OFF) ───────────────────────────

  Future<String> sendMessageWithoutSaving({
    required String uid,
    required String userText,
  }) async {
    return await _callGroqWithoutHistory(userText: userText);
  }

  // ─── Groq API Call (with Firestore history) ───────────────────────────────

  Future<String> _callGroq({
    required String uid,
    required String sessionId,
    required String userText,
  }) async {
    try {
      final messagesSnap = await _messagesRef(
        uid,
        sessionId,
      ).orderBy('timestamp', descending: false).get();

      final history = messagesSnap.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .where((m) => m.content.isNotEmpty)
          .toList();

      final messages = <Map<String, dynamic>>[
        {
          'role': 'system',
          'content':
              'You are ADAM, an intelligent and friendly AI assistant. '
              'You are helpful, concise, and professional. '
              'Always respond clearly and accurately.',
        },
      ];

      for (final msg in history) {
        messages.add({
          'role': msg.role == MessageRole.user ? 'user' : 'assistant',
          'content': msg.content,
        });
      }

      messages.add({'role': 'user', 'content': userText});

      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            'No response from AI.';
      } else {
        final error = jsonDecode(response.body);
        return 'Error ${response.statusCode}: ${error['error']['message']}';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // ─── Groq API Call (without history — Save History OFF) ──────────────────

  Future<String> _callGroqWithoutHistory({required String userText}) async {
    try {
      final messages = <Map<String, dynamic>>[
        {
          'role': 'system',
          'content':
              'You are ADAM, an intelligent and friendly AI assistant. '
              'You are helpful, concise, and professional. '
              'Always respond clearly and accurately.',
        },
        {'role': 'user', 'content': userText},
      ];

      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            'No response from AI.';
      } else {
        final error = jsonDecode(response.body);
        return 'Error ${response.statusCode}: ${error['error']['message']}';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
}


