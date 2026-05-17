import 'package:ai_voice_chat/screens/remote/ac_remote/ac_control.dart';
import 'package:ai_voice_chat/screens/remote/ac_remote/ac_test_remote.dart';
import 'package:ai_voice_chat/screens/remote/tv_remote/tvusagescreen.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AcRemoteButton extends StatefulWidget {
  final String brandName;
  const AcRemoteButton({super.key, required this.brandName});
  @override
  State<AcRemoteButton> createState() => _AcRemoteButtonState();
}

class _AcRemoteButtonState extends State<AcRemoteButton>
    with SingleTickerProviderStateMixin {
  static const _cyan = Color(0xFF4FD8EB);

  late String _selectedBrand;
  bool _isSending = false;
  bool _success = false;
  bool _failed = false;
  int _attempts = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final List<String> _brands = [
    'Samsung',
    'Panasonic',
    'Mitsubishi',
    'LG',
    'Haier',
    'Gree',
  ];

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.brandName.isNotEmpty ? widget.brandName : 'Samsung';
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendSignal() async {
    if (_isSending || _success) return;
    setState(() {
      _isSending = true;
      _success = false;
      _failed = false;
    });
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _attempts++;
    });
    HapticFeedback.lightImpact();
    Get.snackbar(
      'Signal Sent',
      'IR signal sent to $_selectedBrand AC',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _cyan.withOpacity(0.85),
      colorText: Colors.black,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      borderRadius: 12,
    );
  }

  void _confirmSuccess() {
    setState(() => _success = true);
    HapticFeedback.heavyImpact();
    Get.snackbar(
      '✅ Paired!',
      '$_selectedBrand AC connected successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.85),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AcControlScreen()),
        );
    });
  }

  void _confirmFailed() {
    setState(() => _failed = true);
    HapticFeedback.vibrate();
    Get.snackbar(
      'Try Again',
      'Point phone directly at $_selectedBrand AC',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withOpacity(0.85),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _failed = false);
    });
  }

  void _openTestRemote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AcTestRemoteScreen(brandName: _selectedBrand),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const CustomNavBar(),
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AC Remote',
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Test Remote · Progress Timeline',
                            style: GoogleFonts.jetBrainsMono(
                              color: _cyan,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_attempts > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          '$_attempts attempt${_attempts > 1 ? 's' : ''}',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EnergyOverviewScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: _cyan,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Brand tabs ──
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _brands.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final b = _brands[i];
                    final sel = b == _selectedBrand;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedBrand = b;
                        _success = false;
                        _attempts = 0;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel
                              ? _cyan.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? _cyan.withOpacity(0.5)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          b,
                          style: GoogleFonts.inter(
                            color: sel ? _cyan : Colors.white60,
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(),

              // ── Power button ──
              GestureDetector(
                onTap: _sendSignal,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _isSending ? _pulseAnim.value : 1.0,
                    child: child,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _success
                                  ? Colors.green.withOpacity(0.35)
                                  : _failed
                                  ? Colors.red.withOpacity(0.3)
                                  : _cyan.withOpacity(_isSending ? 0.4 : 0.2),
                              blurRadius: 60,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                      ),
                      // Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _success
                              ? Colors.green.withOpacity(0.2)
                              : _failed
                              ? Colors.red.withOpacity(0.15)
                              : const Color(0xFF2C9AA6),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _isSending
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              )
                            : Icon(
                                _success
                                    ? Icons.check_circle_rounded
                                    : _failed
                                    ? Icons.close_rounded
                                    : Icons.power_settings_new_rounded,
                                size: 75,
                                color: _success
                                    ? Colors.greenAccent
                                    : _failed
                                    ? Colors.redAccent
                                    : const Color(0xFFBFEFF2),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Text ──
              Text(
                _success ? 'AC Paired!' : 'Did it work?',
                style: GoogleFonts.rajdhani(
                  color: _success ? Colors.greenAccent : Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _success
                      ? 'Proceeding to AC controls...'
                      : 'Point your phone at the $_selectedBrand AC.\nTap the power button and wait for AC to Turn ON/OFF.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Yes/No buttons (after first attempt) ──
              if (_attempts > 0 && !_success)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _confirmSuccess,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  color: Colors.greenAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Yes!',
                                  style: GoogleFonts.inter(
                                    color: Colors.greenAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _confirmFailed,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.close_rounded,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Try again',
                                  style: GoogleFonts.inter(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Advanced test button ──
              if (!_success) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _openTestRemote,
                  child: Text(
                    'Advanced Test →',
                    style: GoogleFonts.inter(
                      color: _cyan.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
