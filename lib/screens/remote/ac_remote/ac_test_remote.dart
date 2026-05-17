import 'package:ai_voice_chat/screens/remote/ac_remote/ac_control.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AcTestRemoteScreen extends StatefulWidget {
  final String brandName;
  const AcTestRemoteScreen({super.key, required this.brandName});
  @override
  State<AcTestRemoteScreen> createState() => _AcTestRemoteScreenState();
}

class _AcTestRemoteScreenState extends State<AcTestRemoteScreen>
    with SingleTickerProviderStateMixin {
  static const _cyan = Color(0xFF4FD8EB);

  bool _isSending = false;
  bool _success = false;
  bool _failed = false;
  int _attempts = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendSignal() async {
    setState(() {
      _isSending = true;
      _success = false;
      _failed = false;
    });
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1800));
    setState(() {
      _isSending = false;
      _attempts++;
    });
    HapticFeedback.lightImpact();
    Get.snackbar(
      'Signal Sent',
      'IR signal sent to ${widget.brandName} AC',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _cyan.withOpacity(0.85),
      colorText: Colors.black,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      borderRadius: 12,
    );
  }

  void _confirmWorked() {
    setState(() => _success = true);
    HapticFeedback.heavyImpact();
    Get.snackbar(
      '✅ Success!',
      '${widget.brandName} AC paired successfully',
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
      'Point phone directly at AC and try again',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withOpacity(0.85),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted)
        setState(() {
          _failed = false;
        });
    });
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
                            'Test Remote · ${widget.brandName}',
                            style: GoogleFonts.jetBrainsMono(
                              color: _cyan,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Attempt counter
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
                          'Attempt $_attempts',
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Brand badge ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _cyan.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _cyan.withOpacity(0.2)),
                      ),
                      child: Text(
                        widget.brandName,
                        style: GoogleFonts.jetBrainsMono(
                          color: _cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Power button ──
                    GestureDetector(
                      onTap: _isSending || _success ? null : _sendSignal,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _isSending ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _success
                                        ? Colors.green.withOpacity(0.3)
                                        : _failed
                                        ? Colors.red.withOpacity(0.3)
                                        : _isSending
                                        ? _cyan.withOpacity(0.25)
                                        : _cyan.withOpacity(0.1),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            // Button circle
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _success
                                    ? Colors.green.withOpacity(0.15)
                                    : _failed
                                    ? Colors.red.withOpacity(0.1)
                                    : _cyan.withOpacity(0.1),
                                border: Border.all(
                                  color: _success
                                      ? Colors.green.withOpacity(0.5)
                                      : _failed
                                      ? Colors.red.withOpacity(0.4)
                                      : _cyan.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: _isSending
                                  ? const CircularProgressIndicator(
                                      color: _cyan,
                                      strokeWidth: 3,
                                    )
                                  : Icon(
                                      _success
                                          ? Icons.check_rounded
                                          : _failed
                                          ? Icons.close_rounded
                                          : Icons.power_settings_new_rounded,
                                      size: 70,
                                      color: _success
                                          ? Colors.greenAccent
                                          : _failed
                                          ? Colors.redAccent
                                          : _cyan,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    Text(
                      _success ? 'AC Paired Successfully!' : 'Did it work?',
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
                            : 'Point your phone at the AC. Tap the power button\nand wait for AC to Turn ON/OFF.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    if (!_success) ...[
                      // ── Send signal button ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: GestureDetector(
                          onTap: _isSending ? null : _sendSignal,
                          child: Container(
                            width: double.infinity,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: _isSending
                                  ? LinearGradient(
                                      colors: [
                                        Colors.grey.shade800,
                                        Colors.grey.shade700,
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF4FD8EB),
                                        Color(0xFF00C9FF),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _isSending
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: _cyan.withOpacity(0.3),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: _isSending
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Sending signal...',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Send IR Signal',
                                    style: GoogleFonts.inter(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Yes / No row ──
                      if (_attempts > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _confirmWorked,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_rounded,
                                          color: Colors.greenAccent,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Yes, it worked',
                                          style: GoogleFonts.inter(
                                            color: Colors.greenAccent,
                                            fontSize: 12,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.close_rounded,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'No, try again',
                                          style: GoogleFonts.inter(
                                            color: Colors.redAccent,
                                            fontSize: 12,
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
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
