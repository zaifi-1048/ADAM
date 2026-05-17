import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  bool _isLoading = false;
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'Invalid Email',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.85),
        colorText: Colors.white,
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _step = 1;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found with this email.';
          break;
        case 'invalid-email':
          msg = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Try again later.';
          break;
        default:
          msg = e.message ?? 'Something went wrong.';
      }
      Get.snackbar(
        'Error',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.85),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF4FD8EB);

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
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_step > 0)
                          setState(() => _step--);
                        else
                          Navigator.pop(context);
                      },
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
                          'Reset Password',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Account recovery',
                          style: GoogleFonts.jetBrainsMono(
                            color: cyan,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  child: _step == 0 ? _buildStep0(cyan) : _buildStep1(cyan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep0(Color cyan) {
    return Column(
      children: [
        const SizedBox(height: 30),

        // Icon
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cyan.withOpacity(0.08),
              border: Border.all(color: cyan.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: cyan.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(Icons.lock_reset_rounded, color: cyan, size: 42),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'Forgot Password?',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter your email and we\'ll send\na reset link to your inbox',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 13,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 36),

        // Email field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Email Address',
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'example@gmail.com',
              hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
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

        const SizedBox(height: 28),

        // Button
        GestureDetector(
          onTap: _isLoading ? null : _sendReset,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? LinearGradient(
                      colors: [Colors.grey.shade700, Colors.grey.shade600],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF4FD8EB), Color(0xFF00C9FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: cyan.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Send Reset Link',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(Color cyan) {
    const green = Color(0xFF22C55E);
    return Column(
      children: [
        const SizedBox(height: 40),

        // Success icon
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: green.withOpacity(0.08),
              border: Border.all(color: green.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: green.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: green,
              size: 42,
            ),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'Email Sent!',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Check your inbox for the reset link.\nAlso check your spam folder.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),

        // Email badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: green.withOpacity(0.25)),
          ),
          child: Text(
            _emailCtrl.text,
            style: GoogleFonts.jetBrainsMono(color: green, fontSize: 11),
          ),
        ),

        const SizedBox(height: 40),

        // Back to login
        GestureDetector(
          onTap: () => Get.offAllNamed('/login'),
          child: Container(
            width: double.infinity,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4FD8EB), Color(0xFF00C9FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cyan.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Back to Login',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Resend
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: Text(
            'Resend Email',
            style: GoogleFonts.inter(
              color: cyan,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
