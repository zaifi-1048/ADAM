import 'package:ai_voice_chat/controller/voicechatcontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VoiceChat extends StatelessWidget {
  const VoiceChat({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VoiceChatController());

    const Color bgColor = Color(0xFF0B0D0F);
    const Color accentCyan = Color(0xFF4FD8EB);
    const Color textGrey = Color(0xFF909499);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: accentCyan, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Voice Assistant",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          Obx(
            () => Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (controller.isListening.value)
                    _buildPulseCircle(accentCyan.withOpacity(0.1), 220),
                  if (controller.isListening.value)
                    _buildPulseCircle(accentCyan.withOpacity(0.2), 180),

                  Container(
                    height: 140,
                    width: 140,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentCyan.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Image.asset('assets/robot_avatar.png'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 50),

          Obx(
            () => Text(
              controller.statusText.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Speak clearly into your microphone",
            style: TextStyle(color: textGrey, fontSize: 14),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSmallActionBtn(Icons.keyboard, "Text"),

                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 85,
                    width: 85,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentCyan.withOpacity(0.0),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_none,
                      color: accentCyan,
                      size: 40,
                    ),
                  ),
                ),

                _buildSmallActionBtn(Icons.volume_up, "Audio"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSmallActionBtn(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white70, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF909499), fontSize: 12),
        ),
      ],
    );
  }
}
