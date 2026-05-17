import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

const _cyan = Color(0xFF4FD8EB);
const _purple = Color(0xFFB06EFF);
const _green = Color(0xFF22C55E);
const _amber = Color(0xFFFFC947);
const _surface = Color(0xFF161B22);
const _bg = Color(0xFF0A0E1A);

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _monthlySelected = true;

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.auto_awesome_rounded,
      'color': _amber,
      'title': 'Unlimited AI Generations',
      'sub': 'Generate as many images as you want',
    },
    {
      'icon': Icons.chat_bubble_rounded,
      'color': _cyan,
      'title': 'Unlimited AI Chat',
      'sub': 'No message limits, ever',
    },
    {
      'icon': Icons.travel_explore_rounded,
      'color': _green,
      'title': 'Web Search Integration',
      'sub': 'Real-time web answers in every chat',
    },
    {
      'icon': Icons.psychology_rounded,
      'color': _purple,
      'title': 'Advanced Emotion AI',
      'sub': 'Deep emotional intelligence analysis',
    },
    {
      'icon': Icons.block_flipped,
      'color': Colors.redAccent,
      'title': 'Ad-Free Experience',
      'sub': 'Zero interruptions, pure focus',
    },
    {
      'icon': Icons.cloud_upload_rounded,
      'color': Color(0xFF38BDF8),
      'title': 'Cloud Storage',
      'sub': 'All sessions backed up securely',
    },
  ];

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
        child: Stack(
          children: [
            // Glow orbs
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _cyan.withOpacity(0.1),
                      blurRadius: 120,
                      spreadRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.08),
                      blurRadius: 100,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header
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
                        const Spacer(),
                        // Beta badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.science_rounded,
                                color: _amber,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'BETA',
                                style: GoogleFonts.jetBrainsMono(
                                  color: _amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
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
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero badge
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _cyan.withOpacity(0.2),
                                    _purple.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _cyan.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.workspace_premium_rounded,
                                    color: _amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ADAM PREMIUM',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: _cyan,
                                      fontSize: 11,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Unlock Full',
                                  style: GoogleFonts.rajdhani(
                                    color: Colors.white54,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Potential',
                                  style: GoogleFonts.rajdhani(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    height: 0.9,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Everything ADAM can do, without limits',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          _buildPricingToggle(),
                          const SizedBox(height: 22),
                          _buildSelectedPlanCard(),
                          const SizedBox(height: 24),

                          Text(
                            'Everything Included',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'All features, no restrictions',
                            style: GoogleFonts.inter(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._features.map((f) => _buildFeatureTile(f)),
                          const SizedBox(height: 24),
                          _buildTrustRow(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  _buildCTA(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _monthlySelected = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _monthlySelected
                      ? _cyan.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  border: _monthlySelected
                      ? Border.all(color: _cyan.withOpacity(0.4))
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Monthly',
                          style: GoogleFonts.inter(
                            color: _monthlySelected ? _cyan : Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '3 days free',
                            style: GoogleFonts.inter(
                              color: _green,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$9.99/mo',
                      style: GoogleFonts.rajdhani(
                        color: _monthlySelected ? Colors.white : Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _monthlySelected = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_monthlySelected
                      ? _purple.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  border: !_monthlySelected
                      ? Border.all(color: _purple.withOpacity(0.4))
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Yearly',
                          style: GoogleFonts.inter(
                            color: !_monthlySelected ? _purple : Colors.white54,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Save 64%',
                            style: GoogleFonts.inter(
                              color: _amber,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$79.99/yr',
                      style: GoogleFonts.rajdhani(
                        color: !_monthlySelected
                            ? Colors.white
                            : Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlanCard() {
    final isMonthly = _monthlySelected;
    final color = isMonthly ? _cyan : _purple;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isMonthly
                  ? Icons.calendar_today_rounded
                  : Icons.calendar_month_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMonthly ? 'Monthly Plan' : 'Yearly Plan',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isMonthly
                      ? '3 days free trial, then \$9.99/month'
                      : '\$79.99/year — save \$120 vs monthly',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isMonthly ? '\$9.99' : '\$79.99',
                style: GoogleFonts.rajdhani(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              Text(
                isMonthly ? '/mo' : '/yr',
                style: GoogleFonts.inter(
                  color: color.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(Map<String, dynamic> f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (f['color'] as Color).withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (f['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              f['icon'] as IconData,
              color: f['color'] as Color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f['title'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  f['sub'] as String,
                  style: GoogleFonts.inter(color: Colors.white30, fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: _green.withOpacity(0.7),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustRow() {
    final items = [
      {'icon': Icons.lock_rounded, 'label': 'Secure'},
      {'icon': Icons.cancel_rounded, 'label': 'Cancel anytime'},
      {'icon': Icons.support_agent_rounded, 'label': '24/7 Support'},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items
          .map(
            (i) => Column(
              children: [
                Icon(i['icon'] as IconData, color: Colors.white24, size: 18),
                const SizedBox(height: 4),
                Text(
                  i['label'] as String,
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 9),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildCTA(BuildContext context) {
    final color = _monthlySelected ? _cyan : _purple;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          // Beta notice banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _amber.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: _amber, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payment integration coming soon. Premium features are free during beta.',
                    style: GoogleFonts.inter(
                      color: _amber.withOpacity(0.85),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // CTA button — activates free beta access
          GestureDetector(
            onTap: () {
              Get.snackbar(
                '🎉 Beta Access Activated!',
                'You now have full Premium access — free during beta.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: _green.withOpacity(0.9),
                colorText: Colors.black,
                duration: const Duration(seconds: 3),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                borderRadius: 14,
              );
              Future.delayed(const Duration(milliseconds: 800), () {
                if (context.mounted) Navigator.pop(context);
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _monthlySelected
                      ? [_cyan, const Color(0xFF00C9FF)]
                      : [_purple, const Color(0xFF7C3AED)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
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
                    Icons.workspace_premium_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Activate Free Beta Access',
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
            'No payment required during beta · Full access included',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
