import 'dart:async';
import 'dart:convert';
import 'package:ai_voice_chat/config/api_keys.dart';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_voice_chat/main.dart' show flutterLocalNotificationsPlugin;

enum WakeState {
  disabled,
  paused,
  waiting,
  activated,
  listening,
  processing,
  responding,
}

class WakeWordService {
  static final WakeWordService _i = WakeWordService._();
  static WakeWordService get instance => _i;
  WakeWordService._();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final Battery _battery = Battery();

  bool _initialized = false;
  bool _sttReady = false;
  bool _isPaused = false;
  bool _isRunning = false;
  bool _sessionActive = false;
  bool _appInBackground = false;
  bool _launchedExternalApp = false;
  bool _foregroundServiceActive = false; // true = can listen in background
  bool _wakeWordDetectedInBackground = false;
  bool _cameFromBackground = false;
  bool _restoringFromExternalApp = false;
  // _resumeCompleter removed — service handles all launches directly
  DateTime? _lastActiveTime;
  String? _cachedCity;
  Timer? _restartTimer;
  DateTime? _lastWakeWordTime; // cooldown to prevent double triggers
  GlobalKey<NavigatorState>? _navKey;
  OverlayEntry? _overlay;

  final ValueNotifier<WakeState> state = ValueNotifier(WakeState.disabled);
  final ValueNotifier<String> lastCommand = ValueNotifier('');
  final ValueNotifier<String> lastResponse = ValueNotifier('');
  final ValueNotifier<bool> isInSession = ValueNotifier(false);

  // ── Platform channels ──
  static const _dialerChannel = MethodChannel(
    'com.example.ai_voice_chat/dialer',
  );
  static const _whatsappChannel = MethodChannel(
    'com.example.ai_voice_chat/whatsapp',
  );
  static const _serviceChannel = MethodChannel(
    'com.example.ai_voice_chat/service',
  );

  static const _groqKey = openAiKey;
  static const _groqUrl = 'https://api.openai.com/v1/chat/completions';

  static const _wakeWords = [
    'hey adam',
    'hi adam',
    'hello adam',
    'ok adam',
    'okay adam',
    'adam listen',
    'adam wake up',
    'yo adam',
    'adam',
    'hey aadm',
    'hi aadm',
    'hello aadm',
    'aay adam',
    'aye adam',
    'hay adam',
    'marhaba adam',
    'bonjour adam',
    'salut adam',
    'hola adam',
    'oye adam',
    'hallo adam',
    'listen adam',
  ];

  static const _dismissWords = [
    'dismiss',
    'goodbye',
    'bye',
    'exit',
    'done',
    'cancel',
    'go away',
    'shut down',
    'khatam',
    'band karo',
    'rukho',
    'bas',
    'au revoir',
    'adios',
    'basta',
  ];

  // ════════════════════════════════════════════
  // ── Initialize ──
  // ════════════════════════════════════════════
  Future<bool> initialize(GlobalKey<NavigatorState> navKey) async {
    _navKey = navKey;
    if (_initialized) return _sttReady;
    debugPrint('ADAM: Initializing...');
    try {
      _sttReady = await _stt.initialize(
        onError: (e) {
          final err = e.errorMsg;
          debugPrint('ADAM STT Error: $err');
          if (!_isRunning || _isPaused || _appInBackground) return;

          if (err == 'error_client') {
            _scheduleRestart(seconds: 4);
            return;
          }
          if (state.value == WakeState.waiting) {
            _scheduleRestart(seconds: 2);
          } else if (state.value == WakeState.listening) {
            if (err == 'error_speech_timeout' || err == 'error_no_match') {
              debugPrint('ADAM: Command timeout — retrying once');
              Future.delayed(const Duration(milliseconds: 150), () {
                if (_isRunning &&
                    !_appInBackground &&
                    state.value == WakeState.listening) {
                  _startCommandListening();
                }
              });
            } else {
              Future.delayed(const Duration(milliseconds: 300), _deactivate);
            }
          }
        },
        onStatus: (status) {
          debugPrint('ADAM STT Status: $status');
          if ((status == 'done' || status == 'notListening') &&
              _isRunning &&
              !_isPaused &&
              !_appInBackground) {
            if (state.value == WakeState.waiting) {
              _scheduleRestart(seconds: 1);
            }
          }
        },
      );
      await _tts.setSpeechRate(0.44);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setLanguage('en-US');
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(() {
        debugPrint('ADAM TTS done (handler). state=${state.value}');
        // ── KEY FIX: If "Yes?" TTS completed and we're ready for command ──
        // _onWakeWord()'s await may not resume in background
        // so the handler triggers command listening directly
        if (_isRunning &&
            state.value == WakeState.activated &&
            (!_appInBackground || _foregroundServiceActive)) {
          debugPrint('ADAM: Handler → starting command listener');
          // Ensure external launches route through MainActivity
          if (_appInBackground) _cameFromBackground = true;
          Future.delayed(const Duration(milliseconds: 200), () {
            _startCommandListening();
          });
        }
      });
      _tts.setErrorHandler((e) => debugPrint('ADAM TTS error: $e'));
      _initialized = true;
    } catch (e) {
      debugPrint('ADAM Init Error: $e');
    }
    return _sttReady;
  }

  // ════════════════════════════════════════════
  // ── Enable / Disable ──
  // ════════════════════════════════════════════
  void enable() {
    if (!_initialized || !_sttReady) return;
    if (_isRunning && state.value != WakeState.disabled) return;
    debugPrint('ADAM: Enabling...');
    _isPaused = false;
    _isRunning = true;
    _sessionActive = false;
    _appInBackground = false;
    _launchedExternalApp = false;
    isInSession.value = false;
    state.value = WakeState.waiting;
    _showNotification();
    _startForegroundService(); // ── Start background listening service ──
    _startListening();
  }

  void disable() {
    debugPrint('ADAM: Disabling...');
    _restartTimer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _sessionActive = false;
    _appInBackground = false;
    _launchedExternalApp = false;
    _foregroundServiceActive = false;
    _lastActiveTime = null;
    isInSession.value = false;
    _stt.stop();
    _tts.stop();
    _hideOverlay();
    _cancelNotification();
    _stopForegroundService(); // ── Stop background service ──
    lastCommand.value = '';
    lastResponse.value = '';
    state.value = WakeState.disabled;
  }

  void pauseForScreen() {
    if (!_isRunning) return;
    _isPaused = true;
    _restartTimer?.cancel();
    _stt.stop();
    state.value = WakeState.paused;
  }

