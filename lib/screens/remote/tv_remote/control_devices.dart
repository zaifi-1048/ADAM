import 'package:ai_voice_chat/controller/dashboard_controller.dart';
import 'package:ai_voice_chat/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ControlDevicesScreen extends StatelessWidget {
  const ControlDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [Color(0xFF1C2229), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        controller.selectedIndex.value = 0;
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              Text(
                "Control\nYour Devices",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),

              const Spacer(flex: 2),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Image.asset(
                  'assets/images/remoted.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.tablet_android,
                      size: 80,
                      color: Colors.cyan,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 45),
                child: Text(
                  "Bring convenience to your fingertips by managing all your appliances. "
                  "Stay organized, save time, and make your home truly smart and responsive.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.6,
                  ),
                ),
              ),

              const Spacer(flex: 1),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.toNamed(AppRoutes.selectremote);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA7F3F7),
                      foregroundColor: const Color(0xFF0F141C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Start Now",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
