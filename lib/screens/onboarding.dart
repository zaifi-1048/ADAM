import 'package:ai_voice_chat/controller/onboarding_controller.dart';
import 'package:ai_voice_chat/screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<OnboardingController>(() => OnboardingController());
    final controller = Get.find<OnboardingController>();

    const accentColor = Color(0xFF4FD8EB);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF000000)],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: accentColor,
                      size: 20,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: controller.pageController,
                  itemCount: controller.pages.length,
                  onPageChanged: (index) =>
                      controller.currentPage.value = index,
                  itemBuilder: (context, index) {
                    final page = controller.pages[index];
                    return _buildPageContent(
                      title: page['title']!,
                      subtitle: page['subtitle']!,
                      imagePath: page['image']!,
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(
                      () => Opacity(
                        opacity: controller.currentPage.value == 0 ? 0 : 1,
                        child: TextButton(
                          onPressed: () {
                            if (controller.currentPage.value > 0) {
                              controller.pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: const Text(
                            "BACK",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Obx(
                      () => Row(
                        children: List.generate(
                          controller.pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controller.currentPage.value == i
                                  ? accentColor
                                  : Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        if (controller.currentPage.value ==
                            controller.pages.length - 1) {
                          Get.offAll(() => const WelcomeScreen());
                        } else {
                          controller.pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Obx(
                        () => Text(
                          controller.currentPage.value ==
                                  controller.pages.length - 1
                              ? "DONE"
                              : "NEXT",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent({
    required String title,
    required String subtitle,
    required String imagePath,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 30),
          child: Text(
            subtitle,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Color(0xFF909499),
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