  void resumeAfterScreen() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _scheduleRestart(seconds: 1);
  }

  // ════════════════════════════════════════════
  // ── App Lifecycle ──
  // ════════════════════════════════════════════
  void onAppResumed() {
    if (!_isRunning) return;
    debugPrint('ADAM: App resumed...');
    _appInBackground = false;
    _restartTimer?.cancel();

    if (_wakeWordDetectedInBackground) {
      debugPrint('ADAM: Resume triggered by wake word — skipping resume flow');
      _isPaused = false;
      _appInBackground = false;
      return;
    }

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!_isRunning || _appInBackground) return;
      _isPaused = false;

      // Also check again — wake word might have been detected during delay
      if (_wakeWordDetectedInBackground) {
        debugPrint('ADAM: Wake word detected during resume delay — skipping');
        return;
      }

      if (_launchedExternalApp) {
        _launchedExternalApp = false;
        debugPrint('ADAM: Returned from external app...');
        // Restore session so user can give next command without wake word
        _sessionActive = true;
        isInSession.value = true;
        _lastActiveTime = DateTime.now();
        lastCommand.value = '';
        lastResponse.value = '';
        _restoringFromExternalApp = true;
        _showOverlay();
        // Short cooldown then start command listening (not wake word)
        Future.delayed(const Duration(milliseconds: 2000), () {
          _restoringFromExternalApp = false;
          if (_isRunning && !_appInBackground) {
            debugPrint('ADAM: Restoring command session after external app');
            _startCommandListening();
          }
        });
        return;
      }

      final recentlyActive =
          _lastActiveTime != null &&
          DateTime.now().difference(_lastActiveTime!).inMinutes < 10;

      if (_sessionActive || recentlyActive) {
        debugPrint('ADAM: Restoring active session...');
        if (_restoringFromExternalApp) return; // already restoring
        _sessionActive = true;
        isInSession.value = true;
        _showOverlay();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_isRunning &&
              !_appInBackground &&
              !_wakeWordDetectedInBackground) {
            _startCommandListening();
          }
        });
      } else {
        debugPrint('ADAM: Restarting wake word...');
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_isRunning &&
              !_appInBackground &&
              !_wakeWordDetectedInBackground) {
            _startListening();
          }
        });
      }
    });
  }

  void onAppPaused() {
    if (!_isRunning) return;
    debugPrint('ADAM: App paused...');
    _appInBackground = true;
    _wakeWordDetectedInBackground = false; // reset on each pause
    if (_sessionActive) _lastActiveTime = DateTime.now();

    if (_foregroundServiceActive) {
      debugPrint('ADAM: Background listening active via foreground service');
      _restartTimer?.cancel();

      if (state.value == WakeState.activated) {
        // ── Wake word just fired, TTS saying "Yes?" ──
        // Preserve state — handler will start command listening when TTS done
        debugPrint('ADAM: Wake word activated mid-flow — preserving state');
        // ── KEY FIX: Any external launch must go through MainActivity ──
        // because app is now in background
        _cameFromBackground = true;
        // Do NOT touch TTS, do NOT reset state, do NOT schedule anything
      } else if (state.value == WakeState.responding) {
        // Let TTS finish the response naturally
        debugPrint('ADAM: Letting response TTS finish before background mode');
        state.value = WakeState.waiting;
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (_isRunning && _appInBackground && _foregroundServiceActive) {
            _tts.stop();
            _startListening();
          }
        });
      } else if (state.value == WakeState.listening ||
          state.value == WakeState.processing) {
        state.value = WakeState.waiting;
        _tts.stop();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_isRunning && _appInBackground && _foregroundServiceActive) {
            _startListening();
          }
        });
      } else if (state.value == WakeState.waiting) {
        debugPrint('ADAM: Already in wake word mode, continuing in background');
      }
    } else {
      _stt.stop();
      _restartTimer?.cancel();
    }
  }

  bool get isEnabled => _isRunning && state.value != WakeState.disabled;

  // ════════════════════════════════════════════
  // ── Listening Loops ──
  // ════════════════════════════════════════════
  Future<void> _startListening() async {
    // ── Allow background listening if foreground service is active ──
    if (!_isRunning || _isPaused) return;
    if (_appInBackground && !_foregroundServiceActive) return;
    if (state.value == WakeState.disabled) return;
    // ── Don't start wake word if restoring command session ──
    if (_restoringFromExternalApp) {
      debugPrint('ADAM: Skipping wake word start — restoring session');
      return;
    }
    if (_stt.isListening) {
      await _stt.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    state.value = WakeState.waiting;
    debugPrint('ADAM: Listening for wake word...');
    try {
      await _stt.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            debugPrint('ADAM heard: "${result.recognizedWords}"');
          }
          _onResult(result.recognizedWords, result.finalResult);
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 4),
        localeId: 'en_US',
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('ADAM listen error: $e');
      _scheduleRestart(seconds: 2);
    }
  }

  Future<void> _startCommandListening() async {
    // Allow if foreground service active (background mode) or app is in front
    if (!_isRunning || _isPaused) return;
    if (_appInBackground && !_foregroundServiceActive) return;
    if (_stt.isListening) {
      await _stt.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    state.value = WakeState.listening;
    debugPrint('ADAM: Listening for command...');
    try {
      await _stt.listen(
        onResult: (result) =>
            _onResult(result.recognizedWords, result.finalResult),
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 15),
        localeId: 'en_US',
        partialResults: true,
      );
    } catch (e) {
      debugPrint('ADAM command listen error: $e');
      _deactivate();
    }
  }

  void _scheduleRestart({int seconds = 1}) {
    _restartTimer?.cancel();
    _restartTimer = Timer(Duration(seconds: seconds), () {
      if (_isRunning &&
          !_isPaused &&
          !_appInBackground &&
          (state.value == WakeState.waiting ||
              state.value == WakeState.paused)) {
        _startListening();
      }
    });
  }

  // ════════════════════════════════════════════
  // ── Wake Word Detection ──
  // ════════════════════════════════════════════
  void _onResult(String words, bool isFinal) {
    final lower = words.toLowerCase().trim();
    if (lower.isEmpty) return;
    switch (state.value) {
      case WakeState.waiting:
        if (_matchesWakeWord(lower)) {
          debugPrint('ADAM DETECTED: "$lower"');
          _onWakeWord();
        }
        break;
      case WakeState.listening:
        if (isFinal && lower.isNotEmpty) {
          lastCommand.value = words;
          _processCommand(lower);
        }
        break;
      default:
        break;
    }
  }

  bool _matchesWakeWord(String text) {
    // ── FIX 3: Cooldown — ignore wake words within 3s of last activation ──
    if (_lastWakeWordTime != null) {
      final elapsed = DateTime.now().difference(_lastWakeWordTime!).inSeconds;
      if (elapsed < 3) {
        debugPrint('ADAM: Wake word cooldown active ($elapsed s) — ignoring');
        return false;
      }
    }

    for (final w in _wakeWords) {
      if (w == 'adam') {
        if (RegExp(r'\badam\b').hasMatch(text) && !text.contains('madam')) {
          return true;
        }
      } else {
        if (text.contains(w)) return true;
      }
    }
    return false;
  }

  Future<void> _onWakeWord() async {
    _restartTimer?.cancel();
    await _stt.stop();
    state.value = WakeState.activated;
    _sessionActive = true;
    _lastActiveTime = DateTime.now();
    _lastWakeWordTime = DateTime.now(); // start cooldown
    isInSession.value = true;
    HapticFeedback.mediumImpact();

    // ── If in background, bring app to front first ──
    if (_appInBackground && _foregroundServiceActive) {
      debugPrint('ADAM: Wake word detected in background — bringing to front');
      // ── FIX: Set flags so onAppResumed() skips its normal flow ──
      _wakeWordDetectedInBackground = true;
      _appInBackground = false;
      try {
        await _serviceChannel.invokeMethod('bringToFront');
        // Fixed delay for activity transition — no Completer needed
        // External launches use the service directly anyway
        await Future.delayed(const Duration(milliseconds: 800));
        debugPrint('ADAM: bringToFront done — proceeding');
      } catch (e) {
        debugPrint('ADAM: bringToFront failed: $e');
        _wakeWordDetectedInBackground = false;
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    _showOverlay();
    await Future.delayed(const Duration(milliseconds: 400));
    await _tts.speak('Yes?');
    // ── FIX 2: Allow command listening even if app went to background ──
    // during "Yes?" TTS — foreground service keeps everything alive
    final canListen =
        _isRunning &&
        state.value == WakeState.activated &&
        (!_appInBackground || _foregroundServiceActive);

    if (canListen) {
      debugPrint('ADAM: Wake TTS done — starting command listener');
      _wakeWordDetectedInBackground = false;
      await _startCommandListening();
    } else {
      debugPrint(
        'ADAM: Cannot start command — running=$_isRunning bg=$_appInBackground service=$_foregroundServiceActive state=${state.value}',
      );
    }
  }

  Future<void> _onTtsDone() async {
    debugPrint('ADAM TTS done (backup handler). State=${state.value}');
  }

  Future<void> _continueAfterResponse() async {
    if (!_isRunning) return;
    debugPrint('ADAM: Response TTS done. state=${state.value}');
    if (state.value != WakeState.responding) return;
    if (_sessionActive && !_appInBackground) {
      _lastActiveTime = DateTime.now();
      await Future.delayed(const Duration(milliseconds: 300));
      lastCommand.value = '';
      lastResponse.value = '';
      await _startCommandListening();
    } else if (_sessionActive && _appInBackground) {
      lastCommand.value = '';
      lastResponse.value = '';
      _lastActiveTime = DateTime.now();
    } else {
      _deactivate();
    }
  }

  // ════════════════════════════════════════════
  // ── Master Command Handler ──
  // ════════════════════════════════════════════
  Future<String?> _handlePhoneCommand(String cmd) async {
    // ── 1. Forecast (7-day) ── check BEFORE current weather ──
    if (_hasAny(cmd, [
      'forecast',
      'week forecast',
      'weekly forecast',
      '7 day',
      'seven day',
      'next week weather',
      'week weather',
      'coming days',
      'this week weather',
      'agle hafte',
      'hafta',
      'poora hafta',
    ])) {
      return await _getWeatherWithCard(
        city: _extractCity(cmd),
        forecastMode: true,
      );
    }

    // ── 2. Current weather ──
    if (_hasAny(cmd, [
      'weather',
      'temperature',
      'rain',
      'sunny',
      'humidity',
      'climate',
      'degrees',
      'raining',
      'snowing',
      'whether',
      'chances of rain',
      'will it rain',
      'hot outside',
      'cold outside',
      'mausam',
      'barish',
      'aaj ka mausam',
      'current weather',
    ])) {
      return await _getWeatherWithCard(
        city: _extractCity(cmd),
        forecastMode: false,
      );
    }

    // ── 2. Time ──
    if (_hasAny(cmd, [
      'what time',
      'current time',
      'time is it',
      'time now',
      'tell me the time',
      'what is the time',
      'clock',
      'kitna baja',
      'waqt',
    ])) {
      final now = DateTime.now();
      final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final ampm = now.hour >= 12 ? 'PM' : 'AM';
      final m = now.minute.toString().padLeft(2, "0");
      return 'The current time is $h:$m $ampm.';
    }

    // ── 3. Date ──
    if (_hasAny(cmd, [
      'what day',
      'what date',
      'today date',
      'current date',
      'todays date',
      'what is today',
      'which day',
      'day is today',
      'date today',
      'day today',
      'what is the date',
      'aaj kaun sa',
      'aaj ki date',
    ])) {
      final now = DateTime.now();
      final months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      final days = [
        '',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return 'Today is ${days[now.weekday]}, ${now.day} ${months[now.month]} ${now.year}.';
    }

    // ── 4. Battery ──
    if (_hasAny(cmd, [
      'battery',
      'battery level',
      'how much charge',
      'power level',
      'how much battery',
      'charge level',
      'phone battery',
      'charging',
      'battery kitni',
    ])) {
      return await _getBattery();
    }

    // ── 5. WhatsApp (before generic call) ──
    if (_hasAny(cmd, [
      'whatsapp',
      'whats app',
      'open whatsapp',
      'whatsapp pe',
      'send whatsapp',
      'whatsapp message',
      'message on whatsapp',
      'whatsapp call',
      'on whatsapp',
      'send message to',
      'send a message to',
      'message to',
      'text to',
      'send message',
      'whatsapp karo',
      'message bhejo',
      'message bhej',
      'message kar',
      'whatsapp voice call',
      'whatsapp video call',
      'video call on whatsapp',
      'voice call on whatsapp',
      'call on whatsapp',
      'whatsapp pe call',
      'video call',
      'voice call',
    ])) {
      return await _handleWhatsApp(cmd);
    }

    // ── 6. Chat screen ──
    if (_hasAny(cmd, [
      'open chat',
      'go to chat',
      'text chat',
      'start chat',
      'adam chat',
      'chat screen',
      'open chatbox',
      'new chat',
      'chat with adam',
      'chat karo',
      'chat kholo',
    ])) {
      _navigateInApp('/chat');
      return 'Opening chat screen.';
    }

    // ── 7. Voice Chat screen ──
    if (_hasAny(cmd, [
      'voice chat',
      'open voice',
      'start voice',
      'voice screen',
      'go to voice',
      'voice mode',
      'open voice chat',
      'voice chat kholo',
    ])) {
      _navigateInApp('/voice');
      return 'Opening voice chat.';
    }

    // ── 8. Translation screen ──
    if (_hasAny(cmd, [
      'translate',
      'translation',
      'open translation',
      'translator',
      'language translate',
      'ai translation',
      'translation screen',
      'open translator',
      'go to translation',
      'translation kholo',
      'translate karo',
      'take me to translation',
    ])) {
      _navigateInApp('/translation');
      return 'Opening translation screen.';
    }

    // ── 9. Memory / History screen ──
    if (_hasAny(cmd, [
      'open memory',
      'my history',
      'past sessions',
      'memory screen',
      'show memory',
      'my chats',
      'all sessions',
      'show history',
      'open history',
      'history screen',
      'go to memory',
      'memory kholo',
      'history kholo',
      'purani baatein',
      'memory page',
    ])) {
      _navigateInApp('/memory');
      return 'Opening memory screen.';
    }

    // ── 10. Task manager screen ──
    if (_hasAny(cmd, [
      'open task manager',
      'open tasks screen',
      'go to tasks',
      'task manager screen',
      'task screen',
      'task manager kholo',
      'tasks kholo',
      'task page',
    ])) {
      _navigateInApp('/tasks');
      return 'Opening task manager.';
    }

    // ── 11. Settings ──
    if (_hasAny(cmd, [
      'settings',
      'open settings',
      'settings screen',
      'go to settings',
      'adam settings',
      'app settings',
      'show settings',
      'settings kholo',
    ])) {
      _navigateInApp('/settings');
      return 'Opening settings.';
    }

    // ── 12. Dashboard / Home ──
    if (_hasAny(cmd, [
      'go home',
      'open home',
      'dashboard',
      'main screen',
      'home screen',
      'adam home',
      'go to home',
      'main page',
      'ghar jao',
      'home kholo',
    ])) {
      _navigateInApp('/dashboard');
      return 'Going to home screen.';
    }

    // ── 13. Image generation ──
    if (_hasAny(cmd, [
      'generate image',
      'create image',
      'make image',
      'ai image',
      'create a picture',
      'draw something',
      'image banao',
    ])) {
      _navigateInApp('/chat');
      return 'Opening image generation.';
    }

    // ── 14. Read tasks ──
    if (_hasAny(cmd, [
      'my tasks',
      'my task',
      'show tasks',
      'show task',
      'list tasks',
      'task list',
      'what are my tasks',
      'pending tasks',
      'tell me my tasks',
      'read my tasks',
      'show me tasks',
      'what tasks',
      'meri tasks',
      'tasks batao',
      'task batao',
      'tasks dikhao',
      'tasks sunao',
    ])) {
      return await _readAndSpeakTasks();
    }

    // ── 15. Add task ──
    if (_hasAny(cmd, [
      'add task',
      'create task',
      'new task',
      'add a task',
      'add reminder',
      'task add karo',
      'naya task',
      'task banana',
    ])) {
      _navigateInApp('/tasks');
      return 'Opening task manager to add a new task.';
    }

    // ── 16. Clear ALL history ──
    if (_hasAny(cmd, [
      'clear history',
      'delete history',
      'clear all history',
      'delete all chats',
      'wipe history',
      'clear my chats',
      'delete my history',
      'clear everything',
      'delete everything',
      'wipe all data',
      'sab delete karo',
      'history mita do',
      'history saaf karo',
      'delete all sessions',
      'clear all',
      'delete all',
      'delete tasks',
      'clear tasks',
      'delete all tasks',
      'clear all tasks',
      'sab kuch delete',
      'sab kuch saaf',
      'wipe everything',
    ])) {
      return await _clearAllHistory();
    }

    // ── 17. Clear chat only ──
    if (_hasAny(cmd, [
      'clear chat',
      'delete chat',
      'remove chat',
      'clear text chat',
      'delete text chat',
      'chat delete karo',
    ])) {
      return await _clearHistoryByType('chat');
    }

    // ── 18. Clear voice only ──
    if (_hasAny(cmd, [
      'clear voice',
      'delete voice',
      'remove voice history',
      'clear voice history',
      'delete voice chat',
    ])) {
      return await _clearHistoryByType('voice');
    }

    // ── 19. Clear translation only ──
    if (_hasAny(cmd, [
      'clear translation',
      'delete translation',
      'clear translation history',
    ])) {
      return await _clearHistoryByType('translation');
    }

    // ── 20. Count sessions ──
    if (_hasAny(cmd, [
      'how many chats',
      'how many sessions',
      'count chats',
      'total sessions',
      'chat count',
      'kitni sessions',
    ])) {
      return await _countSessions();
    }

    // ── 21. Maps ──
    if (_hasAny(cmd, [
      'navigate to',
      'navigate me to',
      'directions to',
      'route to',
      'how to get to',
      'take me to',
      'start navigation',
      'start navigation to',
      'open maps',
      'google maps',
      'open google map',
      'find location',
      'where is',
      'search on map',
      'location of',
      'maps kholo',
      'rasta batao',
      'le chalo',
      'jana hai',
      'location batao',
      'show location',
      'nearest',
      'near me',
      'close to me',
      'nearby',
      'qareeb',
      'find nearest',
      'find nearby',
      'closest',
    ])) {
      return await _handleMaps(cmd);
    }

    // ── 22. Phone call ──
    if (_hasAny(cmd, [
      'call',
      'dial',
      'phone call',
      'ring',
      'make a call',
      'give a call',
      'place a call',
      'call karo',
      'phone karo',
      'ring karo',
      'contact',
      'contacts',
    ])) {
      return await _handlePhoneCall(cmd);
    }

    // ── 23. YouTube ──
    if (_hasAny(cmd, [
      'youtube',
      'open youtube',
      'play on youtube',
      'search youtube',
      'watch on youtube',
      'youtube pe',
      'youtube kholo',
      'video dekhna',
    ])) {
      return await _handleYouTube(cmd);
    }

    // ── 24. Calculator ──
    if (_hasAny(cmd, [
      'calculator',
      'open calculator',
      'calculate',
      'compute',
      'calculator kholo',
      'hisaab',
    ])) {
      return await _handleCalculator();
    }

    // ── 25. Google Search ──
    if (_hasAny(cmd, [
      'search for',
      'google search',
      'look up',
      'search on google',
      'find on google',
      'open google',
      'browse',
      'search the web',
      'google',
      'google pe dhundo',
      'search karo',
    ])) {
      return await _handleGoogleSearch(cmd);
    }

    // ── 26. Flashlight ──
    if (_hasAny(cmd, [
      'flashlight',
      'torch',
      'turn on torch',
      'turn off torch',
      'flash on',
      'flash off',
      'torch on',
      'torch off',
      'light on',
      'light off',
      'torchlight',
      'torch jala',
      'torch bujha',
      'torch band karo',
      'torch chalu karo',
    ])) {
      return await _handleFlashlight(cmd);
    }

    // ── 27. Volume ──
    if (_hasAny(cmd, [
      'volume up',
      'increase volume',
      'louder',
      'volume barhao',
      'volume down',
      'decrease volume',
      'lower volume',
      'quieter',
      'volume kam karo',
      'mute',
      'unmute',
      'silent mode',
      'ring mode',
      'volume max',
      'volume zero',
      'full volume',
    ])) {
      return await _handleVolume(cmd);
    }

    // ── 28. Set Alarm ──
    if (_hasAny(cmd, [
      'set alarm',
      'alarm at',
      'wake me up',
      'alarm for',
      'remind me at',
      'set a reminder',
      'reminder at',
      'alarm laga do',
      'alarm set karo',
      'uthana',
    ])) {
      return await _handleSetAlarm(cmd);
    }

    // ── 29. Add Task ──
    if (_hasAny(cmd, [
      'add task',
      'create task',
      'new task',
      'add to tasks',
      'add a task',
      'task add karo',
      'task banana',
      'task banao',
      'remember to',
      'note down',
      'make a note',
    ])) {
      return await _handleAddTask(cmd);
    }

    // ── 30. SMS ──
    if (_hasAny(cmd, [
      'send sms',
      'send text',
      'text message',
      'send message via sms',
      'sms to',
      'text to',
      'message to',
    ])) {
      return await _handleSms(cmd);
    }

    return null;
  }

  // ════════════════════════════════════════════
  // ── Process Command ──
  // ════════════════════════════════════════════
  Future<void> _processCommand(String command) async {
    await _stt.stop();

    final lower = command.toLowerCase().trim();
    final isJustWakeWord =
        _wakeWords.any((w) => lower == w) ||
        lower == 'adam' ||
        lower == 'hey' ||
        lower == 'hi' ||
        lower == 'okay' ||
        lower == 'ok' ||
        lower.length < 3;
    if (isJustWakeWord) {
      debugPrint(
        'ADAM: Ignoring noise/wake-word in command listener: "$command"',
      );
      await _startCommandListening();
      return;
    }

    // ── Filter single-word noise unless it's a known command ──
    final knownSingle = [
      'battery',
      'weather',
      'time',
      'date',
      'shutdown',
      'stop',
      'cancel',
      'maps',
      'whatsapp',
      'youtube',
      'calculator',
    ];
    if (lower.split(' ').length == 1 && !knownSingle.contains(lower)) {
      debugPrint('ADAM: Ignoring single-word noise: "$command"');
      await _startCommandListening();
      return;
    }

    debugPrint('ADAM Processing: "$command"');
    state.value = WakeState.processing;
    _lastActiveTime = DateTime.now();

    if (_dismissWords.any((w) => command.contains(w))) {
      _sessionActive = false;
      isInSession.value = false;
      state.value = WakeState.responding;
      await _tts.speak('Goodbye.');
      _deactivate();
      return;
    }

    final response = await _handlePhoneCommand(command);
    if (response != null) {
      debugPrint('ADAM Response: "$response"');
      lastResponse.value = response;
      state.value = WakeState.responding;
      await _tts.speak(response);
      await _continueAfterResponse();
      return;
    }

    // AI fallback via Groq
    try {
      final res = await http
          .post(
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
                      'You are ADAM, an intelligent AI voice assistant like JARVIS. '
                      'Respond in the same language the user spoke. '
                      'Keep response to maximum 2 short sentences. Be direct and helpful.',
                },
                {'role': 'user', 'content': command},
              ],
              'max_tokens': 100,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final text = (data['choices'][0]['message']['content'] as String)
            .trim();
        lastResponse.value = text;
        state.value = WakeState.responding;
        await _tts.speak(text);
        await _continueAfterResponse();
      } else {
        state.value = WakeState.responding;
        await _tts.speak('I encountered an error. Please try again.');
        await _continueAfterResponse();
      }
    } catch (e) {
      debugPrint('ADAM Groq Error: $e');
      state.value = WakeState.responding;
      await _tts.speak('Connection error. Please check your network.');
      await _continueAfterResponse();
    }
  }

  // ════════════════════════════════════════════
  // ── Deactivate ──
  // ════════════════════════════════════════════
  void _deactivate() {
    debugPrint('ADAM: Deactivating...');
    lastCommand.value = '';
    lastResponse.value = '';
    _sessionActive = false;
    isInSession.value = false;
    _hideOverlay();
    state.value = WakeState.waiting;
    if (_isRunning && !_isPaused && !_appInBackground) {
      _restartTimer?.cancel();
      _restartTimer = Timer(const Duration(milliseconds: 800), () {
        if (_isRunning && !_isPaused && !_appInBackground) {
          _startListening();
        }
      });
    }
  }

  // ════════════════════════════════════════════
  // ── Navigate in App ──
  // ════════════════════════════════════════════
  void _navigateInApp(String route) {
    debugPrint('ADAM: Navigating to $route');
    Future.delayed(const Duration(milliseconds: 400), () {
      try {
        Get.toNamed(route);
        debugPrint('ADAM: Navigated to $route ✓');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (_isRunning && !_appInBackground) {
            _sessionActive = true;
            isInSession.value = true;
            // ── FIX: Don't interrupt if TTS is still speaking ──
            if (state.value != WakeState.responding &&
                state.value != WakeState.processing) {
              state.value = WakeState.waiting;
              _scheduleRestart(seconds: 1);
            }
          }
        });
      } catch (e) {
        debugPrint('ADAM Nav Error: $e');
        _navKey?.currentState?.pushNamed(route);
      }
    });
  }

  // ════════════════════════════════════════════
  // ── Firestore: Tasks ──
  // ════════════════════════════════════════════
  Future<String> _readAndSpeakTasks() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 'You are not logged in.';

      QuerySnapshot? snap;
      try {
        snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('task_history')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();
      } catch (_) {}

      if (snap == null || snap.docs.isEmpty) {
        try {
          snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('tasks')
              .limit(5)
              .get();
        } catch (_) {}
      }

      if (snap == null || snap.docs.isEmpty) {
        return 'You have no tasks yet.';
      }

      final tasks = <String>[];
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final title =
            data['title'] as String? ??
            data['text'] as String? ??
            data['name'] as String? ??
            data['task'] as String? ??
            '';
        final done =
            data['isCompleted'] as bool? ?? data['completed'] as bool? ?? false;
        if (title.isNotEmpty) {
          tasks.add('$title — ${done ? "completed" : "pending"}');
        }
      }

      if (tasks.isEmpty) return 'Your task manager is empty.';
      if (tasks.length == 1) return 'You have one task: ${tasks[0]}.';
      final spoken = tasks.take(3).join('. Next task: ');
      return 'You have ${tasks.length} tasks. Here are the latest: $spoken.';
    } catch (e) {
      debugPrint('ADAM Read Tasks Error: $e');
      _navigateInApp('/tasks');
      return 'Let me open your task manager.';
    }
  }

  Future<String> _clearAllHistory() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 'You are not logged in.';
      int deleted = 0;

      // Delete sessions
      try {
        final sessions = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .get();
        for (final s in sessions.docs) {
          final msgs = await s.reference.collection('messages').get();
          for (final m in msgs.docs) {
            await m.reference.delete();
          }
          await s.reference.delete();
          deleted++;
        }
      } catch (_) {}

      // Delete task_history
      try {
        final th = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('task_history')
            .get();
        for (final d in th.docs) {
          await d.reference.delete();
          deleted++;
        }
      } catch (_) {}

      // Delete tasks
      try {
        final tasks = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('tasks')
            .get();
        for (final d in tasks.docs) {
          await d.reference.delete();
          deleted++;
        }
      } catch (_) {}

      return deleted > 0
          ? 'Done. I permanently deleted $deleted items.'
          : 'Everything is already empty.';
    } catch (e) {
      debugPrint('ADAM Clear All Error: $e');
      return 'Could not clear data. Please try from Settings.';
    }
  }

  Future<String> _clearHistoryByType(String type) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 'You are not logged in.';
      final sessions = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .where('type', isEqualTo: type)
          .get();
      if (sessions.docs.isEmpty) return 'No $type history found.';
      int deleted = 0;
      for (final s in sessions.docs) {
        final msgs = await s.reference.collection('messages').get();
        for (final m in msgs.docs) {
          await m.reference.delete();
        }
        await s.reference.delete();
        deleted++;
      }
      return 'Deleted $deleted $type sessions.';
    } catch (_) {
      return 'Could not clear $type history.';
    }
  }

  Future<String> _countSessions() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 'Not logged in.';
      final s = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .get();
      final chat = s.docs.where((d) => (d.data())['type'] == 'chat').length;
      final voice = s.docs.where((d) => (d.data())['type'] == 'voice').length;
      final tr = s.docs
          .where((d) => (d.data())['type'] == 'translation')
          .length;
      return 'You have ${s.docs.length} sessions: $chat chat, $voice voice, $tr translation.';
    } catch (_) {
      return 'Could not count sessions.';
    }
  }

  // ════════════════════════════════════════════
  // ── WhatsApp Handler (JARVIS style) ──
  // ════════════════════════════════════════════
  Future<String> _handleWhatsApp(String cmd) async {
    final lower = cmd.toLowerCase().trim();

    // ── FIX 1: Detect call type with regex for "call NAME on whatsapp" ──
    final isVideoCall = _hasAny(lower, [
      'video call',
      'video chat',
      'video pe',
      'video karo',
    ]);
    // Catches: "call baba on whatsapp", "open whatsapp and call baba",
    //          "whatsapp call baba", "voice call baba on whatsapp"
    final isVoiceCall =
        !isVideoCall &&
        (_hasAny(lower, [
              'whatsapp call',
              'voice call on whatsapp',
              'whatsapp pe call',
              'call karo whatsapp',
              'call via whatsapp',
              'whatsapp voice',
            ]) ||
            // Generic: any command with both "whatsapp" + "call" = voice call
            (lower.contains('whatsapp') && lower.contains('call')));

    final message = _extractWhatsAppMessage(lower);
    final contactName = _extractWhatsAppContact(lower);
    final rawNumber = _extractPhoneNumber(cmd);

    debugPrint(
      'ADAM WA: contact="$contactName" msg="$message" num="$rawNumber" voice=$isVoiceCall video=$isVideoCall',
    );

    // Just open WhatsApp — use https://wa.me directly (whatsapp:// fails on some devices)
    if (contactName == null && rawNumber == null) {
      // Use package URI to open WhatsApp directly (no invalid link error)
      await _launch('whatsapp://');
      return 'Opening WhatsApp.';
    }

    // Resolve number
    String? phoneNumber = rawNumber;
    String displayName = rawNumber ?? '';
    if (contactName != null) {
      displayName = contactName;
      final found = await _findContactNumber(contactName);
      if (found != null) {
        phoneNumber = found;
      } else {
        return 'I could not find $contactName in your contacts for WhatsApp.';
      }
    }

    // ── Normalize for WhatsApp URL (digits only, with country code, no leading 0) ──
    final cleanNumber = _normalizeForWhatsApp(phoneNumber ?? '');
    debugPrint('ADAM WA: cleanNumber="$cleanNumber" from raw="$phoneNumber"');
    if (cleanNumber.isEmpty) {
      return 'Could not find a valid number for WhatsApp.';
    }

    // ── FIX: Arm accessibility flag BEFORE opening for calls too ──
    // ── WhatsApp Voice Call ──
    if (isVoiceCall) {
      try {
        await _whatsappChannel.invokeMethod('prepareAutoVoiceCall');
      } catch (_) {}
      debugPrint(
        'ADAM WA: autoVoiceCall armed → opening https://wa.me/$cleanNumber',
      );
      await _launch('https://wa.me/$cleanNumber');
      return 'Starting WhatsApp voice call with $displayName.';
    }

    // ── WhatsApp Video Call ──
    if (isVideoCall) {
      try {
        await _whatsappChannel.invokeMethod('prepareAutoVideoCall');
      } catch (_) {}
      debugPrint(
        'ADAM WA: autoVideoCall armed → opening https://wa.me/$cleanNumber',
      );
      await _launch('https://wa.me/$cleanNumber');
      return 'Starting WhatsApp video call with $displayName.';
    }

    // ── Open specific chat only ──
    if (message == null || message.isEmpty) {
      debugPrint('ADAM WA: Opening chat → https://wa.me/$cleanNumber');
      await _launch('https://wa.me/$cleanNumber');
      return 'Opening WhatsApp chat with $displayName.';
    }

    // ── Send message with auto-send ──
    final encoded = Uri.encodeComponent(message);
    debugPrint(
      'ADAM WA: Sending "$message" to $displayName → https://wa.me/$cleanNumber',
    );
    try {
      await _whatsappChannel.invokeMethod('prepareAutoSend');
    } catch (_) {}
    await _launch('https://wa.me/$cleanNumber?text=$encoded');
    return 'Sending message to $displayName.';
  }

  // ── Noise words that should NEVER be contact names ──
  static const _waNoiseWords = {
    'hi',
    'hello',
    'hey',
    'the',
    'a',
    'an',
    'my',
    'me',
    'now',
    'please',
    'ok',
    'okay',
    'and',
    'or',
    'for',
    'to',
    'on',
    'in',
    'at',
    'with',
    'send',
    'open',
    'message',
    'msg',
    'text',
    'whatsapp',
    'chat',
    'call',
    'via',
    'through',
    'using',
    'some',
    'this',
    'that',
    'it',
    'him',
    'her',
    'them',
    'voice',
    'video',
    'saying',
    'say',
  };

  String? _cleanContactName(String? raw) {
    if (raw == null) return null;
    var name = raw
        .trim()
        .replaceAll(RegExp(r"'s$"), '')
        .replaceAll(
          RegExp(
            r'\b(whatsapp|please|now|ok|okay|on|via|through|and|the|a)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (name.isEmpty || name.length < 2) return null;
    if (_waNoiseWords.contains(name.toLowerCase())) return null;
    return name;
  }

  // ── Normalize phone number for WhatsApp deep link ──
  // WhatsApp URL requires: digits only + country code, no +, no leading 0
  // Input can be: +923001234567 / 03001234567 / 923001234567 / 3001234567
  String _normalizeForWhatsApp(String raw) {
    // Remove everything except digits and leading +
    var digits = raw.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return '';

    // Already has country code (starts with 92 for Pakistan, length ~12)
    if (digits.startsWith('92') && digits.length >= 11) {
      return digits; // e.g. 923001234567
    }

    // Starts with 0 (local Pakistani format: 03001234567)
    if (digits.startsWith('0') && digits.length >= 10) {
      return '92${digits.substring(1)}'; // 0300... → 92300...
    }

    // No country code, no leading 0 (e.g. 3001234567)
    if (digits.length == 10) {
      return '92$digits'; // → 923001234567
    }

    // Already international without + (e.g. 923001234567)
    if (digits.length >= 11) {
      return digits;
    }

    return digits;
  }

  String? _extractWhatsAppContact(String cmd) {
    final patterns = [
      // ── MOST SPECIFIC FIRST ──

      // "chat with NAME"
      RegExp(
        r'\bchat\s+with\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\b',
        caseSensitive: false,
      ),

      // "to NAME on/via whatsapp"
      RegExp(
        r'\bto\s+([a-zA-Z]+)\s+(?:on|via|through|using)\s+whatsapp',
        caseSensitive: false,
      ),

      // "send X to NAME" at end — catches "send good morning to baba"
      RegExp(r'\bsend\s+.+?\s+to\s+([a-zA-Z]+)\s*$', caseSensitive: false),

      // "message to NAME" / "send message to NAME"
      RegExp(
        r'\b(?:send\s+)?(?:a\s+)?message\s+to\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)(?:\s+on\s+whatsapp|\s+saying|\s*$)',
        caseSensitive: false,
      ),
      RegExp(
        r'\bmessage\s+to\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)(?:\s+saying|\s+on\s+whatsapp|\s*$)',
        caseSensitive: false,
      ),

      // "call NAME on/via/through whatsapp"
      RegExp(
        r'\bcall\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\s+(?:on|via|through|using)\s+whatsapp',
        caseSensitive: false,
      ),

      // "call NAME" at end
      RegExp(
        r'\bcall\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\s*$',
        caseSensitive: false,
      ),

      // "video call NAME on whatsapp" or "video call NAME"
      RegExp(
        r'\bvideo\s+call\s+(?:to\s+)?([a-zA-Z]+(?:\s+[a-zA-Z]+)?)(?:\s+on\s+whatsapp|\s*$)',
        caseSensitive: false,
      ),

      // "open NAME's whatsapp"
      RegExp(
        r"\bopen\s+([a-zA-Z]+(?:'s|\s+[a-zA-Z]+)?)\s+whatsapp",
        caseSensitive: false,
      ),

      // "whatsapp NAME and/to/message"
      RegExp(
        r'\bwhatsapp\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\s+(?:and|to|saying|that|message)\b',
        caseSensitive: false,
      ),

      // "text to NAME saying"
      RegExp(
        r'\btext\s+(?:to\s+)?([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\s+(?:saying|that)\b',
        caseSensitive: false,
      ),

      // "send NAME a/the message"
      RegExp(
        r'\bsend\s+([a-zA-Z]+)\s+(?:a\s+|the\s+)?(?:message|msg|text)\b',
        caseSensitive: false,
      ),

      // "to NAME" anywhere — last resort
      RegExp(r'\bto\s+([a-zA-Z]+)\s*$', caseSensitive: false),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(cmd);
      if (m != null) {
        final name = _cleanContactName(m.group(1));
        if (name != null) {
          debugPrint('ADAM WA: Extracted contact: "$name"');
          return name;
        }
      }
    }
    return null;
  }

  String? _extractWhatsAppMessage(String cmd) {
    String? cleanMsg(String? raw) {
      if (raw == null) return null;
      var msg = raw
          .trim()
          // Remove trailing "on whatsapp" / "via whatsapp"
          .replaceAll(
            RegExp(r'\s+(?:on|via)\s+whatsapp\s*$', caseSensitive: false),
            '',
          )
          // Remove trailing "to NAME"
          .replaceAll(
            RegExp(r'\s+to\s+[a-zA-Z]+\s*$', caseSensitive: false),
            '',
          )
          .trim();
      // Only reject if structurally empty — NOT based on content
      // "hi", "ok", "hello" are all valid messages!
      if (msg.isEmpty) return null;
      return msg;
    }

    final patterns = [
      // "send HI message to NAME" → captures "hi" (most specific first)
      RegExp(r'\bsend\s+(.+?)\s+message\s+to\b', caseSensitive: false),

      // "the message HI" / "a message HI"
      RegExp(r'\b(?:the|a)\s+message\s+(.+)$', caseSensitive: false),

      // "send message HI"
      RegExp(r'\bsend\s+message\s+(.+)$', caseSensitive: false),

      // "and send HI" at end (e.g. "open chat with baba and send hi")
      RegExp(r'\band\s+send\s+(.+)$', caseSensitive: false),

      // "saying HI" / "say HI" / "tell him HI"
      RegExp(
        r'\b(?:saying|say|tell him|tell her|tell them|with message|message is|text is)\s+(.+)$',
        caseSensitive: false,
      ),

      // "message/msg him/her saying HI"
      RegExp(
        r'\b(?:message|msg)\s+(?:him|her|them|saying|that)\s+(.+)$',
        caseSensitive: false,
      ),

      // "send NAME a/the message HI" (message at end)
      RegExp(
        r'\bsend\s+\w+\s+(?:a\s+|the\s+)?(?:message|msg|text)\s+(.+)$',
        caseSensitive: false,
      ),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(cmd);
      if (m != null) {
        final msg = cleanMsg(m.group(1));
        if (msg != null) {
          debugPrint('ADAM WA: Extracted message: "$msg"');
          return msg;
        }
      }
    }
    return null;
  }

  // ════════════════════════════════════════════
  // ── Phone Call Handler ──
  // ════════════════════════════════════════════
  Future<String> _handlePhoneCall(String cmd) async {
    String? dialNumber;
    String displayName = '';

    final number = _extractPhoneNumber(cmd);
    if (number != null) {
      dialNumber = number;
      displayName = number;
    } else {
      final name = _extractContactName(cmd);
      if (name != null && name.isNotEmpty) {
        displayName = name;
        final found = await _findContactNumber(name);
        if (found != null) {
          dialNumber = found;
        } else {
          return 'I could not find $name in your contacts.';
        }
      }
    }

    if (dialNumber == null || dialNumber.isEmpty) {
      return 'Who would you like to call?';
    }

    // Request CALL_PHONE permission
    debugPrint('ADAM: Requesting CALL_PHONE permission...');
    final callPermStatus = await Permission.phone.request();
    debugPrint('ADAM: CALL_PHONE permission: $callPermStatus');

    if (!callPermStatus.isGranted) {
      _launchedExternalApp = true;
      await _launch('tel:$dialNumber');
      return 'Please grant call permission. Opening dialer for now.';
    }

    // Show SIM picker
    debugPrint('ADAM: Showing SIM picker for $displayName');
    final simChoice = await _showSimPicker(displayName);
    debugPrint('ADAM: SIM choice = $simChoice');

    if (simChoice == null) {
      _scheduleRestart(seconds: 1);
      return 'Call cancelled.';
    }

    // Dial via platform channel
    try {
      debugPrint('ADAM: Dialing $dialNumber on SIM $simChoice');
      await _dialerChannel.invokeMethod('makeCall', {
        'number': dialNumber,
        'simSlot': simChoice,
      });
      return 'Calling $displayName.';
    } catch (e) {
      debugPrint('ADAM Direct Call Error: $e');
      _launchedExternalApp = true;
      await _launch('tel:$dialNumber');
      return 'Opening dialer for $displayName.';
    }
  }

  Future<int?> _showSimPicker(String contactName) async {
    final context = _navKey?.currentContext;
    if (context == null) {
      debugPrint('ADAM: No context — defaulting to SIM 1');
      return 1;
    }
    _restartTimer?.cancel();
    await _stt.stop();

    // Hide ADAM overlay so SIM picker is fully visible
    _hideOverlay();

    debugPrint('ADAM: Showing SIM picker');
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (_) => _SimPickerSheet(contactName: contactName),
    );

    debugPrint('ADAM: SIM picker returned: $result');

    // Restore overlay after selection
    if (_sessionActive && _isRunning) _showOverlay();

    return result;
  }

  String? _extractContactName(String cmd) {
    final contactPattern = RegExp(r'\bcontacts?\s+(.+)', caseSensitive: false);
    final contactMatch = contactPattern.firstMatch(cmd);
    if (contactMatch != null) {
      final name = contactMatch.group(1)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    var name = cmd
        .replaceAll(
          RegExp(
            r'\b(call|dial|ring|phone|make a call|give a call|place a call|please|open|dialer|and|the|contact|contacts|for|me|now|number|okay|ok|karo|kar|from)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return name.isNotEmpty ? name : null;
  }

  // ════════════════════════════════════════════
  // ── Contact Search (Scored) ──
  // ════════════════════════════════════════════
  Future<String?> _findContactNumber(String name) async {
    try {
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        debugPrint('ADAM: Contacts permission denied');
        return null;
      }

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final query = name.toLowerCase().trim();

      int score(String displayName) {
        final dn = displayName.toLowerCase();
        final parts = dn.split(' ');
        if (dn == query) return 100;
        if (parts.last == query) return 80;
        if (parts.first == query) return 70;
        if (parts.any((p) => p == query)) return 60;
        if (dn.startsWith(query)) return 40;
        if (dn.contains(query)) return 20;
        return 0;
      }

      Contact? best;
      int bestScore = 0;
      for (final c in contacts) {
        if (c.phones.isEmpty) continue;
        final s = score(c.displayName);
        if (s > bestScore) {
          bestScore = s;
          best = c;
        }
      }

      if (best != null && bestScore > 0) {
        final number = best.phones.first.number.replaceAll(
          RegExp(r'[\s\-()]'),
          '',
        );
        debugPrint(
          'ADAM: Best match "${best.displayName}" (score=$bestScore) → $number',
        );
        return number;
      }
      debugPrint('ADAM: No contact found for: $name');
    } catch (e) {
      debugPrint('ADAM Contacts Error: $e');
    }
    return null;
  }

  // ════════════════════════════════════════════
  // ── Other App Handlers ──
  // ════════════════════════════════════════════
  Future<String> _handleMaps(String cmd) async {
    _launchedExternalApp = true;
    final lower = cmd.toLowerCase();
    final dest = _extractDestination(cmd);

    // ── Detect intent: navigation vs just viewing location ──
    final isNavigation = _hasAny(lower, [
      'navigate',
      'navigation',
      'directions',
      'route',
      'take me',
      'how to get',
      'start navigation',
      'le chalo',
      'jana hai',
      'rasta',
    ]);

    if (dest != null && dest.isNotEmpty) {
      final encoded = Uri.encodeComponent(dest);

      if (isNavigation) {
        // ── Navigation: use google.navigation in foreground (auto-starts)
        // Use HTTPS in background (opens Maps from background)
        if (!_appInBackground) {
          // Foreground → google.navigation:// starts turn-by-turn directly ✅
          final ok = await _launch('google.navigation:q=$encoded&mode=d');
          if (ok) return 'Starting navigation to $dest.';
        } else {
          // Background → HTTPS works but user needs to tap Start
          final ok = await _launch(
            'https://www.google.com/maps/dir/?api=1'
            '&destination=$encoded&travelmode=driving',
          );
          if (ok) return 'Starting navigation to $dest.';
        }

        // Fallback: use geo: URI which triggers navigation in Maps
        final geoUri = Uri.parse('geo:0,0?q=$encoded');
        try {
          if (await canLaunchUrl(geoUri)) {
            await _launch(geoUri.toString());
            return 'Starting navigation to $dest.';
          }
        } catch (_) {}

        // Final fallback: web URL with directions mode
        await _launch(
          'https://www.google.com/maps/dir/?api=1'
          '&destination=$encoded'
          '&travelmode=driving',
        );
        return 'Starting navigation to $dest.';
      } else {
        // ── Just show location on map (search mode) ──
        // Try Maps app first
        final geoUri = Uri.parse('geo:0,0?q=$encoded');
        try {
          if (await canLaunchUrl(geoUri)) {
            await _launch(geoUri.toString());
            return 'Showing $dest on Google Maps.';
          }
        } catch (_) {}

        // Fallback: web search
        await _launch(
          'https://www.google.com/maps/search/?api=1&query=$encoded',
        );
        return 'Showing $dest on Google Maps.';
      }
    }

    // ── "nearest X" — search near current location ──
    final isNearest = _hasAny(lower, [
      'nearest',
      'near me',
      'nearby',
      'closest',
      'qareeb',
    ]);
    if (isNearest) {
      final query = cmd
          .replaceAll(
            RegExp(
              r'\b(nearest|find nearest|nearby|find nearby|closest|near me|qareeb|find|get me|show me|give me the)\b',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (query.isNotEmpty) {
        final encoded = Uri.encodeComponent(query);
        // "near me" search opens Maps with nearby results
        final geoUri = Uri.parse('geo:0,0?q=$encoded+near+me');
        try {
          if (await canLaunchUrl(geoUri)) {
            await _launch(geoUri.toString());
            return 'Finding nearest $query on Google Maps.';
          }
        } catch (_) {}
        await _launch('https://www.google.com/maps/search/$encoded+near+me');
        return 'Finding nearest $query near you.';
      }
    }

    // ── No destination — just open Maps ──
    await _launch('https://www.google.com/maps');
    return 'Opening Google Maps.';
  }

  // ══════════════════════════════════════════════
  // ── 26. Flashlight Handler ──
  // ══════════════════════════════════════════════
  Future<String> _handleFlashlight(String cmd) async {
    final lower = cmd.toLowerCase();
    final turnOn = _hasAny(lower, [
      'turn on',
      'on',
      'jala',
      'chalu',
      'enable',
      'flash on',
      'torch on',
      'light on',
    ]);
    final turnOff = _hasAny(lower, [
      'turn off',
      'off',
      'bujha',
      'band',
      'disable',
      'flash off',
      'torch off',
      'light off',
    ]);

    try {
      if (turnOff) {
        await _serviceChannel.invokeMethod('setFlashlight', {'on': false});
        return 'Flashlight turned off.';
      } else {
        // Default to turning on
        await _serviceChannel.invokeMethod('setFlashlight', {'on': true});
        return 'Flashlight turned on.';
      }
    } catch (e) {
      debugPrint('Flashlight error: \$e');
      return 'Could not control flashlight.';
    }
  }

  // ══════════════════════════════════════════════
  // ── 27. Volume Handler ──
  // ══════════════════════════════════════════════
  Future<String> _handleVolume(String cmd) async {
    final lower = cmd.toLowerCase();

    String action = 'up';
    if (_hasAny(lower, [
      'down',
      'lower',
      'decrease',
      'quieter',
      'kam',
      'zero',
      'mute',
    ])) {
      action = 'down';
    } else if (_hasAny(lower, ['mute', 'silent'])) {
      action = 'mute';
    } else if (_hasAny(lower, ['unmute', 'ring'])) {
      action = 'unmute';
    } else if (_hasAny(lower, ['max', 'full', 'maximum'])) {
      action = 'max';
    }

    try {
      await _serviceChannel.invokeMethod('setVolume', {'action': action});
      switch (action) {
        case 'down':
          return 'Volume decreased.';
        case 'mute':
          return 'Device muted.';
        case 'unmute':
          return 'Device unmuted.';
        case 'max':
          return 'Volume set to maximum.';
        default:
          return 'Volume increased.';
      }
    } catch (e) {
      debugPrint('Volume error: \$e');
      return 'Could not adjust volume.';
    }
  }

  // ══════════════════════════════════════════════
  // ── 28. Set Alarm Handler ──
  // ══════════════════════════════════════════════
  Future<String> _handleSetAlarm(String cmd) async {
    final lower = cmd.toLowerCase();

    // Extract time from command
    // Patterns: "7am", "7:30am", "7 30", "7 o'clock"
    final timeRegex = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m|p\.m)?',
      caseSensitive: false,
    );
    final match = timeRegex.firstMatch(lower);

    if (match == null) {
      return 'Please say the time clearly, like "set alarm for 7 AM".';
    }

    int hour = int.parse(match.group(1)!);
    int minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3)?.toLowerCase();

    if (period == 'pm' && hour != 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    try {
      await _serviceChannel.invokeMethod('setAlarm', {
        'hour': hour,
        'minute': minute,
        'message': 'ADAM Alarm',
      });
      final timeStr =
          '${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")}';
      return 'Alarm set for \$timeStr.';
    } catch (e) {
      debugPrint('Alarm error: \$e');
      // Fallback: open clock app
      await _launch(
        'intent:#Intent;action=android.alarmclock.SET_ALARM;i.HOUR=\$hour;i.MINUTES=\$minute;end',
      );
      return 'Opening clock to set alarm for $hour:${minute.toString().padLeft(2, "0")}.';
    }
  }

  // ══════════════════════════════════════════════
  // ── 29. Add Task Handler ──
  // ══════════════════════════════════════════════
  Future<String> _handleAddTask(String cmd) async {
    // Extract task title
    String title = cmd
        .replaceAll(
          RegExp(
            r'\b(add task|create task|new task|add a task|add to tasks|'
            r'remember to|note down|make a note|task add karo|task banana|task banao)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (title.isEmpty || title.length < 3) {
      return 'What task should I add? Please say the task name.';
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 'You are not logged in.';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .add({
            'title': title,
            'completed': false,
            'createdAt': FieldValue.serverTimestamp(),
            'source': 'voice',
          });

      return 'Task added: \$title.';
    } catch (e) {
      debugPrint('Add task error: \$e');
      return 'Could not add task. Please try again.';
    }
  }

  // ══════════════════════════════════════════════
  // ── 30. SMS Handler ──
  // ══════════════════════════════════════════════
  Future<String> _handleSms(String cmd) async {
    final lower = cmd.toLowerCase();

    String? contactName;
    final m = RegExp(
      r'(?:sms|text|message)\s+(?:to\s+)?([a-z]+)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (m != null) contactName = m.group(1);

    String? message;
    final msgM = RegExp(
      r'(?:saying|that|message)\s+(.+)',
      caseSensitive: false,
    ).firstMatch(cmd);
    if (msgM != null) message = msgM.group(1);

    if (contactName == null) return 'Who should I send the SMS to?';

    // Contact lookup using inline scoring
    String? phoneNumber;
    String displayName = contactName;
    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      int bestScore = 0;
      Contact? best;
      final query = contactName.toLowerCase();
      for (final c in contacts) {
        if (c.phones.isEmpty) continue;
        final dn = c.displayName.toLowerCase();
        int s = 0;
        if (dn == query) {
          s = 100;
        } else if (dn.split(' ').any((p) => p == query))
          s = 60;
        else if (dn.startsWith(query))
          s = 40;
        else if (dn.contains(query))
          s = 20;
        if (s > bestScore) {
          bestScore = s;
          best = c;
        }
      }
      if (best != null && bestScore > 0) {
        phoneNumber = best.phones.first.number.replaceAll(
          RegExp(r'[\s\-()]'),
          '',
        );
        displayName = best.displayName;
      }
    } catch (_) {}

    if (phoneNumber == null) return 'Contact $contactName not found.';

    if (message != null) {
      await _launch('sms:$phoneNumber?body=\${Uri.encodeComponent(message)}');
      return 'Opening SMS to $displayName with your message.';
    } else {
      await _launch('sms:$phoneNumber');
      return 'Opening SMS to $displayName.';
    }
  }

  Future<String> _handleYouTube(String cmd) async {
    _launchedExternalApp = true;
    var query = cmd
        .replaceAll(
          RegExp(
            r'\b(open|youtube|play|watch|search|find|on|in|for|me|please|and|the|a|pe|kholo|can|you|could|just|now|okay|ok|show|give|tell|video|videos|song|songs)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (query.isNotEmpty && query.length > 2) {
      await _launch(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
      );
      return 'Searching YouTube for $query.';
    }
    await _launch('https://www.youtube.com');
    return 'Opening YouTube.';
  }

  Future<String> _handleCalculator() async {
    _launchedExternalApp = true;
    final packages = [
      'com.vivo.calculator',
      'com.sec.android.app.popupcalculator',
      'com.miui.calculator',
      'com.oppo.calculator',
      'com.google.android.calculator',
      'com.android.calculator2',
      'com.coloros.calculator',
      'com.asus.calculator',
      'com.oneplus.calculator',
    ];
    for (final pkg in packages) {
      try {
        final uri = Uri.parse('android-app://$pkg');
        if (await canLaunchUrl(uri)) {
          await _launch(uri.toString());
          return 'Opening calculator.';
        }
      } catch (_) {}
    }
    await _launch('https://www.google.com/search?q=calculator');
    return 'Opening calculator.';
  }

  Future<String> _handleGoogleSearch(String cmd) async {
    _launchedExternalApp = true;
    var query = cmd
        .replaceAll(
          RegExp(
            r'\b(search for|google search|look up|search on google|find on google|open google|browse|search the web|search|google|please|and|for|me|karo|kar|pe|dhundo)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (query.isNotEmpty && query.length > 1) {
      await _launch(
        'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
      );
      return 'Searching Google for $query.';
    }
    await _launch('https://www.google.com');
    return 'Opening Google.';
  }

  // ════════════════════════════════════════════
  // ── Helpers ──
  // ════════════════════════════════════════════
  bool _hasAny(String cmd, List<String> keywords) =>
      keywords.any((k) => cmd.contains(k));

  String? _extractPhoneNumber(String cmd) {
    final m = RegExp(r'[\+]?[\d][\d\s\-]{6,15}').firstMatch(cmd);
    return m?.group(0)?.replaceAll(RegExp(r'[\s\-]'), '');
  }

  String? _extractDestination(String cmd) {
    final patterns = [
      // "navigate me to X" / "navigate to X" / "take me to X"
      RegExp(
        r'\b(?:navigate\s+(?:me\s+)?to|take\s+me\s+to|directions\s+to|route\s+to|get\s+to|start\s+navigation\s+to|show\s+me\s+the\s+way\s+to)\s+(.+)',
        caseSensitive: false,
      ),
      // "go to X" / "going to X"
      RegExp(
        r'\b(?:go\s+to|going\s+to|jana\s+hai)\s+([a-zA-Z\s]+?)(?:\s+on\s+map|\s+in\s+map|\s*$)',
        caseSensitive: false,
      ),
      // "nearest X" / "find nearest X" / "nearby X"
      RegExp(
        r'\b(?:nearest|find\s+nearest|find\s+nearby|closest|near\s+me)\s+(.+)',
        caseSensitive: false,
      ),
      // "where is X"
      RegExp(
        r'\b(?:where\s+is|location\s+of|find)\s+(.+?)(?:\s+on\s+map|\s*$)',
        caseSensitive: false,
      ),
      // "search X on map" / "show me X on map"
      RegExp(
        r'\b(?:maps\s+for|search\s+on\s+map\s+for|find\s+on\s+map|show\s+me)\s+(.+)',
        caseSensitive: false,
      ),
      // "open google maps X"
      RegExp(
        r'\b(?:open\s+google\s+map(?:s)?)\s+(?:and\s+)?(?:search\s+for|show|find|navigate\s+to)?\s*(.+)',
        caseSensitive: false,
      ),
      // Urdu patterns
      RegExp(
        r'\b([a-zA-Z\s]+?)\s+(?:ka\s+rasta|pe\s+jana|tak\s+jana|le\s+chalo)\b',
        caseSensitive: false,
      ),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(cmd);
      if (m != null) {
        var dest = (m.group(1) ?? '').trim();
        dest = dest
            .replaceAll(
              RegExp(
                r'\b(please|now|open|google|and|search|map|maps|on|in|the|a|me)\b',
                caseSensitive: false,
              ),
              ' ',
            )
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (dest.isNotEmpty && dest.length > 1) {
          debugPrint('ADAM Maps: destination = "$dest"');
          return dest;
        }
      }
    }
    return null;
  }

  String? _extractCity(String cmd) {
    final patterns = [
      RegExp(
        r'(?:weather in|temperature in|forecast in|forecast for|climate in|weather of|weather for)\s+([a-zA-Z\s]+?)(?:\s*$|\s+(?:today|tomorrow|now|currently|please|abhi|kal))',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:in)\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)?)\s+(?:weather|temperature|forecast)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:rain|sunny|cold|hot)\s+(?:in|at)\s+([a-zA-Z\s]+?)(?:\s*$)',
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(cmd);
      if (m != null) {
        final city = m.group(1)?.trim();
        if (city != null && city.isNotEmpty && city.length > 2) return city;
      }
    }
    return null;
  }

  // ── Cached location coords ──
  double? _cachedLat;
  double? _cachedLon;

  // ── WMO weather code → emoji + description ──
  Map<String, String> _wmoDesc(int code) {
    if (code == 0) return {'e': '☀️', 'd': 'Clear sky'};
    if (code <= 2) return {'e': '⛅', 'd': 'Partly cloudy'};
    if (code == 3) return {'e': '☁️', 'd': 'Overcast'};
    if (code <= 49) return {'e': '🌫️', 'd': 'Foggy'};
    if (code <= 55) return {'e': '🌦️', 'd': 'Drizzle'};
    if (code <= 65) return {'e': '🌧️', 'd': 'Rain'};
    if (code <= 77) return {'e': '🌨️', 'd': 'Snow'};
    if (code <= 82) return {'e': '🌧️', 'd': 'Rain showers'};
    if (code <= 86) return {'e': '🌨️', 'd': 'Snow showers'};
    if (code <= 99) return {'e': '⛈️', 'd': 'Thunderstorm'};
    return {'e': '🌡️', 'd': 'Unknown'};
  }

  // ── Get location (lat/lon + city name) ──
  Future<Map<String, dynamic>?> _getLocation(String? cityName) async {
    if (cityName != null && cityName.isNotEmpty) {
      // Geocode city name using Open-Meteo geocoding
      try {
        final res = await http
            .get(
              Uri.parse(
                'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(cityName)}&count=1&language=en&format=json',
              ),
            )
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final results = data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final r = results[0];
            return {
              'lat': (r['latitude'] as num).toDouble(),
              'lon': (r['longitude'] as num).toDouble(),
              'city': r['name'] as String? ?? cityName,
              'country': r['country'] as String? ?? '',
            };
          }
        }
      } catch (_) {}
    }

    // Use cached or IP-based location
    if (_cachedLat != null && _cachedLon != null) {
      return {
        'lat': _cachedLat!,
        'lon': _cachedLon!,
        'city': _cachedCity ?? 'Your location',
        'country': '',
      };
    }
    try {
      final res = await http
          .get(Uri.parse('http://ip-api.com/json/?fields=city,lat,lon,country'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        _cachedCity = d['city'] as String? ?? 'Faisalabad';
        _cachedLat = (d['lat'] as num?)?.toDouble() ?? 31.4187;
        _cachedLon = (d['lon'] as num?)?.toDouble() ?? 73.0791;
        return {
          'lat': _cachedLat!,
          'lon': _cachedLon!,
          'city': _cachedCity!,
          'country': d['country'] as String? ?? '',
        };
      }
    } catch (_) {}
    // Default to Faisalabad
    return {
      'lat': 31.4187,
      'lon': 73.0791,
      'city': 'Faisalabad',
      'country': 'Pakistan',
    };
  }

  // ── Main weather entry point — speaks + shows card ──
  Future<String> _getWeatherWithCard({
    String? city,
    bool forecastMode = false,
  }) async {
    try {
      final loc = await _getLocation(city);
      if (loc == null) return 'Could not determine location.';

      final lat = loc['lat'] as double;
      final lon = loc['lon'] as double;
      final cityName = loc['city'] as String;

      // Open-Meteo API — free, no key, very accurate
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
        'weather_code,wind_speed_10m,precipitation_probability'
        '&daily=temperature_2m_max,temperature_2m_min,weather_code,'
        'precipitation_sum,precipitation_probability_max'
        '&wind_speed_unit=kmh'
        '&timezone=auto'
        '&forecast_days=7',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        return 'Weather service unavailable. Try again.';
      }

      final data = jsonDecode(res.body);
      final current = data['current'] as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;

      final temp = (current['temperature_2m'] as num).round();
      final feelsLike = (current['apparent_temperature'] as num).round();
      final humidity = (current['relative_humidity_2m'] as num).round();
      final windSpeed = (current['wind_speed_10m'] as num).round();
      final rainChance =
          (current['precipitation_probability'] as num?)?.round() ?? 0;
      final wmoCode = (current['weather_code'] as num).round();
      final weather = _wmoDesc(wmoCode);

      // ── Show visual weather card overlay ──
      _showWeatherCard(
        city: cityName,
        temp: temp,
        feelsLike: feelsLike,
        humidity: humidity,
        windSpeed: windSpeed,
        rainChance: rainChance,
        description: weather['d']!,
        emoji: weather['e']!,
        daily: daily,
        forecastMode: forecastMode,
      );

      if (!forecastMode) {
        // Current weather speech
        final rainStr = rainChance > 20
            ? ' Rain chance $rainChance percent.'
            : '';
        final maxT = (daily['temperature_2m_max'] as List)[0];
        final minT = (daily['temperature_2m_min'] as List)[0];
        return '$cityName: ${weather['d']}, $temp degrees. '
            'Feels like $feelsLike. High ${(maxT as num).round()}, low ${(minT as num).round()}. '
            'Humidity $humidity percent, wind $windSpeed km/h.$rainStr';
      } else {
        // Forecast speech — summarize next 3 days
        final dates = daily['time'] as List;
        final maxTemps = daily['temperature_2m_max'] as List;
        final minTemps = daily['temperature_2m_min'] as List;
        final codes = daily['weather_code'] as List;
        final dayNames = [
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
        ];

        final buffer = StringBuffer('7-day forecast for $cityName. ');
        for (int i = 0; i < 3 && i < dates.length; i++) {
          final date = DateTime.parse(dates[i] as String);
          final dayName = i == 0
              ? 'Today'
              : i == 1
              ? 'Tomorrow'
              : dayNames[date.weekday % 7];
          final hi = (maxTemps[i] as num).round();
          final lo = (minTemps[i] as num).round();
          final desc = _wmoDesc((codes[i] as num).round())['d'];
          buffer.write('$dayName: $desc, high $hi low $lo. ');
        }
        return buffer.toString();
      }
    } catch (e) {
      debugPrint('ADAM Weather Error: $e');
      return 'Could not fetch weather. Check your internet connection.';
    }
  }

  // ── Show weather card as bottom overlay ──
  void _showWeatherCard({
    required String city,
    required int temp,
    required int feelsLike,
    required int humidity,
    required int windSpeed,
    required int rainChance,
    required String description,
    required String emoji,
    required Map<String, dynamic> daily,
    required bool forecastMode,
  }) {
    final context = _navKey?.currentContext;
    if (context == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      builder: (_) => WeatherCard(
        city: city,
        temp: temp,
        feelsLike: feelsLike,
        humidity: humidity,
        windSpeed: windSpeed,
        rainChance: rainChance,
        description: description,
        emoji: emoji,
        daily: daily,
        forecastMode: forecastMode,
      ),
    );
  }

  Future<String> _getBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final s = await _battery.batteryState;
      final info = s == BatteryState.charging
          ? ' and charging'
          : s == BatteryState.full
          ? ' and fully charged'
          : '';
      return 'Battery is at $level percent$info.';
    } catch (_) {
      return 'Could not read battery.';
    }
  }

  Future<bool> _launch(String url) async {
    try {
      if (_foregroundServiceActive && _appInBackground) {
        // ── Truly in background → service launches ──
        debugPrint('ADAM: Service launch (bg): $url');
        try {
          final result = await _serviceChannel.invokeMethod('launchUrl', {
            'url': url,
          });
          if (result == true) return true;
        } catch (e) {
          debugPrint('ADAM: Service launch failed: $e');
        }
      }

      // ── App is in foreground (including after bringToFront) ──
      // Direct launch properly brings external app to front
      debugPrint('ADAM: Direct launch (fg): $url');
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint('ADAM Launch Error: \$url → \$e');
    }
    return false;
  }

  // ════════════════════════════════════════════
  // ── Foreground Service ──
  // ════════════════════════════════════════════
  Future<void> _startForegroundService() async {
    try {
      await _serviceChannel.invokeMethod('startService');
      _foregroundServiceActive = true;
      debugPrint(
        'ADAM: Foreground service started — background listening enabled',
      );
    } catch (e) {
      debugPrint('ADAM: Foreground service start failed: $e');
      _foregroundServiceActive = false;
    }
  }

  Future<void> _stopForegroundService() async {
    try {
      await _serviceChannel.invokeMethod('stopService');
      _foregroundServiceActive = false;
      debugPrint('ADAM: Foreground service stopped');
    } catch (e) {
      debugPrint('ADAM: Foreground service stop failed: $e');
    }
  }

  // ════════════════════════════════════════════
  // ── Overlay ──
  // ════════════════════════════════════════════
  void _showOverlay() {
    _hideOverlay();
    _tryShowOverlay(0);
  }

  void _tryShowOverlay(int attempt) {
    if (attempt > 8) return;
    final overlay = _navKey?.currentState?.overlay;
    if (overlay == null) {
      Future.delayed(
        Duration(milliseconds: 150 + attempt * 100),
        () => _tryShowOverlay(attempt + 1),
      );
      return;
    }
    try {
      _overlay = OverlayEntry(
        builder: (_) => ADAMOverlayWidget(
          stateNotifier: state,
          commandNotifier: lastCommand,
          responseNotifier: lastResponse,
          isInSessionNotifier: isInSession,
          onDismiss: () {
            _tts.stop();
            _stt.stop();
            _sessionActive = false;
            isInSession.value = false;
            _deactivate();
          },
        ),
      );
      overlay.insert(_overlay!);
      debugPrint('ADAM: Overlay shown');
    } catch (e) {
      debugPrint('ADAM Overlay Error: $e');
      Future.delayed(
        Duration(milliseconds: 200 + attempt * 100),
        () => _tryShowOverlay(attempt + 1),
      );
    }
  }

  void _hideOverlay() {
    try {
      _overlay?.remove();
    } catch (_) {}
    _overlay = null;
  }

  Future<void> _showNotification() async {
    try {
      await flutterLocalNotificationsPlugin.show(
        888,
        'ADAM is active',
        'Say "Hey ADAM" — tap to return',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'adam_wake_word_ch',
            'ADAM Wake Word',
            channelDescription: 'ADAM voice assistant',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            showWhen: false,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('ADAM Notification Error: $e');
    }
  }

  void _cancelNotification() => flutterLocalNotificationsPlugin.cancel(888);
  void dispose() => disable();
}

