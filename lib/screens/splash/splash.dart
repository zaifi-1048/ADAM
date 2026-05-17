import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_voice_chat/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Scale: 0.7 → 1.0 with elastic bounce
    _scale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));

    // Fade in: 0 → 1
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Subtle pulse after fully visible
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    _ctrl.forward();

    Timer(const Duration(seconds: 5), () {
      if (mounted) Get.offNamed(AppRoutes.onboarding);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Same gradient as dashboard
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF000000)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value * _pulse.value,
                child: child,
              ),
            ),
            child: Image.asset(
              'assets/images/adam_splash.png',
              width: 397,
              height: 397,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
