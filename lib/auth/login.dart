import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_voice_chat/controller/login_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    const cyan = Color(0xFF4FD8EB);
    const surface = Color(0xFF161B22);
    const fieldColor = Color(0xFF0D1117);
    const secondary = Color(0xFF8B949E);

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
                          'Sign in to continue',
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
                      height: 110,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cyan.withOpacity(0.08),
                          border: Border.all(color: cyan.withOpacity(0.25)),
                        ),
                        child: const Icon(
                          Icons.smart_toy_outlined,
                          color: cyan,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Title ──
                Center(
                  child: Text(
                    'Welcome Back',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Sign in to access your smart space',
                    style: GoogleFonts.inter(color: secondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Email ──
                Text(
                  'Email Address',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: fieldColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'example@gmail.com',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Colors.white24,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Password ──
                Text(
                  'Password',
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: TextField(
                      controller: controller.passwordController,
                      obscureText: controller.obscurePassword.value,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.white24,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white24,
                          size: 18,
                        ),
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
                  ),
                ),

                const SizedBox(height: 10),

                // ── Forgot Password ──
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: controller.goToForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.inter(
                        color: cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // ── Sign In Button ──
                Obx(
                  () => GestureDetector(
                    onTap: controller.isLoading.value
                        ? null
                        : controller.onSignIn,
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
                              'Sign In',
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

                // ── Google Sign In ──
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

                // ── Sign Up ──
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account?  ",
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: GoogleFonts.inter(
                            color: cyan,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = controller.goToSignup,
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
}
