import 'dart:math';
import 'package:ai_voice_chat/screens/chat/ai_reader_screen.dart';
import 'package:ai_voice_chat/screens/chat/chatbox.dart';
import 'package:ai_voice_chat/screens/remote/selectremote.dart';
import 'package:ai_voice_chat/screens/memory/memory.dart';
import 'package:ai_voice_chat/screens/tasks/task_manager_screen.dart';
import 'package:ai_voice_chat/screens/voice/ai_voice_chat_screen.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/dashboard_controller.dart';

// ─────────────────────────────────────────────
//  Colour palette
// ─────────────────────────────────────────────
const _cyan = Color(0xFF4FD8EB);
const _purple = Color(0xFFB06EFF);
const _green = Color(0xFF22C55E);
const _pink = Color(0xFFFF6B9D);
const _amber = Color(0xFFFFC947);
const _card = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DashboardController>())
      Get.put(DashboardController());
    final ctrl = Get.find<DashboardController>();
    return Scaffold(
      backgroundColor: _card,
      body: Obx(() {
        switch (ctrl.selectedIndex.value) {
          case 1:
            return const VoiceChatScreen();
          case 2:
            return const MemoryScreen();
          case 3:
            return const SelectRemoteScreen();
          default:
            return _HomeTab(ctrl: ctrl);
        }
      }),
      bottomNavigationBar: const CustomNavBar(),
    );
  }
}

