import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:ai_voice_chat/services/stt_manager.dart';
import 'package:ai_voice_chat/services/wake_word_service.dart';

class VoiceController extends GetxController {
  static VoiceController get to => Get.find();

  final FlutterTts tts = FlutterTts();
  final RxBool isMaleVoice = true.obs;

  @override
  void onInit() {
    super.onInit();
    applyVoiceSettings();
  }

  Future<void> setMale() async {
    isMaleVoice.value = true;
    await applyVoiceSettings();
  }

  Future<void> setFemale() async {
    isMaleVoice.value = false;
    await applyVoiceSettings();
  }

  Future<void> applyVoiceSettings({String language = 'en-US'}) async {
    await tts.setLanguage(language);
    await tts.setSpeechRate(0.45);
    await tts.setVolume(1.0);
    await tts.setPitch(isMaleVoice.value ? 0.75 : 1.2);
  }

  // ── Called by VoiceChatScreen when it starts ──
  Future<bool> acquireSTT() async {
    final granted = await SttManager.instance.requestAccess(
      SttPriority.voiceChat,
    );
    if (granted) {
      // Pause wake word
      WakeWordService.instance.pauseForScreen();
    }
    return granted;
  }

  // ── Called by VoiceChatScreen when it closes ──
  Future<void> releaseSTT() async {
    await SttManager.instance.releaseAccess(SttPriority.voiceChat);
    // Resume wake word
    WakeWordService.instance.resumeAfterScreen();
  }

  String get voiceLabel => isMaleVoice.value ? 'Male' : 'Female';
}
