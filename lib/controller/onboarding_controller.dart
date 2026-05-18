import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  var currentPage = 0.obs;

  final List<Map<String, String>> pages = [
    {
      'title': 'Manage Your Tasks Effortlessly',
      'subtitle':
          'Stay organized throughout your day with smart, seamless task control. Plan, track, and manage everything with clarity so nothing ever feels overwhelming.',
      'image': 'assets/images/qw.png',
    },
    {
      'title': 'Fast Replies, Smooth Chat',
      'subtitle':
          'Experience quick, natural conversations designed to help you get things done with ease. Ask, explore, and interact freely, everything responds instantly and intelligently.',
      'image': 'assets/images/qwe.png',
    },
    {
      'title': 'Smart Control for Every Device',
      'subtitle':
          'Handle your home appliances from one simple interface. Turn things on/off, adjust settings instantly anytime, anywhere.',
      'image': 'assets/images/qwr.png',
    },
    {
      'title': 'Real-Time Avatar Interaction',
      'subtitle':
          'Interact with a lifelike avatar that makes every conversation feel real. Enjoy smooth animations and expressive reactions as you chat.',
      'image': 'assets/images/on4.png',
    },
  ];

  bool get isLastPage => currentPage.value == pages.length - 1;

  void nextPage() {
    if (isLastPage) {
      Get.offAllNamed('/welcome');
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
