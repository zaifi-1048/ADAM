import 'package:ai_voice_chat/screens/remote/ac_remote/ac_remote.dart';
import 'package:ai_voice_chat/screens/remote/ac_remote/acusagescreen.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AcControlScreen extends StatefulWidget {
  const AcControlScreen({super.key});
  @override
  State<AcControlScreen> createState() => _AcControlScreenState();
}

class _AcControlScreenState extends State<AcControlScreen> {
  static const _cyan = Color(0xFF4FD8EB);

  int _temp = 24;
  int _indoorTemp = 28;
  String _selectedMode = 'Fan';
  String _selectedBrand = 'Samsung';
  double _windSpeed = 0.5;
  double _cooling = 0.6;
  String _airFlow = 'Medium';
  bool _timerSet = false;
  int _timerMinutes = 30;
  String _searchQuery = '';

  final _searchCtrl = TextEditingController();
  final List<String> _modes = ['Cool', 'Heat', 'Dry', 'Fan', 'Auto'];
  final List<String> _brands = [
    'Samsung',
    'Panasonic',
    'Mitsubishi',
    'LG',
    'Haier',
    'Sanyo',
    'Onida',
    'Aux',
    'Gree',
  ];
  final List<String> _airFlows = ['Low', 'Medium', 'High', 'Auto'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _show(String msg) {
    HapticFeedback.lightImpact();
    Get.snackbar(
      '',
      msg,
      titleText: const SizedBox.shrink(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _cyan.withOpacity(0.85),
      colorText: Colors.black,
      duration: const Duration(milliseconds: 1400),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      borderRadius: 12,
    );
  }

  void _showTimer() async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int mins = _timerMinutes;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            backgroundColor: const Color(0xFF1C2229),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Set Timer',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$mins minutes',
                  style: GoogleFonts.rajdhani(
                    color: _cyan,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Slider(
                  value: mins.toDouble(),
                  min: 5,
                  max: 180,
                  divisions: 35,
                  activeColor: _cyan,
                  inactiveColor: Colors.white12,
                  onChanged: (v) => setS(() => mins = v.round()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, mins),
                child: const Text(
                  'Set',
                  style: TextStyle(
                    color: Color(0xFF4FD8EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _timerMinutes = result;
        _timerSet = true;
      });
      _show('⏱ Timer set for $result minutes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBrands = _brands
        .where((b) => b.toLowerCase().contains(_searchQuery))
        .toList();

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
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AcEnergyOverviewScreen(),
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

              // ── Brand tabs ──
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _brands.length,
                  itemBuilder: (_, i) {
                    final b = _brands[i];
                    final sel = b == _selectedBrand;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedBrand = b),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: sel
                              ? _cyan.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? _cyan : Colors.white.withOpacity(0.12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          b,
                          style: GoogleFonts.inter(
                            color: sel ? _cyan : Colors.white54,
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

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ── Temperature dial ──
                      Center(
                        child: Column(
                          children: [
                            // Up
                            GestureDetector(
                              onTap: () {
                                if (_temp < 32) setState(() => _temp++);
                                _show('Temp: $_temp°C');
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _cyan.withOpacity(0.12),
                                  border: Border.all(
                                    color: _cyan.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: _cyan,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 210,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    value: (_temp - 16) / 16,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.white12,
                                    valueColor: const AlwaysStoppedAnimation(
                                      _cyan,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 130,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF161B22,
                                    ).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.wifi_tethering_rounded,
                                        color: _cyan,
                                        size: 16,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_temp',
                                        style: GoogleFonts.rajdhani(
                                          color: Colors.white,
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '°C',
                                        style: GoogleFonts.inter(
                                          color: Colors.white54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '$_indoorTemp°C indoor',
                                        style: GoogleFonts.inter(
                                          color: Colors.white24,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Down
                            GestureDetector(
                              onTap: () {
                                if (_temp > 16) setState(() => _temp--);
                                _show('Temp: $_temp°C');
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white54,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Wind Speed ──
                      _controlCard(
                        'Wind Speed',
                        Icons.air_rounded,
                        _windSpeed,
                        (v) {
                          setState(() => _windSpeed = v);
                          _show('Wind Speed: ${(v * 100).round()}%');
                        },
                      ),

                      const SizedBox(height: 12),

                      // ── Cooling ──
                      _controlCard('Cooling', Icons.ac_unit_rounded, _cooling, (
                        v,
                      ) {
                        setState(() => _cooling = v);
                        _show('Cooling: ${(v * 100).round()}%');
                      }),

                      const SizedBox(height: 12),

                      // ── Air Flow ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Air Flow',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Set the range',
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    final idx = _airFlows.indexOf(_airFlow);
                                    if (idx > 0)
                                      setState(
                                        () => _airFlow = _airFlows[idx - 1],
                                      );
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.05),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left_rounded,
                                      color: Colors.white54,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                Text(
                                  _airFlow,
                                  style: GoogleFonts.rajdhani(
                                    color: _cyan,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    final idx = _airFlows.indexOf(_airFlow);
                                    if (idx < _airFlows.length - 1)
                                      setState(
                                        () => _airFlow = _airFlows[idx + 1],
                                      );
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _cyan.withOpacity(0.12),
                                      border: Border.all(
                                        color: _cyan.withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: _cyan,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Set Timer + Power Off ──
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _showTimer,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: _timerSet
                                      ? _cyan.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _timerSet
                                        ? _cyan.withOpacity(0.3)
                                        : Colors.white12,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer_rounded,
                                      color: _timerSet ? _cyan : Colors.white54,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _timerSet
                                          ? '$_timerMinutes min'
                                          : 'Set timer',
                                      style: GoogleFonts.inter(
                                        color: _timerSet
                                            ? _cyan
                                            : Colors.white54,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _show('AC powered off');
                                Future.delayed(
                                  const Duration(milliseconds: 800),
                                  () {
                                    if (mounted) Navigator.pop(context);
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.power_settings_new_rounded,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Power Off',
                                      style: GoogleFonts.inter(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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

  Widget _controlCard(
    String label,
    IconData icon,
    double value,
    ValueChanged<double> onChange,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _cyan, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: GoogleFonts.jetBrainsMono(
                  color: _cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _cyan,
              inactiveTrackColor: Colors.white12,
              thumbColor: _cyan,
              overlayColor: _cyan.withOpacity(0.2),
              trackHeight: 3,
            ),
            child: Slider(value: value, onChanged: onChange),
          ),
        ],
      ),
    );
  }
}
