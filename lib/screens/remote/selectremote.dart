import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class SelectRemoteScreen extends StatefulWidget {
  const SelectRemoteScreen({super.key});
  @override
  State<SelectRemoteScreen> createState() => _SelectRemoteScreenState();
}

class _SelectRemoteScreenState extends State<SelectRemoteScreen>
    with TickerProviderStateMixin {
  static const _cyan = Color(0xFF4FD8EB);
  static const _purple = Color(0xFFB06EFF);
  static const _green = Color(0xFF22C55E);
  static const _amber = Color(0xFFFFC947);

  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late Animation<double> _pulse;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _rotate = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _rotateCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // ── Header ──
                const SizedBox(height: 20),
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
                          color: _cyan,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Remote',
                          style: GoogleFonts.rajdhani(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Control your devices',
                          style: GoogleFonts.jetBrainsMono(
                            color: _cyan,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // ── Animated hub illustration ──
                AnimatedBuilder(
                  animation: Listenable.merge([_pulseCtrl, _rotateCtrl]),
                  builder: (_, __) => SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer rotating ring
                        Transform.rotate(
                          angle: _rotate.value * 2 * 3.14159,
                          child: CustomPaint(
                            size: const Size(240, 240),
                            painter: _DashedCirclePainter(
                              color: _cyan.withOpacity(0.15),
                              dashCount: 24,
                            ),
                          ),
                        ),
                        // Mid ring
                        Transform.rotate(
                          angle: -_rotate.value * 2 * 3.14159 * 0.7,
                          child: CustomPaint(
                            size: const Size(190, 190),
                            painter: _DashedCirclePainter(
                              color: _purple.withOpacity(0.12),
                              dashCount: 16,
                            ),
                          ),
                        ),
                        // Glow
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _cyan.withOpacity(0.1),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        // Center icon — pulsing
                        Transform.scale(
                          scale: _pulse.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF161B22),
                              border: Border.all(
                                color: _cyan.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.settings_remote_rounded,
                              color: _cyan,
                              size: 54,
                            ),
                          ),
                        ),
                        // Orbiting device dots
                        ..._orbitDots(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Title ──
                Text(
                  'Control Your Devices',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Bring convenience to your fingertips.\nManage all your appliances seamlessly.',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // ── Feature pills ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pill(Icons.bluetooth_rounded, 'Bluetooth', _cyan),
                    const SizedBox(width: 10),
                    _pill(Icons.wifi_rounded, 'Wi-Fi', _green),
                    const SizedBox(width: 10),
                    _pill(Icons.sensors_rounded, 'IR Sensor', _amber),
                  ],
                ),

                const SizedBox(height: 20),

                // ── TV Remote Button ──
                GestureDetector(
                  onTap: () => Get.toNamed('/scantv'),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4FD8EB), Color(0xFF00C9FF)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _cyan.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.tv_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'TV Remote',
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── AC Remote Button ──
                GestureDetector(
                  onTap: () => Get.toNamed('/acremote'),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_purple, const Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.ac_unit_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'AC Remote',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Orbiting dots around hub ──
  List<Widget> _orbitDots() {
    final items = [
      {'icon': Icons.tv_rounded, 'color': _cyan, 'angle': 0.0},
      {'icon': Icons.ac_unit_rounded, 'color': _purple, 'angle': 2.09},
      {'icon': Icons.lightbulb_rounded, 'color': _amber, 'angle': 4.18},
    ];
    return items.map((item) {
      final angle = (item['angle'] as double) + _rotate.value * 2 * 3.14159;
      const r = 115.0;
      final x = r * (0.5 + 0.5 * (angle / 6.28).remainder(1.0));
      final dx = r * _cos(angle);
      final dy = r * _sin(angle);
      final color = item['color'] as Color;
      return Positioned(
        left: 130 + dx - 18,
        top: 130 + dy - 18,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(item['icon'] as IconData, color: color, size: 18),
        ),
      );
    }).toList();
  }

  double _cos(double a) => a == 0 ? 1 : (a == 2.09 ? -0.5 : -0.5);
  double _sin(double a) => a == 0 ? 0 : (a == 2.09 ? 0.866 : -0.866);

  Widget _pill(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ── Dashed circle painter ──
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  const _DashedCirclePainter({required this.color, required this.dashCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final step = 2 * 3.14159 / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final a1 = i * step;
      final a2 = a1 + step * 0.45;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        a1,
        a2 - a1,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}