// ══════════════════════════════════════════════
// ── ADAM OVERLAY WIDGET ──
// ══════════════════════════════════════════════
class ADAMOverlayWidget extends StatefulWidget {
  final ValueNotifier<WakeState> stateNotifier;
  final ValueNotifier<String> commandNotifier;
  final ValueNotifier<String> responseNotifier;
  final ValueNotifier<bool> isInSessionNotifier;
  final VoidCallback onDismiss;

  const ADAMOverlayWidget({
    super.key,
    required this.stateNotifier,
    required this.commandNotifier,
    required this.responseNotifier,
    required this.isInSessionNotifier,
    required this.onDismiss,
  });

  @override
  State<ADAMOverlayWidget> createState() => _ADAMOverlayWidgetState();
}

class _ADAMOverlayWidgetState extends State<ADAMOverlayWidget>
    with TickerProviderStateMixin {
  static const Color _cyan = Color(0xFF4FD8EB);
  static const Color _bg = Color(0xFF050A0F);

  late AnimationController _pulseCtrl, _waveCtrl, _slideCtrl;
  late Animation<double> _pulseAnim, _waveAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _pulseAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _waveAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Color _stateColor(WakeState s) {
    switch (s) {
      case WakeState.activated:
        return _cyan;
      case WakeState.listening:
        return Colors.greenAccent;
      case WakeState.processing:
        return Colors.orangeAccent;
      case WakeState.responding:
        return Colors.blueAccent;
      default:
        return _cyan;
    }
  }

  String _stateLabel(WakeState s) {
    switch (s) {
      case WakeState.activated:
        return 'ACTIVATED';
      case WakeState.listening:
        return 'LISTENING';
      case WakeState.processing:
        return 'PROCESSING';
      case WakeState.responding:
        return 'TRANSMITTING';
      default:
        return 'ACTIVE';
    }
  }

  String _stateHint(WakeState s, bool inSession) {
    switch (s) {
      case WakeState.activated:
        return 'Speak your command...';
      case WakeState.listening:
        return inSession
            ? 'Ask anything — say Dismiss to close'
            : 'Speak your command...';
      case WakeState.processing:
        return 'ADAM is thinking...';
      case WakeState.responding:
        return 'ADAM is speaking...';
      default:
        return '';
    }
  }

  IconData _stateIcon(WakeState s) {
    switch (s) {
      case WakeState.listening:
        return Icons.mic_rounded;
      case WakeState.processing:
        return Icons.hourglass_top_rounded;
      case WakeState.responding:
        return Icons.graphic_eq_rounded;
      default:
        return Icons.record_voice_over_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slideAnim,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ValueListenableBuilder<WakeState>(
            valueListenable: widget.stateNotifier,
            builder: (_, wakeState, __) {
              final color = _stateColor(wakeState);
              return ValueListenableBuilder<bool>(
                valueListenable: widget.isInSessionNotifier,
                builder: (_, inSession, __) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: color.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top bar
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(22),
                              topRight: Radius.circular(22),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: color.withOpacity(0.15),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (_, __) => Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: color.withOpacity(
                                            _pulseAnim.value * 0.4,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color.withOpacity(0.15),
                                        border: Border.all(
                                          color: color.withOpacity(
                                            _pulseAnim.value,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        _stateIcon(wakeState),
                                        color: color,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'ADAM',
                                          style: GoogleFonts.rajdhani(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AnimatedBuilder(
                                          animation: _pulseAnim,
                                          builder: (_, __) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: color.withOpacity(
                                                  _pulseAnim.value * 0.6,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: color.withOpacity(
                                                      _pulseAnim.value,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _stateLabel(wakeState),
                                                  style: GoogleFonts.rajdhani(
                                                    color: color,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (inSession) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.greenAccent
                                                    .withOpacity(0.4),
                                              ),
                                            ),
                                            child: Text(
                                              'SESSION',
                                              style: GoogleFonts.rajdhani(
                                                color: Colors.greenAccent,
                                                fontSize: 7,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      _stateHint(wakeState, inSession),
                                      style: GoogleFonts.rajdhani(
                                        color: Colors.white38,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: widget.onDismiss,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white38,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Body
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: _waveAnim,
                                builder: (_, __) => SizedBox(
                                  height: 40,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: _WaveformPainter(
                                      progress: _waveAnim.value,
                                      color: color,
                                      active:
                                          wakeState == WakeState.listening ||
                                          wakeState == WakeState.responding,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Command bubble
                              ValueListenableBuilder<String>(
                                valueListenable: widget.commandNotifier,
                                builder: (_, cmd, __) => cmd.isNotEmpty
                                    ? Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.04),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white12,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'YOU  ',
                                              style: GoogleFonts.rajdhani(
                                                color: Colors.greenAccent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                cmd,
                                                style: GoogleFonts.rajdhani(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              // Response bubble
                              ValueListenableBuilder<String>(
                                valueListenable: widget.responseNotifier,
                                builder: (_, resp, __) => resp.isNotEmpty
                                    ? Column(
                                        children: [
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF4FD8EB,
                                              ).withOpacity(0.06),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF4FD8EB,
                                                ).withOpacity(0.2),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'ADAM  ',
                                                  style: GoogleFonts.rajdhani(
                                                    color: const Color(
                                                      0xFF4FD8EB,
                                                    ),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    resp,
                                                    style: GoogleFonts.rajdhani(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              const SizedBox(height: 8),

                              // Hints
                              if (!inSession)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.center,
                                  children:
                                      [
                                            'Hey ADAM',
                                            'Hello ADAM',
                                            'OK ADAM',
                                            'ADAM Listen',
                                          ]
                                          .map(
                                            (p) => _hintChip(
                                              p,
                                              Colors.white12,
                                              Colors.white24,
                                            ),
                                          )
                                          .toList(),
                                )
                              else
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.center,
                                  children:
                                      [
                                            'Show my tasks',
                                            'Send Baba a message',
                                            'WhatsApp call Awais',
                                            'Video call Baba',
                                            'Weather in Karachi',
                                            'My battery',
                                            'Navigate to hospital',
                                            'Open settings',
                                          ]
                                          .map(
                                            (p) => _hintChip(
                                              p,
                                              Colors.greenAccent.withOpacity(
                                                0.15,
                                              ),
                                              Colors.greenAccent.withOpacity(
                                                0.4,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),

                              const SizedBox(height: 6),
                              Text(
                                inSession
                                    ? 'Session active — say "Dismiss" to close'
                                    : 'Say "Dismiss" or tap X to close',
                                style: GoogleFonts.rajdhani(
                                  color: Colors.white24,
                                  fontSize: 9,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _hintChip(String label, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.rajdhani(
          color: textColor,
          fontSize: 8,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ── WEATHER CARD WIDGET ──
// ══════════════════════════════════════════════
class WeatherCard extends StatelessWidget {
  final String city, description, emoji;
  final int temp, feelsLike, humidity, windSpeed, rainChance;
  final Map<String, dynamic> daily;
  final bool forecastMode;

  const WeatherCard({
    super.key,
    required this.city,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.rainChance,
    required this.description,
    required this.emoji,
    required this.daily,
    required this.forecastMode,
  });

  Color _bgColor() {
    if (description.toLowerCase().contains('clear') ||
        description.toLowerCase().contains('sunny')) {
      return const Color(0xFF1565C0);
    }
    if (description.toLowerCase().contains('cloud')) {
      return const Color(0xFF455A64);
    }
    if (description.toLowerCase().contains('rain') ||
        description.toLowerCase().contains('drizzle')) {
      return const Color(0xFF1A237E);
    }
    if (description.toLowerCase().contains('snow')) {
      return const Color(0xFF37474F);
    }
    if (description.toLowerCase().contains('thunder')) {
      return const Color(0xFF212121);
    }
    if (description.toLowerCase().contains('fog')) {
      return const Color(0xFF546E7A);
    }
    return const Color(0xFF0D47A1);
  }

  String _dayName(String dateStr, int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _wmoEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 2) return '⛅';
    if (code == 3) return '☁️';
    if (code <= 49) return '🌫️';
    if (code <= 55) return '🌦️';
    if (code <= 65) return '🌧️';
    if (code <= 77) return '🌨️';
    if (code <= 82) return '🌧️';
    if (code <= 86) return '🌨️';
    if (code <= 99) return '⛈️';
    return '🌡️';
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColor();
    final dates = daily['time'] as List;
    final maxTemps = daily['temperature_2m_max'] as List;
    final minTemps = daily['temperature_2m_min'] as List;
    final codes = daily['weather_code'] as List;
    final rainProb =
        daily['precipitation_probability_max'] as List? ?? List.filled(7, 0);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── City & date ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city,
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _formatDate(DateTime.now()),
                            style: GoogleFonts.rajdhani(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white60,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Main temp + emoji ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 64)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$temp°',
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.w300,
                              height: 1,
                            ),
                          ),
                          Text(
                            description,
                            style: GoogleFonts.rajdhani(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Stats row ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('💧', '$humidity%', 'Humidity'),
                        _divider(),
                        _stat('💨', '$windSpeed km/h', 'Wind'),
                        _divider(),
                        _stat('🌡️', 'Feels $feelsLike°', 'Feels like'),
                        _divider(),
                        _stat('🌂', '$rainChance%', 'Rain'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 7-day forecast ──
                  Text(
                    '7-DAY FORECAST',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: List.generate(
                        dates.length > 7 ? 7 : dates.length,
                        (i) {
                          final hi = (maxTemps[i] as num).round();
                          final lo = (minTemps[i] as num).round();
                          final code = (codes[i] as num).round();
                          final rain = (rainProb[i] as num?)?.round() ?? 0;
                          final isLast =
                              i == (dates.length > 7 ? 6 : dates.length - 1);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(color: Colors.white12),
                                    ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    _dayName(dates[i] as String, i),
                                    style: GoogleFonts.rajdhani(
                                      color: i == 0
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 14,
                                      fontWeight: i == 0
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Text(
                                  _wmoEmoji(code),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const Spacer(),
                                if (rain > 20) ...[
                                  Text(
                                    '💧$rain%',
                                    style: GoogleFonts.rajdhani(
                                      color: Colors.lightBlueAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  '$lo°',
                                  style: GoogleFonts.rajdhani(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _tempBar(
                                  lo,
                                  hi,
                                  (minTemps[0] as num).round(),
                                  (maxTemps[0] as num).round(),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '$hi°',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.rajdhani(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Powered by Open-Meteo · Tap to dismiss',
                      style: GoogleFonts.rajdhani(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _divider() => Container(width: 0.5, height: 40, color: Colors.white24);

  Widget _tempBar(int lo, int hi, int dayLo, int dayHi) {
    final range = (dayHi - dayLo).toDouble().clamp(1.0, 40.0);
    final start = ((lo - dayLo) / range).clamp(0.0, 1.0);
    final end = ((hi - dayLo) / range).clamp(0.0, 1.0);
    return SizedBox(
      width: 60,
      height: 4,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: end - start,
            alignment: Alignment.centerLeft,
            child: FractionalTranslation(
              translation: Offset(start / (end - start).clamp(0.01, 1.0), 0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFFFF7043)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

// ══════════════════════════════════════════════
// ── SIM PICKER ──
// ══════════════════════════════════════════════
class _SimPickerSheet extends StatelessWidget {
  final String contactName;
  const _SimPickerSheet({required this.contactName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF050A0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF4FD8EB).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FD8EB).withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF4FD8EB).withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF4FD8EB).withOpacity(0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4FD8EB).withOpacity(0.15),
                    border: Border.all(
                      color: const Color(0xFF4FD8EB).withOpacity(0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.call_rounded,
                    color: Color(0xFF4FD8EB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT SIM',
                        style: GoogleFonts.rajdhani(
                          color: const Color(0xFF4FD8EB),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Calling $contactName',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white38,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // SIM buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SimButton(
                    sim: 1,
                    label: 'SIM 1',
                    color: const Color(0xFF4FD8EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SimButton(
                    sim: 2,
                    label: 'SIM 2',
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Tap to dial with that SIM',
              style: GoogleFonts.rajdhani(
                color: Colors.white24,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimButton extends StatelessWidget {
  final int sim;
  final String label;
  final Color color;
  const _SimButton({
    required this.sim,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, sim),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.sim_card_rounded, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Tap to call',
              style: GoogleFonts.rajdhani(
                color: color.withOpacity(0.5),
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ── WAVEFORM PAINTER ──
// ══════════════════════════════════════════════
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool active;
  const _WaveformPainter({
    required this.progress,
    required this.color,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 28;
    final barWidth = size.width / (barCount * 2.2);
    final centerY = size.height / 2;
    final rng = Random(42);
    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth * 2.2) + barWidth / 2;
      double h;
      if (active) {
        final wave = sin((i / barCount * 2 * pi) + progress * 2 * pi);
        h = size.height * (0.15 + (wave + 1) / 2 * 0.7);
      } else {
        h = size.height * (0.08 + rng.nextDouble() * 0.15);
      }
      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        Paint()
          ..color = color.withOpacity(active ? 0.7 : 0.2)
          ..strokeWidth = barWidth * 0.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.active != active || old.color != color;
}
