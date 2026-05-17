import 'package:flutter/material.dart';
import 'package:ai_voice_chat/screens/chat/chatinfoscreen.dart';
import 'package:ai_voice_chat/screens/chat/chatbox.dart';

// ── ChatScreen is now just a transparent router ──
// Landing page removed — goes straight to ChatInfoScreen
class ChatScreen extends StatelessWidget {
  final String? initialSessionId;
  const ChatScreen({super.key, this.initialSessionId});

  @override
  Widget build(BuildContext context) {
    // If opened with a specific session, go straight to ChatBox
    if (initialSessionId != null) {
      return ChatBox(initialSessionId: initialSessionId);
    }
    // Otherwise show the redesigned chat hub
    return const ChatInfoScreen();
  }
}
