import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ai_voice_chat/services/chat_service.dart';
import 'package:ai_voice_chat/models/message_model.dart';
import 'package:ai_voice_chat/services/settings_service.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class ChatBox extends StatefulWidget {
  final String? initialSessionId;
  const ChatBox({super.key, this.initialSessionId});
  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _sessionId;
  String? _uid;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isWebSearchEnabled = false;

  final List<MessageModel> _localMessages = [];

  bool get _isNoSaveMode =>
      _sessionId != null && _sessionId!.startsWith('no-save');

  @override
  void initState() {
    super.initState();
    _initSession();

    // ── Auto-fill prompt from Chat Info screen ──
    final args = Get.arguments;
    if (args != null && args is Map && args['prompt'] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textController.text = args['prompt'] as String;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSession() async {
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) {
      Get.offAllNamed('/login');
      return;
    }
    await SettingsService.to.init();
    if (widget.initialSessionId != null) {
      setState(() {
        _sessionId = widget.initialSessionId;
        _isInitializing = false;
      });
      return;
    }
    if (!SettingsService.to.saveHistory) {
      setState(() {
        _sessionId = 'no-save-${DateTime.now().millisecondsSinceEpoch}';
        _isInitializing = false;
      });
      return;
    }
    final sessionId = await _chatService.createSession(
      _uid!,
      title: 'New Chat',
    );
    setState(() {
      _sessionId = sessionId;
      _isInitializing = false;
    });
  }

  void _openSession(String sessionId) {
    setState(() {
      _sessionId = sessionId;
      _localMessages.clear();
    });
    _scrollToBottom();
  }

  Future<String> _searchWeb(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final url =
          'https://api.duckduckgo.com/?q=$encoded&format=json&no_html=1&skip_disambig=1';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final abstract = data['AbstractText'] as String? ?? '';
        final answer = data['Answer'] as String? ?? '';
        final topics =
            (data['RelatedTopics'] as List?)
                ?.take(3)
                .map((t) => t is Map ? t['Text'] as String? ?? '' : '')
                .where((t) => t.isNotEmpty)
                .join('\n') ??
            '';
        if (abstract.isNotEmpty || answer.isNotEmpty || topics.isNotEmpty) {
          return 'Web Search Results for "$query":\n'
              '${answer.isNotEmpty ? "Answer: $answer\n" : ""}'
              '${abstract.isNotEmpty ? "Summary: $abstract\n" : ""}'
              '${topics.isNotEmpty ? "Related:\n$topics" : ""}';
        }
      }
    } catch (e) {
      debugPrint('Web search error: $e');
    }
    return '';
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sessionId == null || _uid == null || _isLoading)
      return;
    _textController.clear();
    setState(() => _isLoading = true);

    if (_isNoSaveMode) {
      setState(() {
        _localMessages.add(
          MessageModel.local(
            content: text,
            role: MessageRole.user,
            sessionId: _sessionId,
          ),
        );
      });
      _scrollToBottom();
      try {
        String webContext = '';
        if (_isWebSearchEnabled) webContext = await _searchWeb(text);
        final userText = webContext.isNotEmpty
            ? '$text\n\n[Web context: $webContext]'
            : text;
        final aiReply = await _chatService.sendMessageWithoutSaving(
          uid: _uid!,
          userText: userText,
        );
        setState(() {
          _localMessages.add(
            MessageModel.local(
              content: aiReply.isNotEmpty
                  ? aiReply
                  : 'Sorry, I could not process that.',
              role: MessageRole.assistant,
              sessionId: _sessionId,
            ),
          );
        });
      } catch (e) {
        setState(() {
          _localMessages.add(
            MessageModel.local(
              content:
                  'Error: Could not get a response. Check your connection.',
              role: MessageRole.assistant,
              sessionId: _sessionId,
            ),
          );
        });
      }
    } else {
      try {
        String webContext = '';
        if (_isWebSearchEnabled) webContext = await _searchWeb(text);
        final userText = webContext.isNotEmpty
            ? '$text\n\n[Web context: $webContext]'
            : text;
        await _chatService.sendMessage(
          uid: _uid!,
          sessionId: _sessionId!,
          userText: userText,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to send message. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<bool> _confirmDelete(BuildContext ctx) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C2229),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Chat',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this chat?',
              style: TextStyle(color: Colors.white54, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _saveCurrentChat() async {
    if (_sessionId == null || _uid == null) return;
    if (_isNoSaveMode) {
      Get.back();
      Get.snackbar(
        '⚠️ Cannot Save',
        'Enable Save History in Settings first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    Get.back();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(_sessionId)
          .update({'saved': true, 'title': 'Saved Chat'});
      Get.snackbar(
        'Saved ✅',
        'Chat saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not save chat.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void _showSavedChats() {
    Get.back();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
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
              "Saved Chats",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_uid)
                    .collection('sessions')
                    .where('saved', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4FD8EB),
                      ),
                    );
                  final docs = List.from(snapshot.data?.docs ?? []);
                  docs.sort((a, b) {
                    final aTs = (a.data() as Map)['updatedAt'] as Timestamp?;
                    final bTs = (b.data() as Map)['updatedAt'] as Timestamp?;
                    if (aTs == null || bTs == null) return 0;
                    return bTs.compareTo(aTs);
                  });
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            color: Colors.white24,
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No saved chats yet",
                            style: TextStyle(color: Colors.white54),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap 'Save Current Chat' in the menu",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final sessionId = data['id'] as String? ?? docs[index].id;
                      final title = data['title'] as String? ?? 'Saved Chat';
                      final msgCount = data['messageCount'] as int? ?? 0;
                      final updatedAt = data['updatedAt'] as Timestamp?;
                      final date = updatedAt != null
                          ? _formatDate(updatedAt.toDate())
                          : '';
                      final isActive = sessionId == _sessionId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? const Color(0xFF4FD8EB).withOpacity(0.2)
                              : const Color(0xFF1C2229),
                          child: Icon(
                            Icons.bookmark,
                            color: isActive
                                ? const Color(0xFF4FD8EB)
                                : Colors.white54,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFF4FD8EB)
                                : Colors.white,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '$msgCount messages • $date',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () async {
                            final confirmed = await _confirmDelete(context);
                            if (confirmed) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_uid)
                                  .collection('sessions')
                                  .doc(sessionId)
                                  .update({'saved': false});
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _openSession(sessionId);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF4FD8EB);
    return Scaffold(
      drawer: _buildSidebar(context),
      bottomNavigationBar: const CustomNavBar(),
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
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
                child: Row(
                  children: [
                    Builder(
                      builder: (ctx) => IconButton(
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                        icon: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Learning · AI Chat',
                            style: GoogleFonts.jetBrainsMono(
                              color: cyan,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Web search toggle
                    GestureDetector(
                      onTap: () => setState(
                        () => _isWebSearchEnabled = !_isWebSearchEnabled,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _isWebSearchEnabled
                              ? Colors.green.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isWebSearchEnabled
                                ? Colors.green.withOpacity(0.4)
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.travel_explore_rounded,
                              color: _isWebSearchEnabled
                                  ? Colors.greenAccent
                                  : Colors.white38,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Web',
                              style: GoogleFonts.inter(
                                color: _isWebSearchEnabled
                                    ? Colors.greenAccent
                                    : Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (ctx) => IconButton(
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white54,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── No-save banner ──
              if (_isNoSaveMode)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        color: Colors.orange,
                        size: 13,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "History saving is OFF",
                        style: TextStyle(color: Colors.orange, fontSize: 11),
                      ),
                    ],
                  ),
                ),

              // ── Message list ──
              Expanded(
                child: _isInitializing
                    ? const Center(
                        child: CircularProgressIndicator(color: cyan),
                      )
                    : _isNoSaveMode
                    ? _buildLocalMessages()
                    : _buildFirestoreMessages(),
              ),

              // ── Typing indicator ──
              if (_isLoading) _buildTypingIndicator(),

              // ── Input ──
              _buildInputField(cyan),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalMessages() {
    if (_localMessages.isEmpty) return _buildEmptyState();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _localMessages.length,
      itemBuilder: (_, i) {
        final msg = _localMessages[i];
        return _buildMessageBubble(msg.content, msg.role == MessageRole.user);
      },
    );
  }

  Widget _buildFirestoreMessages() {
    if (_sessionId == null) return _buildEmptyState();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(_sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4FD8EB)),
          );
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final content = data['content'] as String? ?? '';
            final isUser = (data['role'] as String? ?? '') == 'user';
            return _buildMessageBubble(content, isUser);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.chat_bubble_outline_rounded,
          color: Color(0xFF4FD8EB),
          size: 60,
        ),
        const SizedBox(height: 16),
        Text(
          "Let's have a chat!",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Ask me anything...",
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _buildMessageBubble(String content, bool isUser) {
    const cyan = Color(0xFF4FD8EB);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: cyan.withOpacity(0.2),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: cyan,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: content));
                Get.snackbar(
                  'Copied',
                  'Message copied to clipboard',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: cyan.withOpacity(0.8),
                  colorText: Colors.black,
                  duration: const Duration(seconds: 1),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? cyan.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: Border.all(
                    color: isUser
                        ? cyan.withOpacity(0.3)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: isUser
                    ? Text(
                        content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      )
                    : MarkdownBody(
                        data: content,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            height: 1.5,
                          ),
                          strong: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          h1: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          h3: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          code: TextStyle(
                            color: cyan,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            fontSize: 13,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          listBullet: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.1),
              child: const Icon(Icons.person, color: Colors.white70, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF4FD8EB).withOpacity(0.2),
          child: Icon(
            _isWebSearchEnabled
                ? Icons.travel_explore
                : Icons.smart_toy_outlined,
            color: _isWebSearchEnabled
                ? Colors.greenAccent
                : const Color(0xFF4FD8EB),
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2229),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(0),
              const SizedBox(width: 4),
              _dot(1),
              const SizedBox(width: 4),
              _dot(2),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _dot(int index) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.4, end: 1.0),
    duration: Duration(milliseconds: 400 + (index * 150)),
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _isWebSearchEnabled
              ? Colors.greenAccent
              : const Color(0xFF4FD8EB),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );

  Widget _buildInputField(Color cyan) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    decoration: BoxDecoration(
      color: Colors.black,
      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              controller: _textController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type message...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey.shade800 : cyan,
              shape: BoxShape.circle,
              boxShadow: _isLoading
                  ? []
                  : [BoxShadow(color: cyan.withOpacity(0.3), blurRadius: 10)],
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
          ),
        ),
      ],
    ),
  );

  Widget _buildSidebar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    return Drawer(
      backgroundColor: const Color(0xFF000000),
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1F26).withOpacity(0.9),
                    Colors.black,
                  ],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF4FD8EB).withOpacity(0.2),
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? const Icon(
                            Icons.person,
                            color: Color(0xFF4FD8EB),
                            size: 40,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "AI Companion",
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _sidebarTile(
                  icon: Icons.add_comment_outlined,
                  title: "New Chat",
                  onTap: () async {
                    Get.back();
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) return;
                    if (!SettingsService.to.saveHistory) {
                      setState(() {
                        _sessionId =
                            'no-save-${DateTime.now().millisecondsSinceEpoch}';
                        _localMessages.clear();
                      });
                      return;
                    }
                    final newId = await _chatService.createSession(
                      uid,
                      title: 'New Chat',
                    );
                    setState(() => _sessionId = newId);
                  },
                ),
                _sidebarTile(
                  icon: Icons.psychology_outlined,
                  title: "ADAM's Memory",
                  onTap: () {
                    Get.back();
                    Get.toNamed('/memory');
                  },
                ),
                _sidebarTile(
                  icon: Icons.bookmark_border,
                  title: "Saved Chats",
                  onTap: _showSavedChats,
                ),
                _sidebarTile(
                  icon: Icons.bookmark_add_outlined,
                  title: "Save Current Chat",
                  onTap: _saveCurrentChat,
                ),
                const Divider(color: Colors.white12, height: 32),
                _sidebarTile(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap: () {
                    Get.back();
                    Get.toNamed('/settings');
                  },
                ),
                _sidebarTile(
                  icon: Icons.help_outline,
                  title: "Help & Support",
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      "Help & Support",
                      "Contact us at support@adamai.com",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                _sidebarTile(
                  icon: Icons.logout,
                  title: "Sign Out",
                  color: Colors.redAccent,
                  onTap: () async {
                    Get.back();
                    await FirebaseAuth.instance.signOut();
                    Get.offAllNamed('/welcome');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? color,
  }) => ListTile(
    leading: Icon(icon, color: color ?? Colors.white70, size: 26),
    title: Text(
      title,
      style: GoogleFonts.inter(
        color: color ?? Colors.white70,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    dense: true,
  );
}
