import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:ai_voice_chat/services/stt_manager.dart';
import 'package:ai_voice_chat/services/wake_word_service.dart';

class VoiceController extends GetxController {
  static VoiceController get to => Get.find();

  final FlutterTts tts = FlutterTts();

  @override
  void onInit() {
    super.onInit();
    applyVoiceSettings();
  }

  Future<void> applyVoiceSettings({String language = 'en-US'}) async {
    await tts.setLanguage(language);
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
  }

  Future<bool> acquireSTT() async {
    final granted = await SttManager.instance.requestAccess(SttPriority.voiceChat);
    if (granted) WakeWordService.instance.pauseForScreen();
    return granted;
  }

  Future<void> releaseSTT() async {
    await SttManager.instance.releaseAccess(SttPriority.voiceChat);
    WakeWordService.instance.resumeAfterScreen();
  }
}
