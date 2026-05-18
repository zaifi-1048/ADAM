import 'dart:convert';
import 'package:ai_voice_chat/config/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:ai_voice_chat/controller/voice_controller.dart';
import 'package:ai_voice_chat/services/settings_service.dart';
import 'package:ai_voice_chat/services/stt_manager.dart';
import 'package:ai_voice_chat/services/wake_word_service.dart';

class VoiceChatScreen extends StatefulWidget {
  final String? initialSessionId;
  const VoiceChatScreen({super.key, this.initialSessionId});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final VoiceController _voiceCtrl = VoiceController.to;

  static const String _groqApiKey = openAiKey;
  static const String _groqUrl =
      'https://api.openai.com/v1/chat/completions';

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;

  String _userText = '';
  String _adamResponse = '';
  String _statusText = 'Tap the mic to start';
  String? _sessionId;
  String? _uid;

  String _selectedLocale = 'en_US';
  String _selectedLanguageName = 'English';
  String _ttsLanguage = 'en-US';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'locale': 'en_US', 'tts': 'en-US'},
    {'name': 'Urdu', 'locale': 'ur_PK', 'tts': 'ur-PK'},
    {'name': 'Arabic', 'locale': 'ar_SA', 'tts': 'ar-SA'},
    {'name': 'Hindi', 'locale': 'hi_IN', 'tts': 'hi-IN'},
    {'name': 'French', 'locale': 'fr_FR', 'tts': 'fr-FR'},
    {'name': 'German', 'locale': 'de_DE', 'tts': 'de-DE'},
    {'name': 'Spanish', 'locale': 'es_ES', 'tts': 'es-ES'},
    {'name': 'Portuguese', 'locale': 'pt_BR', 'tts': 'pt-BR'},
    {'name': 'Italian', 'locale': 'it_IT', 'tts': 'it-IT'},
    {'name': 'Russian', 'locale': 'ru_RU', 'tts': 'ru-RU'},
    {'name': 'Chinese', 'locale': 'zh_CN', 'tts': 'zh-CN'},
    {'name': 'Japanese', 'locale': 'ja_JP', 'tts': 'ja-JP'},
    {'name': 'Korean', 'locale': 'ko_KR', 'tts': 'ko-KR'},
    {'name': 'Turkish', 'locale': 'tr_TR', 'tts': 'tr-TR'},
    {'name': 'Bengali', 'locale': 'bn_BD', 'tts': 'bn-BD'},
    {'name': 'Indonesian', 'locale': 'id_ID', 'tts': 'id-ID'},
    {'name': 'Dutch', 'locale': 'nl_NL', 'tts': 'nl-NL'},
    {'name': 'Polish', 'locale': 'pl_PL', 'tts': 'pl-PL'},
  ];

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTts();
    _initSession();
    WakeWordService.instance.pauseForScreen();
    _acquireSTT();
  }

  Future<void> _acquireSTT() async {
    await SttManager.instance.initialize();
    await SttManager.instance.requestAccess(SttPriority.voiceChat);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _voiceCtrl.tts.stop();
    SttManager.instance.releaseAccess(SttPriority.voiceChat);
    WakeWordService.instance.resumeAfterScreen();
    super.dispose();
  }

  Future<void> _initSession() async {
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) return;
    await SettingsService.to.init();
    if (widget.initialSessionId != null) {
      setState(() => _sessionId = widget.initialSessionId);
      await _loadPreviousMessages(widget.initialSessionId!);
      return;
    }
    if (!SettingsService.to.saveHistory) {
      setState(() => _sessionId = 'no-save');
      return;
    }
    final ref = _db.collection('users').doc(_uid).collection('sessions').doc();
    await ref.set({
      'id': ref.id,
      'uid': _uid,
      'title': 'Voice Chat',
      'type': 'voice',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'messageCount': 0,
    });
    setState(() => _sessionId = ref.id);
  }

  Future<void> _loadPreviousMessages(String sessionId) async {
    if (_uid == null) return;
    try {
      final snap = await _db
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();
      final messages = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'role': data['role'] as String? ?? 'user',
          'content': data['content'] as String? ?? '',
        };
      }).toList();
      setState(() {
        _conversationHistory.addAll(messages);
        if (_conversationHistory.isNotEmpty) {
          final lastAi = _conversationHistory.lastWhere(
            (m) => m['role'] == 'assistant',
            orElse: () => {},
          );
          if (lastAi.isNotEmpty) _adamResponse = lastAi['content'] ?? '';
          final lastUser = _conversationHistory.lastWhere(
            (m) => m['role'] == 'user',
            orElse: () => {},
          );
          if (lastUser.isNotEmpty) _userText = lastUser['content'] ?? '';
          _statusText = 'Previous session loaded. Tap mic to continue.';
        }
      });
    } catch (e) {
      debugPrint('Error loading voice history: $e');
    }
  }

  Future<void> _saveMessage(String role, String content) async {
    if (_uid == null || _sessionId == null) return;
    if (!SettingsService.to.saveHistory) return;
    if (_sessionId == 'no-save') return;
    try {
      final msgRef = _db
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(_sessionId)
          .collection('messages')
          .doc(_uuid.v4());
      await msgRef.set({
        'id': msgRef.id,
        'sessionId': _sessionId,
        'role': role,
        'type': 'voice',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isSynced': true,
      });
      await _db
          .collection('users')
          .doc(_uid)
          .collection('sessions')
          .doc(_sessionId)
          .update({
            'updatedAt': FieldValue.serverTimestamp(),
            'messageCount': FieldValue.increment(1),
          });
    } catch (e) {
      debugPrint('Error saving message: $e');
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTts() async {
    await _voiceCtrl.applyVoiceSettings(language: _ttsLanguage);
    _voiceCtrl.tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _voiceCtrl.tts.setCompletionHandler(
      () => setState(() {
        _isSpeaking = false;
        _statusText = 'Tap the mic to speak again';
      }),
    );
  }

  void _showLanguagePicker() {
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
              "Select Language",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = lang['locale'] == _selectedLocale;
                  return ListTile(
                    title: Text(
                      lang['name']!,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF4FD8EB)
                            : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4FD8EB),
                          )
                        : null,
                    onTap: () async {
                      setState(() {
                        _selectedLocale = lang['locale']!;
                        _selectedLanguageName = lang['name']!;
                        _ttsLanguage = lang['tts']!;
                      });
                      await _voiceCtrl.applyVoiceSettings(
                        language: _ttsLanguage,
                      );
                      Navigator.pop(context);
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

  Future<void> _startListening() async {
    if (!SttManager.instance.isReady) {
      setState(() => _statusText = 'Speech not available on this device');
      return;
    }
    if (_isSpeaking) {
      await _voiceCtrl.tts.stop();
      setState(() => _isSpeaking = false);
    }
    setState(() {
      _isListening = true;
      _userText = '';
      _statusText = 'Listening...';
    });
    await SttManager.instance.listen(
      priority: SttPriority.voiceChat,
      onResult: (words, isFinal) {
        setState(() => _userText = words);
        if (isFinal && words.isNotEmpty) _stopListening();
      },
      listenFor: const Duration(seconds: 300),
      pauseFor: const Duration(seconds: 8),
      localeId: _selectedLocale,
      partialResults: true,
    );
  }

  Future<void> _stopListening() async {
    await SttManager.instance.stop(SttPriority.voiceChat);
    setState(() => _isListening = false);
    if (_userText.isNotEmpty) {
      await _saveMessage('user', _userText);
      await _getAIResponse(_userText);
    } else
      setState(() => _statusText = 'No speech detected. Try again.');
  }

  Future<void> _getAIResponse(String userText) async {
    setState(() {
      _isThinking = true;
      _statusText = 'ADAM is thinking...';
      _adamResponse = '';
    });
    _conversationHistory.add({'role': 'user', 'content': userText});
    try {
      final messages = <Map<String, dynamic>>[
        {
          'role': 'system',
          'content':
              'You are ADAM, an intelligent AI assistant. Always respond in the same language the user speaks. Keep responses concise — 2-3 sentences max.',
        },
        ..._conversationHistory,
      ];
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': messages,
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'] as String;
        _conversationHistory.add({'role': 'assistant', 'content': aiText});
        await _saveMessage('assistant', aiText);
        if (SettingsService.to.saveHistory &&
            _sessionId != 'no-save' &&
            _conversationHistory.length <= 2) {
          final title = userText.length > 40
              ? '${userText.substring(0, 40)}...'
              : userText;
          await _db
              .collection('users')
              .doc(_uid)
              .collection('sessions')
              .doc(_sessionId)
              .update({'title': title});
        }
        setState(() {
          _adamResponse = aiText;
          _isThinking = false;
          _statusText = 'ADAM is speaking...';
        });
        await _voiceCtrl.tts.speak(aiText);
      } else {
        setState(() {
          _isThinking = false;
          _adamResponse = 'Sorry, I could not process that. Please try again.';
          _statusText = 'Error occurred';
        });
      }
    } catch (e) {
      setState(() {
        _isThinking = false;
        _adamResponse = 'Connection error. Please check your internet.';
        _statusText = 'Error occurred';
      });
    }
  }

  Future<void> _stopAll() async {
    await SttManager.instance.stop(SttPriority.voiceChat);
    await _voiceCtrl.tts.stop();
    setState(() {
      _isListening = false;
      _isSpeaking = false;
      _isThinking = false;
      _statusText = 'Tap the mic to start';
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color accentCyan = Color(0xFF4FD8EB);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Container(
        width: double.infinity,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                            size: 20,
                          ),
                        ),
                        Text(
                          "Voice",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.initialSessionId != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accentCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accentCyan.withOpacity(0.4),
                              ),
                            ),
                            child: const Text(
                              'Loaded',
                              style: TextStyle(
                                color: Color(0xFF4FD8EB),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        GestureDetector(
                          onTap: _showLanguagePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: accentCyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accentCyan.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedLanguageName,
                                  style: const TextStyle(
                                    color: Color(0xFF4FD8EB),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF4FD8EB),
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await _stopAll();
                            setState(() {
                              _conversationHistory.clear();
                              _userText = '';
                              _adamResponse = '';
                              _statusText = 'Tap the mic to start';
                            });
                            if (!SettingsService.to.saveHistory) {
                              setState(() => _sessionId = 'no-save');
                              return;
                            }
                            final ref = _db
                                .collection('users')
                                .doc(_uid)
                                .collection('sessions')
                                .doc();
                            await ref.set({
                              'id': ref.id,
                              'uid': _uid,
                              'title': 'Voice Chat',
                              'type': 'voice',
                              'createdAt': FieldValue.serverTimestamp(),
                              'updatedAt': FieldValue.serverTimestamp(),
                              'messageCount': 0,
                            });
                            setState(() => _sessionId = ref.id);
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white54,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 44),
                      child: Text(
                        "Personal  •  AI Chat",
                        style: GoogleFonts.jetBrainsMono(
                          color: accentCyan,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!SettingsService.to.saveHistory)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
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
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "History saving is OFF",
                        style: TextStyle(color: Colors.orange, fontSize: 11),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _isListening
                        ? accentCyan
                        : _isSpeaking
                        ? Colors.greenAccent
                        : Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (_userText.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: accentCyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accentCyan.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.person,
                                color: Colors.white54,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _userText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_adamResponse.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.smart_toy_outlined,
                                color: Color(0xFF4FD8EB),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _adamResponse,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _isListening
                    ? _stopListening
                    : _isThinking || _isSpeaking
                    ? _stopAll
                    : _startListening,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isListening || _isSpeaking) ...[
                          _ripple(160, accentCyan.withOpacity(0.08)),
                          _ripple(120, accentCyan.withOpacity(0.12)),
                          _ripple(90, accentCyan.withOpacity(0.18)),
                        ] else ...[
                          _ripple(140, accentCyan.withOpacity(0.05)),
                          _ripple(105, accentCyan.withOpacity(0.08)),
                          _ripple(80, accentCyan.withOpacity(0.1)),
                        ],
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? accentCyan
                                : _isSpeaking
                                ? Colors.greenAccent
                                : _isThinking
                                ? Colors.orange
                                : const Color(0xFF1C2229),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isListening ? accentCyan : Colors.white12,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isListening
                                    ? accentCyan.withOpacity(0.4)
                                    : accentCyan.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening
                                ? Icons.stop
                                : _isSpeaking
                                ? Icons.volume_up
                                : _isThinking
                                ? Icons.hourglass_top
                                : Icons.mic,
                            color: _isListening
                                ? Colors.white
                                : _isSpeaking
                                ? Colors.black
                                : Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) => Container(
                  width: 220,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(15, (index) {
                      double height = 10;
                      if (_isListening || _isSpeaking) {
                        height =
                            8 +
                            (16 *
                                (index % 3 == 0
                                    ? _waveController.value
                                    : index % 3 == 1
                                    ? 1 - _waveController.value
                                    : 0.5));
                      } else if (_isThinking) {
                        height =
                            10 +
                            (8 *
                                ((index + _waveController.value * 5) % 2 == 0
                                    ? _waveController.value
                                    : 0.3));
                      } else {
                        height = index % 2 == 0 ? 10 : 16;
                      }
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: _isListening
                              ? accentCyan
                              : _isSpeaking
                              ? Colors.greenAccent
                              : _isThinking
                              ? Colors.orange
                              : accentCyan.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isListening ? _stopListening : _startListening,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? accentCyan.withOpacity(0.3)
                                : accentCyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: accentCyan.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isListening ? Icons.stop : Icons.mic_none,
                                color: accentCyan,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isListening ? "Stop" : "Tap to talk",
                                style: GoogleFonts.inter(
                                  color: accentCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: _stopAll,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Center(
                            child: Text(
                              "Stop All",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ripple(double size, Color color) => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 1.5),
    ),
  );
}

