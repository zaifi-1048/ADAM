import 'package:ai_voice_chat/controller/welcome_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeScreen extends GetView<WelcomeController> {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<WelcomeController>(() => WelcomeController());
    const Color accentCyan = Color(0xFF28D7F5);
    const Color secondaryText = Color(0xFF8B949E);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // ── Background matching dashboard ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0E1A), Color(0xFF000000)],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  const Text(
                    "Welcome",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: const [
                      Text(
                        "Personal",
                        style: TextStyle(
                          color: accentCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "•",
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "AI Chat",
                        style: TextStyle(
                          color: accentCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Center(
                    child: Image.asset(
                      'assets/images/122.png',
                      height: 260,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    "ADAM",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Verify your identity to unlock ADAM's\nintelligent control.",
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        controller.onLoginPressed();
                        Get.toNamed('/login');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: accentCyan, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Log in",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Image.asset(
                            'assets/icons/po.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: TextButton(
                      onPressed: controller.onHelpPressed,
                      child: const Text(
                        "Need help?",
                        style: TextStyle(color: secondaryText, fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
