import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_voice_chat/models/user_model.dart';
import 'package:ai_voice_chat/routes/app_routes.dart';
import 'package:ai_voice_chat/services/auth_service.dart';
import 'package:ai_voice_chat/services/firestore_service.dart';

class SignupController extends GetxController {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  // ─── Email / Password signup ──────────────────────────────────────────────

  void onRegister() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: credential.user!.uid,
        fullName: fullName,
        email: email,
        provider: 'email',
        createdAt: DateTime.now(),
      );

      await _firestoreService.createUser(user);
      Get.offAllNamed(AppRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Sign Up Failed',
        _authService.getReadableError(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Sign Up Failed',
        'Error: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  void onGoogleSignIn() async {
    isLoading.value = true;
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null) return;

      final firebaseUser = credential.user!;
      final user = UserModel(
        uid: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? 'ADAM User',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        provider: 'google',
        createdAt: DateTime.now(),
      );
      await _firestoreService.upsertUser(user);

      Get.offAllNamed(AppRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Google Sign-In Failed',
        _authService.getReadableError(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Google sign-in failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void goToLogin(BuildContext context) => Navigator.pop(context);

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

