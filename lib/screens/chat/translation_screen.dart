import 'dart:convert';
import 'package:ai_voice_chat/config/api_keys.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class TranslationScreen extends StatefulWidget {
  final String? initialSessionId;
  const TranslationScreen({super.key, this.initialSessionId});
  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _inputController = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  static const _cyan = Color(0xFF4FD8EB);
  static const _groqKey = openAiKey;
  static const _groqUrl = 'https://api.openai.com/v1/chat/completions';

  bool _isListening = false;
  bool _isTranslating = false;
  bool _isSpeaking = false;
  bool _speechAvail = false;
  String _translated = '';
  String _status = 'Type or speak to translate';

  String _fromLang = '🇺🇸 English';
  String _fromCode = 'en_US';
  String _fromTts = 'en-US';
  String _toLang = '🇵🇰 Urdu';
  String _toCode = 'ur_PK';
  String _toTts = 'ur-PK';

  final List<Map<String, String>> _langs = [
    {'name': '🇺🇸 English', 'locale': 'en_US', 'tts': 'en-US'},
    {'name': '🇵🇰 Urdu', 'locale': 'ur_PK', 'tts': 'ur-PK'},
    {'name': '🇸🇦 Arabic', 'locale': 'ar_SA', 'tts': 'ar-SA'},
    {'name': '🇮🇳 Hindi', 'locale': 'hi_IN', 'tts': 'hi-IN'},
    {'name': '🇫🇷 French', 'locale': 'fr_FR', 'tts': 'fr-FR'},
    {'name': '🇩🇪 German', 'locale': 'de_DE', 'tts': 'de-DE'},
    {'name': '🇪🇸 Spanish', 'locale': 'es_ES', 'tts': 'es-ES'},
    {'name': '🇵🇹 Portuguese', 'locale': 'pt_BR', 'tts': 'pt-BR'},
    {'name': '🇮🇹 Italian', 'locale': 'it_IT', 'tts': 'it-IT'},
    {'name': '🇷🇺 Russian', 'locale': 'ru_RU', 'tts': 'ru-RU'},
    {'name': '🇨🇳 Chinese', 'locale': 'zh_CN', 'tts': 'zh-CN'},
    {'name': '🇯🇵 Japanese', 'locale': 'ja_JP', 'tts': 'ja-JP'},
    {'name': '🇰🇷 Korean', 'locale': 'ko_KR', 'tts': 'ko-KR'},
    {'name': '🇹🇷 Turkish', 'locale': 'tr_TR', 'tts': 'tr-TR'},
    {'name': '🇧🇩 Bengali', 'locale': 'bn_BD', 'tts': 'bn-BD'},
    {'name': '🇮🇩 Indonesian', 'locale': 'id_ID', 'tts': 'id-ID'},
    {'name': '🇳🇱 Dutch', 'locale': 'nl_NL', 'tts': 'nl-NL'},
    {'name': '🇵🇱 Polish', 'locale': 'pl_PL', 'tts': 'pl-PL'},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    if (widget.initialSessionId != null) _loadSession(widget.initialSessionId!);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadSession(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(id)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _inputController.text = data['originalText'] as String? ?? '';
          _translated = data['translatedText'] as String? ?? '';
          _status = _translated.isNotEmpty
              ? 'Previous translation loaded ✅'
              : 'Type or speak to translate';
        });
      }
    } catch (e) {
      debugPrint('Load session error: $e');
    }
  }

  Future<void> _initSpeech() async {
    _speechAvail = await _speech.initialize();
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
  }

  Future<void> _saveToHistory(String original, String translated) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final fromName = _fromLang.split(' ').skip(1).join(' ');
      final toName = _toLang.split(' ').skip(1).join(' ');
      final title = original.length > 40
          ? '${original.substring(0, 40)}...'
          : original;
      if (widget.initialSessionId != null) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .doc(widget.initialSessionId)
            .update({
              'title': '🌍 $title',
              'fromLanguage': fromName,
              'toLanguage': toName,
              'originalText': original,
              'translatedText': translated,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        return;
      }
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(_uuid.v4());
      await ref.set({
        'id': ref.id,
        'uid': uid,
        'title': '🌍 $title',
        'type': 'translation',
        'fromLanguage': fromName,
        'toLanguage': toName,
        'originalText': original,
        'translatedText': translated,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': 1,
      });
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  void _showLangPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E1A),
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
            Text(
              isFrom ? "Translate From" : "Translate To",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _langs.length,
                itemBuilder: (context, i) {
                  final lang = _langs[i];
                  final isSel = isFrom
                      ? lang['name'] == _fromLang
                      : lang['name'] == _toLang;
                  return ListTile(
                    leading: Text(
                      lang['name']!.split(' ')[0],
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      lang['name']!.split(' ').skip(1).join(' '),
                      style: TextStyle(
                        color: isSel ? _cyan : Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSel
                        ? const Icon(Icons.check_circle, color: _cyan)
                        : null,
                    onTap: () {
                      setState(() {
                        if (isFrom) {
                          _fromLang = lang['name']!;
                          _fromCode = lang['locale']!;
                          _fromTts = lang['tts']!;
                        } else {
                          _toLang = lang['name']!;
                          _toCode = lang['locale']!;
                          _toTts = lang['tts']!;
                        }
                      });
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

  void _swap() {
    setState(() {
      String t;
      t = _fromLang;
      _fromLang = _toLang;
      _toLang = t;
      t = _fromCode;
      _fromCode = _toCode;
      _toCode = t;
      t = _fromTts;
      _fromTts = _toTts;
      _toTts = t;
      final tmp = _inputController.text;
      _inputController.text = _translated;
      _translated = tmp;
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvail) {
      setState(() => _status = 'Speech not available');
      return;
    }
    if (_isSpeaking) await _tts.stop();
    setState(() {
      _isListening = true;
      _status = 'Listening...';
    });
    await _speech.listen(
      onResult: (r) {
        setState(() => _inputController.text = r.recognizedWords);
        if (r.finalResult && _inputController.text.isNotEmpty) _stopListening();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      localeId: _fromCode,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _status = 'Type or speak to translate';
    });
    if (_inputController.text.isNotEmpty) await _translate();
  }

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isTranslating = true;
      _translated = '';
      _status = 'Translating...';
    });
    try {
      final from = _fromLang.split(' ').skip(1).join(' ');
      final to = _toLang.split(' ').skip(1).join(' ');
      final res = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a professional translator. Translate from $from to $to. Return ONLY the translated text, nothing else.',
            },
            {'role': 'user', 'content': text},
          ],
          'max_tokens': 500,
          'temperature': 0.3,
        }),
      );
      if (res.statusCode == 200) {
        final translated =
            (jsonDecode(res.body)['choices'][0]['message']['content'] as String)
                .trim();
        setState(() {
          _translated = translated;
          _isTranslating = false;
          _status = 'Translation complete ✅';
        });
        await _saveToHistory(text, _translated);
        await _speak();
      } else {
        setState(() {
          _isTranslating = false;
          _status = 'Translation failed. Try again!';
        });
      }
    } catch (e) {
      setState(() {
        _isTranslating = false;
        _status = 'Error: Check your internet connection';
      });
    }
  }

  Future<void> _speak() async {
    if (_translated.isEmpty) return;
    await _tts.setLanguage(_toTts);
    setState(() => _isSpeaking = true);
    await _tts.speak(_translated);
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _translated));
    Get.snackbar(
      '✅ Copied!',
      'Translation copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _cyan.withOpacity(0.8),
      colorText: Colors.black,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _cyan,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "AI Translation",
                                style: GoogleFonts.rajdhani(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                "Instant • AI Powered",
                                style: GoogleFonts.jetBrainsMono(
                                  color: _cyan,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.initialSessionId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _cyan.withOpacity(0.4)),
                            ),
                            child: const Text(
                              'Loaded',
                              style: TextStyle(color: _cyan, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // ── Language selector ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            // FROM
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showLangPicker(true),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "From",
                                      style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          _fromLang.split(' ')[0],
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            _fromLang
                                                .split(' ')
                                                .skip(1)
                                                .join(' '),
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white38,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Swap
                            GestureDetector(
                              onTap: _swap,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _cyan.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _cyan.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.swap_horiz_rounded,
                                  color: _cyan,
                                  size: 20,
                                ),
                              ),
                            ),
                            // TO
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showLangPicker(false),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "To",
                                      style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white38,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _toLang
                                                .split(' ')
                                                .skip(1)
                                                .join(' '),
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _toLang.split(' ')[0],
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Input box ──
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _cyan.withOpacity(0.25)),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                controller: _inputController,
                                maxLines: 4,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type text or tap mic to speak...',
                                  hintStyle: GoogleFonts.inter(
                                    color: Colors.white24,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _inputController.clear();
                                      _translated = '';
                                      _status = 'Type or speak to translate';
                                    }),
                                    child: const Icon(
                                      Icons.clear_rounded,
                                      color: Colors.white24,
                                      size: 20,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // Mic
                                      GestureDetector(
                                        onTap: _isListening
                                            ? _stopListening
                                            : _startListening,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: _isListening
                                                ? _cyan
                                                : _cyan.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _cyan.withOpacity(0.4),
                                            ),
                                            boxShadow: _isListening
                                                ? [
                                                    BoxShadow(
                                                      color: _cyan.withOpacity(
                                                        0.3,
                                                      ),
                                                      blurRadius: 10,
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Icon(
                                            _isListening
                                                ? Icons.stop_rounded
                                                : Icons.mic_rounded,
                                            color: _isListening
                                                ? Colors.white
                                                : _cyan,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Translate button
                                      GestureDetector(
                                        onTap: _isTranslating
                                            ? null
                                            : _translate,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: _isTranslating
                                                ? LinearGradient(
                                                    colors: [
                                                      Colors.grey.shade800,
                                                      Colors.grey.shade700,
                                                    ],
                                                  )
                                                : const LinearGradient(
                                                    colors: [
                                                      Color(0xFF4FD8EB),
                                                      Color(0xFF00C9FF),
                                                    ],
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            boxShadow: _isTranslating
                                                ? []
                                                : [
                                                    BoxShadow(
                                                      color: _cyan.withOpacity(
                                                        0.3,
                                                      ),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                    ),
                                                  ],
                                          ),
                                          child: _isTranslating
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.black,
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Text(
                                                  "Translate",
                                                  style: GoogleFonts.inter(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Status ──
                      Text(
                        _status,
                        style: GoogleFonts.inter(
                          color: _isListening
                              ? _cyan
                              : _status.contains('✅')
                              ? Colors.greenAccent
                              : _isTranslating
                              ? Colors.orange
                              : Colors.white38,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Translation output ──
                      if (_translated.isNotEmpty)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _cyan.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Language label
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  6,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _toLang.split(' ')[0],
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _toLang.split(' ').skip(1).join(' '),
                                      style: GoogleFonts.inter(
                                        color: _cyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Translated text
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  14,
                                ),
                                child: Text(
                                  _translated,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 17,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const Divider(color: Colors.white12, height: 1),
                              // Action buttons
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      onPressed: _isSpeaking
                                          ? () async {
                                              await _tts.stop();
                                              setState(
                                                () => _isSpeaking = false,
                                              );
                                            }
                                          : _speak,
                                      icon: Icon(
                                        _isSpeaking
                                            ? Icons.stop_circle_outlined
                                            : Icons.volume_up_outlined,
                                        color: _isSpeaking
                                            ? Colors.greenAccent
                                            : _cyan,
                                        size: 22,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _copy,
                                      icon: const Icon(
                                        Icons.copy_outlined,
                                        color: Colors.white38,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

