import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controller/dashboard_controller.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F141C),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // ── Home ──
          _navItem(
            label: "Home",
            icon: Icons.home_rounded,
            isSelected: Get.currentRoute == '/dashboard',
            onTap: () {
              if (Get.isRegistered<DashboardController>()) {
                Get.find<DashboardController>().selectedIndex.value = 0;
              }
              if (Get.currentRoute != '/dashboard') {
                Get.offAllNamed('/dashboard');
              }
            },
          ),

          // ── Chat ──
          _navItem(
            label: "Chat",
            icon: Icons.forum_rounded,
            isSelected: Get.currentRoute == '/chat',
            onTap: () {
              if (Get.currentRoute != '/chat') {
                Get.toNamed('/chat');
              }
            },
          ),

          // ── Memory ──
          _navItem(
            label: "Memory",
            icon: Icons.psychology_rounded,
            isSelected: Get.currentRoute == '/memory',
            onTap: () {
              if (Get.currentRoute != '/memory') {
                Get.toNamed('/memory');
              }
            },
          ),

          // ── Settings ──
          _navItem(
            label: "Settings",
            icon: Icons.settings_rounded,
            isSelected: Get.currentRoute == '/settings',
            onTap: () {
              if (Get.currentRoute != '/settings') {
                Get.toNamed('/settings');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const Color activeColor = Color(0xFF4FD8EB);
    const Color inactiveColor = Color(0xFF5A616B);

    return InkWell(
      onTap: onTap,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