// ─────────────────────────────────────────────
//  Home Tab
// ─────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final DashboardController ctrl;
  const _HomeTab({required this.ctrl});

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
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E1A), Color(0xFF000000)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),

              // ── Header ──
              _Header(greeting: _greeting, name: _name),
              const SizedBox(height: 20),

              // ── ADAM Status Hero Card ──
              _ADAMHeroCard(ctrl: ctrl),
              const SizedBox(height: 20),

              // ── Live Stats ──
              if (user != null) _LiveStats(user: user),
              const SizedBox(height: 22),

              // ── Quick Tools ──
              _SectionTitle(title: 'Quick Tools', sub: 'Tap to launch'),
              const SizedBox(height: 12),
              _QuickToolsGrid(ctrl: ctrl),
              const SizedBox(height: 22),

              // ── Emotion Intelligence ──
              if (user != null) _EmotionCard(user: user),
              const SizedBox(height: 22),

              // Recent Sessions removed — available via Memory tab in bottom nav

              // ── Usage Analytics ──
              if (user != null) _UsageAnalytics(user: user),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String greeting, name;
  const _Header({required this.greeting, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            ),
            Text(
              name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _green.withOpacity(0.4)),
            color: _green.withOpacity(0.08),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ADAM Active',
                style: GoogleFonts.jetBrainsMono(color: _green, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  ADAM Hero Card — replaces the robot image + cognitive engine
// ─────────────────────────────────────────────
class _ADAMHeroCard extends StatelessWidget {
  final DashboardController ctrl;
  const _ADAMHeroCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(color: _cyan.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _cyan.withOpacity(0.06),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left — robot + pulse
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _cyan.withOpacity(0.15), width: 1),
                ),
              ),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _cyan.withOpacity(0.25),
                    width: 1.5,
                  ),
                  color: _cyan.withOpacity(0.05),
                ),
              ),
              SizedBox(
                width: 70,
                height: 70,
                child: Image.asset(
                  'assets/images/robot.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.smart_toy_outlined,
                    size: 50,
                    color: _cyan.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Right — info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADAM AI',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adaptive Digital AI Model',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 14),
                // Capability pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    _Pill(label: 'NLP', color: _cyan),
                    _Pill(label: 'Vision', color: _purple),
                    _Pill(label: 'Emotion AI', color: _pink),
                    _Pill(label: 'Automation', color: _green),
                  ],
                ),
                const SizedBox(height: 14),
                // System status row
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: const [
                    _StatusDot(label: 'NLP Engine', active: true, color: _cyan),
                    _StatusDot(label: 'Emotion AI', active: true, color: _pink),
                    _StatusDot(
                      label: 'Automation',
                      active: true,
                      color: _green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  const _StatusDot({
    required this.label,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: active ? color : Colors.white24,
            shape: BoxShape.circle,
            boxShadow: active
                ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)]
                : [],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: active ? color.withOpacity(0.8) : Colors.white24,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
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

// ─────────────────────────────────────────────
//  Live Stats
// ─────────────────────────────────────────────
class _LiveStats extends StatelessWidget {
  final User user;
  const _LiveStats({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .where('completed', isEqualTo: false)
          .snapshots(),
      builder: (_, taskSnap) {
        final pending = taskSnap.data?.docs.length ?? 0;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('sessions')
              .snapshots(),
          builder: (_, sessSnap) {
            final sessions = sessSnap.data?.docs.length ?? 0;
            final today =
                sessSnap.data?.docs.where((d) {
                  final ts = (d.data() as Map)['updatedAt'] as Timestamp?;
                  if (ts == null) return false;
                  final dt = ts.toDate();
                  final now = DateTime.now();
                  return dt.day == now.day &&
                      dt.month == now.month &&
                      dt.year == now.year;
                }).length ??
                0;

            return Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: '$pending',
                    label: 'Pending Tasks',
                    icon: Icons.checklist_rounded,
                    color: _amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    value: '$sessions',
                    label: 'Total Sessions',
                    icon: Icons.history_rounded,
                    color: _cyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    value: '$today',
                    label: 'Today Active',
                    icon: Icons.today_rounded,
                    color: _purple,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Quick Tools Grid  (no duplicate voice chat)
// ─────────────────────────────────────────────
class _QuickToolsGrid extends StatelessWidget {
  final DashboardController ctrl;
  const _QuickToolsGrid({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _ToolData(
        'AI Chat',
        Icons.chat_bubble_rounded,
        const [Color(0xFF0F4C75), Color(0xFF1B262C)],
        _cyan,
        'Intelligent conversation',
        () => Get.to(() => const ChatBox()),
      ),
      _ToolData(
        'AI Reader',
        Icons.document_scanner_rounded,
        const [Color(0xFF2A0A3E), Color(0xFF0D0118)],
        _purple,
        'Analyze documents',
        () => Get.to(() => const AiReaderScreen()),
      ),
      _ToolData(
        'Task Manager',
        Icons.task_alt_rounded,
        const [Color(0xFF0A2A0A), Color(0xFF051005)],
        _green,
        'Manage your tasks',
        () => Get.to(() => const TaskManagerScreen()),
      ),


      _ToolData(
        'Remote',
        Icons.settings_remote_rounded,
        const [Color(0xFF0A1A2A), Color(0xFF050D15)],
        const Color(0xFF2DD4BF),
        'Control appliances',
        () => ctrl.selectedIndex.value = 3,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: tools.length,
      itemBuilder: (_, i) => _ToolCard(data: tools[i]),
    );
  }
}

class _ToolData {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final Color accent;
  final String subtitle;
  final VoidCallback onTap;
  const _ToolData(
    this.label,
    this.icon,
    this.gradient,
    this.accent,
    this.subtitle,
    this.onTap,
  );
}

class _ToolCard extends StatelessWidget {
  final _ToolData data;
  const _ToolCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: data.gradient,
          ),
          border: Border.all(color: data.accent.withOpacity(0.22)),
          boxShadow: [
            BoxShadow(color: data.accent.withOpacity(0.05), blurRadius: 12),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon + arrow row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: data.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: data.accent.withOpacity(0.2)),
                  ),
                  child: Icon(data.icon, color: data.accent, size: 20),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: data.accent.withOpacity(0.5),
                  size: 14,
                ),
              ],
            ),
            // Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Emotion Intelligence Card
// ─────────────────────────────────────────────
class _EmotionCard extends StatelessWidget {
  final User user;
  const _EmotionCard({required this.user});

  Map<String, int> _analyze(List<QueryDocumentSnapshot> docs) {
    final e = {
      'Happy': 0,
      'Curious': 0,
      'Focused': 0,
      'Stressed': 0,
      'Calm': 0,
      'Creative': 0,
    };
    final map = {
      'Happy': [
        'great',
        'good',
        'awesome',
        'love',
        'happy',
        'excellent',
        'nice',
        'thanks',
        'thank',
      ],
      'Curious': [
        'what',
        'how',
        'why',
        'explain',
        'learn',
        'understand',
        'tell',
        'know',
      ],
      'Focused': [
        'task',
        'reminder',
        'alarm',
        'schedule',
        'work',
        'plan',
        'create',
        'set',
      ],
      'Stressed': [
        'urgent',
        'help',
        'problem',
        'issue',
        'error',
        'wrong',
        'fail',
        'busy',
      ],
      'Calm': [
        'weather',
        'time',
        'date',
        'battery',
        'music',
        'relax',
        'open',
        'play',
      ],
      'Creative': [
        'write',
        'story',
        'design',
        'idea',
        'generate',
        'imagine',
        'translate',
        'poem',
      ],
    };
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final messages = data['messages'] as List<dynamic>? ?? [];
      for (final msg in messages) {
        final text = ((msg as Map)['content'] as String? ?? '').toLowerCase();
        map.forEach((emotion, words) {
          if (words.any(text.contains)) e[emotion] = e[emotion]! + 1;
        });
      }
    }
    return e;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .orderBy('updatedAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        final emotions = _analyze(docs);
        final total = emotions.values.fold(0, (a, b) => a + b);
        final sorted = emotions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final dominant = sorted.isNotEmpty && sorted.first.value > 0
            ? sorted.first.key
            : 'Neutral';

        const colors = {
          'Happy': _amber,
          'Curious': _cyan,
          'Focused': _purple,
          'Stressed': Colors.redAccent,
          'Calm': _green,
          'Creative': _pink,
        };

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: _surface,
            border: Border.all(color: _pink.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _pink.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: _pink,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emotion AI',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Based on your conversations',
                            style: GoogleFonts.inter(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          (colors[dominant] ?? _cyan).withOpacity(0.3),
                          (colors[dominant] ?? _cyan).withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: (colors[dominant] ?? _cyan).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      dominant,
                      style: GoogleFonts.jetBrainsMono(
                        color: colors[dominant] ?? _cyan,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (total == 0)
                // Empty state — show placeholder rings
                _EmotionEmptyState()
              else
                // Emotion bars
                ...sorted.where((e) => e.value > 0).take(5).map((entry) {
                  final pct = entry.value / total;
                  final col = colors[entry.key] ?? _cyan;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 68,
                          child: Text(
                            entry.key,
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: pct,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: LinearGradient(
                                      colors: [col, col.withOpacity(0.4)],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(pct * 100).round()}%',
                          style: GoogleFonts.jetBrainsMono(
                            color: col,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _EmotionEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Happy', 'color': _amber},
      {'label': 'Curious', 'color': _cyan},
      {'label': 'Focused', 'color': _purple},
      {'label': 'Calm', 'color': _green},
      {'label': 'Creative', 'color': _pink},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start chatting to unlock emotion insights',
          style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (e) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (e['color'] as Color).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (e['color'] as Color).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: (e['color'] as Color).withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        e['label'] as String,
                        style: TextStyle(
                          color: (e['color'] as Color).withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Recent Sessions
// ─────────────────────────────────────────────
class _RecentSessions extends StatelessWidget {
  final User user;
  const _RecentSessions({required this.user});

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inDays == 0) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _cyan, strokeWidth: 2),
          );
        }

        final all = snap.data?.docs ?? [];
        final valid =
            all.where((d) {
              final t = (d.data() as Map)['type'] as String? ?? '';
              return ['chat', 'voice', 'translation'].contains(t);
            }).toList()..sort((a, b) {
              final at = (a.data() as Map)['updatedAt'] as Timestamp?;
              final bt = (b.data() as Map)['updatedAt'] as Timestamp?;
              return (bt?.seconds ?? 0).compareTo(at?.seconds ?? 0);
            });

        if (valid.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: Colors.white12, size: 22),
                const SizedBox(width: 12),
                Text(
                  'No sessions yet — start a conversation!',
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
                ),
              ],
            ),
          );
        }

        const typeIcon = {
          'voice': Icons.mic_rounded,
          'translation': Icons.translate_rounded,
        };
        const typeColor = {'voice': _green, 'translation': _amber};

        return Column(
          children: valid.take(3).map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final type = d['type'] as String? ?? 'chat';
            final title = d['title'] as String? ?? 'New Chat';
            final count = d['messageCount'] as int? ?? 0;
            final ts = d['updatedAt'] as Timestamp?;
            final date = ts != null ? _formatDate(ts.toDate()) : '';
            final icon = typeIcon[type] ?? Icons.chat_bubble_rounded;
            final color = typeColor[type] ?? _cyan;

            return GestureDetector(
              onTap: () {
                if (type == 'voice') {
                  Get.toNamed('/voice', arguments: {'sessionId': doc.id});
                } else {
                  Get.to(() => ChatBox(initialSessionId: doc.id));
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$count messages  ·  $date',
                            style: GoogleFonts.inter(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white12,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Usage Analytics
// ─────────────────────────────────────────────
class _UsageAnalytics extends StatelessWidget {
  final User user;
  const _UsageAnalytics({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .snapshots(),
      builder: (_, snap) {
        final all = snap.data?.docs ?? [];
        final valid = all.where((d) {
          final t = (d.data() as Map)['type'] as String? ?? '';
          return ['chat', 'voice', 'translation'].contains(t);
        }).toList();

        final total = valid.length;
        final voice = valid
            .where((d) => (d.data() as Map)['type'] == 'voice')
            .length;
        final chat = valid
            .where((d) => (d.data() as Map)['type'] == 'chat')
            .length;
        final trans = valid
            .where((d) => (d.data() as Map)['type'] == 'translation')
            .length;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: _pink,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usage Analytics',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Session breakdown',
                            style: GoogleFonts.inter(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$total total',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white30,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mini donut-style row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AnalyticCircle(
                    label: 'Voice',
                    count: voice,
                    total: total,
                    color: _green,
                  ),
                  _AnalyticCircle(
                    label: 'Chat',
                    count: chat,
                    total: total,
                    color: _cyan,
                  ),
                  _AnalyticCircle(
                    label: 'Translate',
                    count: trans,
                    total: total,
                    color: _amber,
                  ),
                ],
              ),

              if (total > 0) ...[
                const SizedBox(height: 20),
                _bar('Voice', voice, total, _green),
                const SizedBox(height: 8),
                _bar('Chat', chat, total, _cyan),
                const SizedBox(height: 8),
                _bar('Translate', trans, total, _amber),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _bar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.4)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(pct * 100).round()}%',
          style: GoogleFonts.jetBrainsMono(color: color, fontSize: 10),
        ),
      ],
    );
  }
}

class _AnalyticCircle extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _AnalyticCircle({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: pct,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
              ),
              Text(
                '${(pct * 100).round()}%',
                style: GoogleFonts.rajdhani(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
        ),
        Text(
          '$count',
          style: GoogleFonts.jetBrainsMono(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Section Title
// ─────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title, sub;
  final String? action;
  final VoidCallback? onAction;
  const _SectionTitle({
    required this.title,
    required this.sub,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _cyan.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _cyan.withOpacity(0.2)),
              ),
              child: Text(
                action!,
                style: GoogleFonts.inter(color: _cyan, fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }
}







