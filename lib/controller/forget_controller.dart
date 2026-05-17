import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_voice_chat/services/auth_service.dart';

class ForgotPasswordController extends GetxController {
  final TextEditingController emailController = TextEditingController();

  final RxBool isLoading = false.obs;

  final _authService = AuthService();

  void sendResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar('Error', 'Please enter your email.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar('Error', 'Please enter a valid email.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      await _authService.sendPasswordResetEmail(email);
      Get.snackbar(
        'Email Sent',
        'A password reset link has been sent to $email.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      Get.back();
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        _authService.getReadableError(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
