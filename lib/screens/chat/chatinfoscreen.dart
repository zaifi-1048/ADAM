import 'package:ai_voice_chat/screens/chat/payment/subscription.dart';
import 'package:ai_voice_chat/screens/chat/translation_screen.dart';
import 'package:ai_voice_chat/screens/chat/payment/chatmoreinfo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_voice_chat/screens/chat/chatbox.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';

// ─── Palette ───────────────────────────────────────────
const _cyan = Color(0xFF4FD8EB);
const _purple = Color(0xFFB06EFF);
const _green = Color(0xFF22C55E);
const _pink = Color(0xFFFF6B9D);
const _surface = Color(0xFF161B22);
const _bg = Color(0xFF0D1117);

class ChatInfoScreen extends StatelessWidget {
  const ChatInfoScreen({super.key});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _name {
    final u = FirebaseAuth.instance.currentUser;
    if (u?.displayName?.isNotEmpty == true)
      return u!.displayName!.split(' ')[0];
    return u?.email?.split('@')[0] ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),

                // ── Header ──
                _buildHeader(),
                const SizedBox(height: 24),

                // ── ADAM Chat Hero ──
                _buildHeroCard(),
                const SizedBox(height: 24),

                // ── Quick Actions ──
                _buildSectionLabel('Quick Actions', 'Choose what to do'),
                const SizedBox(height: 12),
                _buildQuickActions(),
                const SizedBox(height: 24),

                // ── Suggested Prompts ──
                _buildSectionLabel('Try asking ADAM', 'Tap a prompt to start'),
                const SizedBox(height: 12),
                _buildSuggestions(),
                const SizedBox(height: 24),

                // ── Capabilities ──
                _buildSectionLabel('What ADAM can do', 'AI-powered features'),
                const SizedBox(height: 12),
                _buildCapabilities(),
                const SizedBox(height: 28),

                // ── Buy Premium ──
                _buildPremiumBanner(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_greeting, $_name',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
            ),
            Text(
              'ADAM Chat',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cyan.withOpacity(0.3)),
            color: _cyan.withOpacity(0.07),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Ready',
                style: GoogleFonts.jetBrainsMono(color: _cyan, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero Card ──
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF1A0A2E), Color(0xFF000000)],
        ),
        border: Border.all(color: _cyan.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: _cyan.withOpacity(0.05),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Robot
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _cyan.withOpacity(0.12), width: 1),
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _cyan.withOpacity(0.22),
                    width: 1.5,
                  ),
                  color: _cyan.withOpacity(0.04),
                ),
              ),
              SizedBox(
                width: 55,
                height: 55,
                child: Image.asset(
                  'assets/images/robot.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.smart_toy_outlined,
                    size: 40,
                    color: _cyan.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start a Conversation',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by GPT-4o Mini via OpenAI',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 14),
                // Feature pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    _FeaturePill(label: 'Web Search', color: _green),
                    _FeaturePill(label: 'Voice', color: Color(0xFF22C55E)),
                    _FeaturePill(label: 'Multi-turn', color: _cyan),
                    _FeaturePill(label: 'Memory', color: _purple),
                  ],
                ),
                const SizedBox(height: 14),
                // New Chat button
                GestureDetector(
                  onTap: () => Get.to(() => const ChatBox()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_cyan, Color(0xFF2DD4BF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.black,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'New Chat',
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ──
  Widget _buildQuickActions() {
    final actions = [
      _ActionData(
        icon: Icons.chat_bubble_rounded,
        title: 'AI Chat',
        subtitle: 'Text conversation with ADAM',
        color: _cyan,
        gradient: const [Color(0xFF0F4C75), Color(0xFF0A1A28)],
        onTap: () => Get.to(() => const ChatBox()),
      ),
      _ActionData(
        icon: Icons.mic_rounded,
        title: 'Voice Chat',
        subtitle: 'Talk to ADAM hands-free',
        color: _green,
        gradient: const [Color(0xFF0A2A0A), Color(0xFF050F05)],
        onTap: () => Get.toNamed('/voice'),
      ),
      _ActionData(
        icon: Icons.translate_rounded,
        title: 'AI Translation',
        subtitle: 'Translate any language instantly',
        color: const Color(0xFFFFC947),
        gradient: const [Color(0xFF2A1A00), Color(0xFF150D00)],
        onTap: () => Get.to(() => const TranslationScreen()),
      ),
      _ActionData(
        icon: Icons.auto_awesome_rounded,
        title: 'Image Generation',
        subtitle: 'Create images with AI (Premium)',
        color: _pink,
        gradient: const [Color(0xFF2A0A1A), Color(0xFF150510)],
        onTap: () => Get.to(() => const ChatMoreInfoScreen()),
      ),
    ];

    return Column(
      children: actions
          .map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: a.onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: a.gradient,
                    ),
                    border: Border.all(color: a.color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: a.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: a.color.withOpacity(0.2)),
                        ),
                        child: Icon(a.icon, color: a.color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a.subtitle,
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: a.color.withOpacity(0.5),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Suggested Prompts ──
  Widget _buildSuggestions() {
    final prompts = [
      'Explain machine learning to me',
      'Write a professional email',
      'What is the weather like in Lahore?',
      'Help me plan my day',
      'Translate "Hello" to Urdu',
      'Summarize the news today',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: prompts
          .map(
            (p) => GestureDetector(
              onTap: () => Get.to(() => ChatBox(), arguments: {'prompt': p}),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: _cyan.withOpacity(0.6),
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p,
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Capabilities ──
  Widget _buildCapabilities() {
    final caps = [
      _CapData(
        icon: Icons.psychology_rounded,
        color: _cyan,
        title: 'Contextual Memory',
        desc: 'Remembers your conversation history across sessions',
      ),
      _CapData(
        icon: Icons.travel_explore_rounded,
        color: _green,
        title: 'Web Search',
        desc: 'Searches the web in real-time for up-to-date answers',
      ),
      _CapData(
        icon: Icons.language_rounded,
        color: _purple,
        title: 'Multi Language',
        desc: 'Chat and respond naturally in your preferred language',
      ),
      _CapData(
        icon: Icons.document_scanner_rounded,
        color: _pink,
        title: 'Document Analysis',
        desc: 'Upload PDFs and images for intelligent summarization',
      ),
    ];

    return Column(
      children: caps
          .map(
            (c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.color.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(c.icon, color: c.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.desc,
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Premium Banner ──
  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => Get.to(() => const SubscriptionScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F4C75), Color(0xFF1A0A2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: _cyan.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: _cyan.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_cyan, Color(0xFF2DD4BF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.black,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Unlock unlimited messages, image generation & more',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _cyan.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          sub,
          style: GoogleFonts.inter(color: Colors.white30, fontSize: 10),
        ),
      ],
    );
  }
}

// ─── Data classes ───────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final String label;
  final Color color;
  const _FeaturePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradient,
    required this.onTap,
  });
}

class _CapData {
  final IconData icon;
  final Color color;
  final String title, desc;
  const _CapData({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}


