import 'package:get/get.dart';

class DashboardController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  static const int totalTabs = 6;

  void changeIndex(int index) {
    if (index < 0 || index >= totalTabs) return;

    if (selectedIndex.value != index) {
      selectedIndex.value = index;
    }
  }

  void goHome() {
    selectedIndex.value = 0;
  }

  bool handleBack() {
    if (selectedIndex.value != 0) {
      selectedIndex.value = 0;
      return false;
    }
    return true;
  }
}
