import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SttPriority { wakeWord, voiceChat, translation }

class SttManager {
  static final SttManager _i = SttManager._();
  static SttManager get instance => _i;
  SttManager._();

  final SpeechToText _stt = SpeechToText();

  // ── Internal status stream controller ──
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  Stream<String> get statusStream => _statusController.stream;

  bool _initialized = false;
  bool _ready = false;
  SttPriority? _currentOwner;
  VoidCallback? _onWakeWordRelease;

  Future<bool> initialize() async {
    if (_initialized) return _ready;
    try {
      _ready = await _stt.initialize(
        onError: (e) {
          debugPrint('SttManager Error: ${e.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('SttManager Status: $status');
          // Broadcast status to all listeners
          _statusController.add(status);
        },
      );
      _initialized = true;
      debugPrint('SttManager: Ready = $_ready');
    } catch (e) {
      debugPrint('SttManager Init Error: $e');
    }
    return _ready;
  }

  bool get isReady => _ready;
  bool get isAvailable => _stt.isAvailable;
  bool get isListening => _stt.isListening;
  SttPriority? get currentOwner => _currentOwner;

  void setWakeWordReleaseCallback(VoidCallback cb) {
    _onWakeWordRelease = cb;
  }

  Future<bool> requestAccess(SttPriority priority) async {
    if (!_ready) return false;

    if (_currentOwner == SttPriority.wakeWord &&
        priority != SttPriority.wakeWord) {
      debugPrint('SttManager: $priority taking over from wakeWord');
      await _stt.stop();
      _currentOwner = null;
      _onWakeWordRelease?.call();
    }

    if (_currentOwner != null && _currentOwner != priority) {
      debugPrint('SttManager: Denied — $_currentOwner is active');
      return false;
    }

    _currentOwner = priority;
    debugPrint('SttManager: Granted to $priority');
    return true;
  }

  Future<void> releaseAccess(SttPriority priority) async {
    if (_currentOwner != priority) return;
    debugPrint('SttManager: $priority releasing access');
    await _stt.stop();
    _currentOwner = null;
  }

  Future<void> listen({
    required SttPriority priority,
    required Function(String words, bool isFinal) onResult,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 5),
    bool partialResults = true,
    String localeId = 'en_US',
    bool cancelOnError = false,
  }) async {
    if (_currentOwner != priority) {
      debugPrint('SttManager: $priority not owner — cannot listen');
      return;
    }
    if (_stt.isListening) {
      await _stt.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    await _stt.listen(
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
      listenFor: listenFor,
      pauseFor: pauseFor,
      localeId: localeId,
      cancelOnError: cancelOnError,
      partialResults: partialResults,
    );
  }

  Future<void> stop(SttPriority priority) async {
    if (_currentOwner != priority) return;
    await _stt.stop();
  }

  Future<void> forceStop() async {
    await _stt.stop();
    _currentOwner = null;
  }

  void dispose() {
    _statusController.close();
  }
}
