import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_voice_chat/controller/chat_controller.dart';
import 'package:ai_voice_chat/models/message_model.dart';

class FinalChatScreen extends StatelessWidget {
  const FinalChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatController());

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    const Color(0xFF1C2229).withValues(alpha: 0.5),
                    const Color(0xFF0D1117),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _AppBar(controller: controller),
                Obx(() => controller.isVoiceMode.value
                    ? const _VoiceChatBody()
                    : _TextChatBody(controller: controller)),
                Obx(() => controller.isVoiceMode.value
                    ? const SizedBox.shrink()
                    : _MessageInput(controller: controller)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final ChatController controller;
  const _AppBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF4FD8EB), size: 20),
                onPressed: () {
                  if (controller.isVoiceMode.value) {
                    controller.toggleVoiceMode();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isVoiceMode.value ? 'Voice' : 'Chat',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        controller.isVoiceMode.value
                            ? 'Personal • AI Chat'
                            : 'Learning • AI Chat',
                        style: GoogleFonts.robotoMono(
                          color: const Color(0xFF4FD8EB),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ─── Text Chat Body ───────────────────────────────────────────────────────────

class _TextChatBody extends StatelessWidget {
  final ChatController controller;
  const _TextChatBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        if (controller.messages.isEmpty) {
          return Center(
            child: Text(
              "Let's have a chat!",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        return ListView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: controller.messages.length,
          itemBuilder: (_, i) =>
              _MessageBubble(message: controller.messages[i]),
        );
      }),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF4FD8EB)
              : const Color(0xFF1C2229),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.type == MessageType.voice && isUser)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.graphic_eq,
                    size: 14, color: Colors.black54),
              ),
            Flexible(
              child: Text(
                message.content,
                style: GoogleFonts.poppins(
                  color: isUser ? Colors.black : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Input ────────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  final ChatController controller;
  const _MessageInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Obx(() {
            if (controller.errorText.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  controller.errorText.value,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => controller.sendTextMessage(),
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.toggleVoiceMode,
                        child: const Icon(Icons.graphic_eq,
                            color: Color(0xFF4FD8EB), size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(() => GestureDetector(
                    onTap: controller.isSending.value
                        ? null
                        : controller.sendTextMessage,
                    child: Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        color: controller.isSending.value
                            ? Colors.grey
                            : const Color(0xFF4FD8EB),
                        shape: BoxShape.circle,
                      ),
                      child: controller.isSending.value
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Voice Chat Body ──────────────────────────────────────────────────────────

class _VoiceChatBody extends StatelessWidget {
  const _VoiceChatBody();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tap the mic and speak\nADAM will listen and respond\ninstantly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2229),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Color(0xFF4FD8EB), size: 50),
          ),
          const SizedBox(height: 30),
          Text(
            'Voice mode coming soon.\nUse text chat for now.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
