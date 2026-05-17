import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

const _cyan = Color(0xFF4FD8EB);
const _green = Color(0xFF22C55E);
const _amber = Color(0xFFFFC947);
const _purple = Color(0xFFB06EFF);
const _surface = Color(0xFF161B22);

class ChatPaymentScreen extends StatelessWidget {
  const ChatPaymentScreen({super.key});

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
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Payment',
                          style: GoogleFonts.rajdhani(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '256-bit SSL encrypted',
                          style: GoogleFonts.jetBrainsMono(
                            color: _green,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.science_rounded,
                            color: _amber,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'BETA',
                            style: GoogleFonts.inter(
                              color: _amber,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ── Lock illustration ──
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cyan.withOpacity(0.08),
                          border: Border.all(color: _cyan.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: _cyan.withOpacity(0.15),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: _cyan,
                          size: 44,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Payment Coming Soon',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'re setting up secure payment processing.\nYou\'ll be notified when it\'s ready.',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 13,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // ── Beta notice ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _amber.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _amber.withOpacity(0.25)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.science_rounded,
                                    color: _amber,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Beta Access Active',
                                        style: GoogleFonts.inter(
                                          color: _amber,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'All premium features unlocked for free',
                                        style: GoogleFonts.inter(
                                          color: _amber.withOpacity(0.7),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 14),
                            ...[
                                  {
                                    'icon': Icons.auto_awesome_rounded,
                                    'color': _amber,
                                    'label': 'Image Generation — Unlocked',
                                  },
                                  {
                                    'icon': Icons.chat_bubble_rounded,
                                    'color': _cyan,
                                    'label': 'Unlimited AI Chat — Unlocked',
                                  },
                                  {
                                    'icon': Icons.travel_explore_rounded,
                                    'color': _green,
                                    'label': 'Web Search — Unlocked',
                                  },
                                  {
                                    'icon': Icons.psychology_rounded,
                                    'color': _purple,
                                    'label': 'Emotion AI — Unlocked',
                                  },
                                ]
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item['icon'] as IconData,
                                          color: item['color'] as Color,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          item['label'] as String,
                                          style: GoogleFonts.inter(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: _green,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Payment methods coming ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Methods — Coming Soon',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _payMethodBadge('VISA'),
                                _payMethodBadge('Mastercard'),
                                _payMethodBadge('PayPal'),
                                _payMethodBadge('Stripe'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── Bottom button ──
              Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.snackbar(
                          '🎉 You\'re all set!',
                          'Enjoying full beta access — no payment needed yet.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: _green.withOpacity(0.9),
                          colorText: Colors.black,
                          duration: const Duration(seconds: 3),
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          borderRadius: 14,
                        );
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (context.mounted) Navigator.pop(context);
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_cyan, Color(0xFF00C9FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
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
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.rocket_launch_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Continue with Beta Access',
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Free during beta · Payment required when launched',
                      style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _payMethodBadge(String name) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white12),
    ),
    child: Text(
      name,
      style: GoogleFonts.jetBrainsMono(
        color: Colors.white24,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
