import 'package:ai_voice_chat/screens/remote/ac_remote/button_screen.dart';
import 'package:ai_voice_chat/screens/remote/ac_remote/acusagescreen.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AcRemoteScreen extends StatefulWidget {
  final String brand;
  const AcRemoteScreen({super.key, required this.brand});
  @override
  State<AcRemoteScreen> createState() => _AcRemoteScreenState();
}

class _AcRemoteScreenState extends State<AcRemoteScreen> {
  static const _cyan = Color(0xFF4FD8EB);
  static const _purple = Color(0xFFB06EFF);

  int _temp = 24;
  int _indoorTemp = 28;
  String _selectedMode = 'Fan';
  bool _acOn = true;
  String _selectedBrand = '';

  final List<Map<String, dynamic>> _modes = [
    {
      'icon': Icons.ac_unit_rounded,
      'label': 'Cool',
      'color': const Color(0xFF38BDF8),
    },
    {
      'icon': Icons.whatshot_rounded,
      'label': 'Heat',
      'color': Colors.orangeAccent,
    },
    {
      'icon': Icons.water_drop_rounded,
      'label': 'Dry',
      'color': const Color(0xFF818CF8),
    },
    {'icon': Icons.toys_rounded, 'label': 'Fan', 'color': _cyan},
    {
      'icon': Icons.autorenew_rounded,
      'label': 'Auto',
      'color': const Color(0xFF22C55E),
    },
  ];

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

  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.brand.isNotEmpty) _selectedBrand = widget.brand;
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
                            'Remote · Progress Timeline',
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

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ── Weather + power ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cloud_rounded,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Faisalabad  25° Cloudy',
                                  style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Power toggle
                          GestureDetector(
                            onTap: () {
                              setState(() => _acOn = !_acOn);
                              _show(
                                _acOn ? '✅ AC turned ON' : '❌ AC turned OFF',
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _acOn
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _acOn
                                      ? Colors.green.withOpacity(0.4)
                                      : Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.power_settings_new_rounded,
                                    color: _acOn
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _acOn ? 'ON' : 'OFF',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: _acOn
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Mode + Temp dial ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Mode sidebar
                          Column(
                            children: _modes.map((m) {
                              final sel = m['label'] == _selectedMode;
                              final color = m['color'] as Color;
                              return GestureDetector(
                                onTap: () {
                                  setState(
                                    () => _selectedMode = m['label'] as String,
                                  );
                                  _show('Mode: ${m['label']}');
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 76,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? color.withOpacity(0.18)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: sel
                                          ? color.withOpacity(0.5)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        m['icon'] as IconData,
                                        color: sel ? color : Colors.white38,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        m['label'] as String,
                                        style: GoogleFonts.inter(
                                          color: sel ? color : Colors.white38,
                                          fontSize: 10,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const Spacer(),

                          // Temperature dial
                          Column(
                            children: [
                              // Up
                              GestureDetector(
                                onTap: () {
                                  if (_temp < 32) setState(() => _temp++);
                                  _show('Temp: $_temp°C');
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
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
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Dial
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.08),
                                        width: 14,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.03),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_temp°C',
                                        style: GoogleFonts.rajdhani(
                                          color: Colors.white,
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '$_indoorTemp°C indoor',
                                        style: GoogleFonts.inter(
                                          color: Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Down
                              GestureDetector(
                                onTap: () {
                                  if (_temp > 16) setState(() => _temp--);
                                  _show('Temp: $_temp°C');
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.05),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white54,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ── Quick action buttons ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _actionBtn(
                            Icons.ac_unit_rounded,
                            'Cool',
                            () => _show('Quick Cool'),
                          ),
                          _actionBtn(
                            Icons.tune_rounded,
                            'Adjust',
                            () => _show('Adjust settings'),
                          ),
                          _actionBtn(
                            Icons.bar_chart_rounded,
                            'Stats',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AcEnergyOverviewScreen(),
                              ),
                            ),
                          ),
                          _actionBtn(
                            Icons.favorite_border_rounded,
                            'Fav',
                            () => _show('Added to favourites'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Brand List ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Brand List',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                // Search field
                                SizedBox(
                                  width: 140,
                                  child: TextField(
                                    controller: _searchCtrl,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search brand...',
                                      hintStyle: GoogleFonts.inter(
                                        color: Colors.white24,
                                        fontSize: 11,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search_rounded,
                                        color: Colors.white24,
                                        size: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredBrands.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 2.4,
                                  ),
                              itemBuilder: (_, i) {
                                final brand = filteredBrands[i];
                                final sel = brand == _selectedBrand;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedBrand = brand);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AcRemoteButton(brandName: brand),
                                      ),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? _cyan.withOpacity(0.15)
                                          : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: sel
                                            ? _cyan.withOpacity(0.4)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      brand,
                                      style: GoogleFonts.inter(
                                        color: sel ? _cyan : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 70,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white54, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
        ),
      );
}
