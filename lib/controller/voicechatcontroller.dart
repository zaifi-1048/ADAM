import 'package:get/get.dart';

class VoiceChatController extends GetxController {
  var isListening = false.obs;
  var statusText = "Press the mic to start".obs;
  var selectedIndex = 0.obs;

  void toggleListening() {
    isListening.value = !isListening.value;
    statusText.value = isListening.value
        ? "Listening..."
        : "I'm here, how can I help?";
  }
}
