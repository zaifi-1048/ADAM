import 'package:ai_voice_chat/screens/remote/ac_remote/ac_remote.dart';
import 'package:ai_voice_chat/screens/remote/tv_remote/tvremotescreen.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AcEnergyOverviewScreen extends StatefulWidget {
  const AcEnergyOverviewScreen({super.key});
  @override
  State<AcEnergyOverviewScreen> createState() => _AcEnergyOverviewScreenState();
}

class _AcEnergyOverviewScreenState extends State<AcEnergyOverviewScreen> {
  String _range = 'Today';
  bool _tvOn = true;
  bool _acOn = false;

  static const _cyan = Color(0xFF4FD8EB);
  static const _purple = Color(0xFFB06EFF);
  static const _surface = Color(0xFF161B22);

  final Map<String, Map<String, String>> _stats = {
    'Today': {
      'time': '5h 20m',
      'energy': '3.8 kWh',
      'progress': '0.65',
      'label': '-65% of target',
    },
    'Week': {
      'time': '31h 40m',
      'energy': '22.6 kWh',
      'progress': '0.52',
      'label': '-52% of target',
    },
    'Month': {
      'time': '128h',
      'energy': '91.2 kWh',
      'progress': '0.69',
      'label': '-69% of target',
    },
  };

  Map<String, String> get _current => _stats[_range]!;

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
                            'Energy Overview',
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Display · Total Watt',
                            style: GoogleFonts.jetBrainsMono(
                              color: _cyan,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Live',
                            style: GoogleFonts.inter(
                              color: Colors.greenAccent,
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ── Time Range ──
                      Text(
                        'Time Range',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: ['Today', 'Week', 'Month'].map((label) {
                            final sel = _range == label;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _range = label),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel ? _cyan : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    label,
                                    style: GoogleFonts.inter(
                                      color: sel
                                          ? Colors.black
                                          : Colors.white54,
                                      fontWeight: sel
                                          ? FontWeight.w800
                                          : FontWeight.w400,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── AC Usage Card ──
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _purple.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.ac_unit_rounded,
                                    color: _purple,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AC usage',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Living Room AC · $_range',
                                        style: GoogleFonts.inter(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _acOn
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: _stat(
                                    'On Time',
                                    _current['time']!,
                                    'So far today',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.white12,
                                ),
                                Expanded(
                                  child: _stat(
                                    'Energy',
                                    _current['energy']!,
                                    'Estimated usage',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Limit Usage',
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _current['label']!,
                                  style: GoogleFonts.inter(
                                    color: _cyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: double.parse(_current['progress']!),
                                minHeight: 6,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation(_cyan),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.circle, color: _cyan, size: 7),
                                const SizedBox(width: 6),
                                Text(
                                  'Portion of your daily energy budget used by AC',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),
                            Text(
                              'Connected Controllers',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _deviceChip("Ahmed's iPhone"),
                                _deviceChip("Bedroom tablet"),
                                _deviceChip("Guest remote"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Device Cards ──
                      Text(
                        'Device Control',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _deviceCard(
                              title: 'TV',
                              count: '3 Devices',
                              isOn: _tvOn,
                              icon: Icons.tv_rounded,
                              color: _cyan,
                              onToggle: () => setState(() => _tvOn = !_tvOn),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TvRemoteScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _deviceCard(
                              title: 'AC',
                              count: '3 Devices',
                              isOn: _acOn,
                              icon: Icons.ac_unit_rounded,
                              color: _purple,
                              onToggle: () => setState(() => _acOn = !_acOn),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AcRemoteScreen(brand: ''),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String title, String value, String sub) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
        ),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          sub,
          style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
        ),
      ],
    ),
  );

  Widget _deviceChip(String name) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.greenAccent.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.greenAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _deviceCard({
    required String title,
    required String count,
    required bool isOn,
    required IconData icon,
    required Color color,
    required VoidCallback onToggle,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOn ? color.withOpacity(0.1) : _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOn
              ? color.withOpacity(0.35)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title Remote',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 36,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isOn ? color.withOpacity(0.3) : Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: isOn
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isOn ? color : Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Icon(icon, color: isOn ? color : Colors.white38, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.rajdhani(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            count,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            isOn ? 'ON' : 'OFF',
            style: GoogleFonts.jetBrainsMono(
              color: isOn ? color : Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
