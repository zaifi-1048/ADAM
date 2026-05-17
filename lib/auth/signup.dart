import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ai_voice_chat/controller/signup_controller.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignupController());
    const cyan = Color(0xFF4FD8EB);
    const secondary = Color(0xFF8B949E);
    const fieldColor = Color(0xFF0D1117);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
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
                          color: cyan,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Create your account',
                          style: GoogleFonts.jetBrainsMono(
                            color: cyan,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ── Logo ──
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cyan.withOpacity(0.12),
                          blurRadius: 50,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/log.png',
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cyan.withOpacity(0.08),
                          border: Border.all(color: cyan.withOpacity(0.25)),
                        ),
                        child: const Icon(
                          Icons.smart_toy_outlined,
                          color: cyan,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Center(
                  child: Text(
                    'Create Your Account',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Your journey with ADAM begins here',
                    style: GoogleFonts.inter(color: secondary, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Full Name ──
                _fieldLabel('Full Name'),
                const SizedBox(height: 8),
                _field(
                  hint: 'Emily John',
                  ctrl: controller.fullNameController,
                  icon: Icons.person_outline_rounded,
                  fieldColor: fieldColor,
                ),

                const SizedBox(height: 16),

                // ── Email ──
                _fieldLabel('Email Address'),
                const SizedBox(height: 8),
                _field(
                  hint: 'example@gmail.com',
                  ctrl: controller.emailController,
                  icon: Icons.email_outlined,
                  fieldColor: fieldColor,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // ── Password with toggle ──
                _fieldLabel('Password'),
                const SizedBox(height: 8),
                Obx(
                  () => _field(
                    hint: '••••••••',
                    ctrl: controller.passwordController,
                    icon: Icons.lock_outline_rounded,
                    fieldColor: fieldColor,
                    isPassword: controller.obscurePassword.value,
                    suffixIcon: GestureDetector(
                      onTap: () => controller.obscurePassword.value =
                          !controller.obscurePassword.value,
                      child: Icon(
                        controller.obscurePassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white38,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // ── Register Button ──
                Obx(
                  () => GestureDetector(
                    onTap: controller.isLoading.value
                        ? null
                        : controller.onRegister,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: controller.isLoading.value
                            ? LinearGradient(
                                colors: [
                                  Colors.grey.shade700,
                                  Colors.grey.shade600,
                                ],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF4FD8EB), Color(0xFF00C9FF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: controller.isLoading.value
                            ? []
                            : [
                                BoxShadow(
                                  color: cyan.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Register',
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Divider ──
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Or continue with',
                        style: GoogleFonts.inter(
                          color: Colors.white24,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white12)),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Google Button ──
                Obx(
                  () => GestureDetector(
                    onTap: controller.isLoading.value
                        ? null
                        : controller.onGoogleSignIn,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/google.png',
                            height: 20,
                            errorBuilder: (_, __, ___) => const Text(
                              'G',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Sign In ──
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account?  ',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: GoogleFonts.inter(
                            color: cyan,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Get.back(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
      color: Colors.white60,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _field({
    required String hint,
    required TextEditingController ctrl,
    required IconData icon,
    required Color fieldColor,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Icon(icon, color: Colors.white24, size: 18),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
