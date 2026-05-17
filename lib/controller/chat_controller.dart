import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_voice_chat/models/message_model.dart';
import 'package:ai_voice_chat/services/auth_service.dart';
import 'package:ai_voice_chat/services/chat_service.dart';

class ChatController extends GetxController {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  // ─── Observables ──────────────────────────────────────────────────────────

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isSending = false.obs;
  final RxBool isVoiceMode = false.obs;
  final RxString sessionId = ''.obs;
  final RxString errorText = ''.obs;

  StreamSubscription<List<MessageModel>>? _messagesSub;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _initSession();
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    _messagesSub?.cancel();
    super.onClose();
  }

  // ─── Session setup ────────────────────────────────────────────────────────

  Future<void> _initSession() async {
    final uid = _authService.currentUid;
    if (uid == null) return;

    final sid = await _chatService.createSession(uid);
    sessionId.value = sid;
    _listenToMessages(uid, sid);
  }

  void _listenToMessages(String uid, String sid) {
    _messagesSub?.cancel();
    _messagesSub = _chatService.watchMessages(uid, sid).listen((msgs) {
      messages.assignAll(msgs);
      _scrollToBottom();
    });
  }

  // ─── Send ─────────────────────────────────────────────────────────────────

  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isSending.value) return;

    final uid = _authService.currentUid;
    if (uid == null || sessionId.value.isEmpty) return;

    messageController.clear();
    isSending.value = true;
    errorText.value = '';

    try {
      await _chatService.sendMessage(
        uid: uid,
        sessionId: sessionId.value,
        userText: text,
        type: MessageType.text,
      );
    } catch (e) {
      errorText.value = 'Failed to send. Please try again.';
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendVoiceMessage(String transcribedText) async {
    if (transcribedText.isEmpty) return;

    final uid = _authService.currentUid;
    if (uid == null || sessionId.value.isEmpty) return;

    isSending.value = true;
    errorText.value = '';

    try {
      await _chatService.sendMessage(
        uid: uid,
        sessionId: sessionId.value,
        userText: transcribedText,
        type: MessageType.voice,
      );
    } catch (e) {
      errorText.value = 'Failed to send voice message.';
    } finally {
      isSending.value = false;
    }
  }

  // ─── UI helpers ───────────────────────────────────────────────────────────

  void toggleVoiceMode() => isVoiceMode.toggle();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
