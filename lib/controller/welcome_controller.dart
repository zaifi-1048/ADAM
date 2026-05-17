import 'package:get/get.dart';

class WelcomeController extends GetxController {
  void onLoginPressed() {
    Get.toNamed('/dashboard');
  }

  void onHelpPressed() {
    Get.snackbar(
      "Need Help?",
      "Please contact support to continue",
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
