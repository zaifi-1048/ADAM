import 'dart:ui';
import 'package:ai_voice_chat/screens/remote/tv_remote/connecttvscan.dart';
import 'package:ai_voice_chat/screens/remote/tv_remote/tvusagescreen.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TvRemoteScreen extends StatefulWidget {
  const TvRemoteScreen({super.key});
  @override
  State<TvRemoteScreen> createState() => _TvRemoteScreenState();
}

class _TvRemoteScreenState extends State<TvRemoteScreen>
    with SingleTickerProviderStateMixin {
  static const _cyan = Color(0xFF4FD8EB);
  static const _card = Color(0xFF161B22);
  static const _surface = Color(0xFF0D1117);

  int _tab = 0;
  bool _tvOn = true;
  int _volume = 18;
  int _channel = 5;
  bool _muted = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _tap(String action) {
    HapticFeedback.lightImpact();
    switch (action) {
      case 'up':
        _showCmd('↑ Navigate Up');
        break;
      case 'down':
        _showCmd('↓ Navigate Down');
        break;
      case 'left':
        _showCmd('← Navigate Left');
        break;
      case 'right':
        _showCmd('→ Navigate Right');
        break;
      case 'ok':
        _showCmd('✓ OK / Select');
        break;
      case 'back':
        _showCmd('⬅ Back');
        break;
      case 'home':
        _showCmd('⌂ Home');
        break;
      case 'cast':
        _showCmd('📡 Cast Screen');
        break;
      case 'mute':
        setState(() => _muted = !_muted);
        _showCmd(_muted ? '🔇 Muted' : '🔊 Unmuted');
        break;
      case 'vol+':
        if (_volume < 100) setState(() => _volume++);
        _showCmd('Volume: $_volume');
        break;
      case 'vol-':
        if (_volume > 0) setState(() => _volume--);
        _showCmd('Volume: $_volume');
        break;
      case 'ch+':
        setState(() => _channel++);
        _showCmd('Channel: $_channel');
        break;
      case 'ch-':
        if (_channel > 1) setState(() => _channel--);
        _showCmd('Channel: $_channel');
        break;
      case 'power':
        setState(() => _tvOn = !_tvOn);
        Get.snackbar(
          _tvOn ? 'TV On' : 'TV Off',
          _tvOn ? 'TV turned on' : 'TV turned off',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: (_tvOn ? Colors.green : Colors.red).withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        break;
    }
  }

  void _tapNumber(String num) {
    HapticFeedback.selectionClick();
    _showCmd('Channel $num');
  }

  void _tapApp(String app) {
    HapticFeedback.mediumImpact();
    _showCmd('Opening $app');
  }

  void _showCmd(String msg) {
    Get.snackbar(
      '',
      msg,
      titleText: const SizedBox.shrink(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _cyan.withOpacity(0.85),
      colorText: Colors.black,
      duration: const Duration(milliseconds: 1200),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      borderRadius: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      bottomNavigationBar: const CustomNavBar(),
      backgroundColor: _surface,
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
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 6),
                _buildSubHeader(),
                const SizedBox(height: 14),
                _buildTopBar(),
                const SizedBox(height: 16),
                _buildNavRow(),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _buildTabContent(size),
                ),
                const SizedBox(height: 16),
                _buildTabSwitcher(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
        const SizedBox(width: 12),
        Text(
          'TV Remote',
          style: GoogleFonts.rajdhani(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnergyOverviewScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.bolt_rounded, color: _cyan, size: 18),
          ),
        ),
      ],
    ),
  );

  Widget _buildSubHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        Text(
          ['Remote', 'Control', 'Channels'][_tab],
          style: GoogleFonts.inter(
            color: _cyan,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        const Text('·', style: TextStyle(color: Colors.white24)),
        const SizedBox(width: 6),
        Text(
          'Progress Timeline',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
        ),
      ],
    ),
  );

  // ── Top bar: power + TV name ──
  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        // Power OFF
        _powerBtn(false),
        const SizedBox(width: 10),
        // TV name card
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EnergyOverviewScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _tvOn
                            ? Color.lerp(
                                Colors.green,
                                const Color(0xFF4ADE80),
                                _pulseAnim.value,
                              )!
                            : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.tv_rounded, color: Colors.white54, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Living Room LG TV',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Power ON
        _powerBtn(true),
      ],
    ),
  );

  Widget _powerBtn(bool isOn) => GestureDetector(
    onTap: () => _tap('power'),
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _card,
        border: Border.all(color: Colors.white12),
      ),
      child: Icon(
        Icons.power_settings_new_rounded,
        color: isOn ? Colors.greenAccent : Colors.redAccent,
        size: 24,
      ),
    ),
  );

  // ── Nav Row ──
  Widget _buildNavRow() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _circleBtn(Icons.arrow_back_ios_rounded, () => _tap('back')),
        Row(
          children: [
            _smallRound(Icons.tv_rounded),
            const SizedBox(width: 10),
            _smallRound(Icons.control_camera_rounded, active: true),
          ],
        ),
        _circleBtn(
          Icons.home_rounded,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConnectTVScanScreen()),
          ),
        ),
      ],
    ),
  );

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _card,
        border: Border.all(color: Colors.white12),
      ),
      child: Icon(icon, color: Colors.white70, size: 18),
    ),
  );

  Widget _smallRound(IconData icon, {bool active = false}) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? _cyan : _card,
      border: Border.all(color: Colors.white12),
    ),
    child: Icon(icon, color: active ? Colors.black : Colors.white54, size: 18),
  );

  // ── Tab Content ──
  Widget _buildTabContent(Size size) {
    switch (_tab) {
      case 0:
        return _buildRemoteTab(size);
      case 1:
        return _buildControlTab();
      case 2:
        return _buildChannelsTab();
      default:
        return const SizedBox();
    }
  }

  // Tab 0 — D-pad + volume/channel ──
  Widget _buildRemoteTab(Size size) {
    final dSize = size.width * 0.62;
    return Column(
      key: const ValueKey(0),
      children: [
        // D-Pad
        SizedBox(
          width: dSize,
          height: dSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF060A10),
                ),
              ),
              // Arrows
              _dpadBtn(
                Icons.keyboard_arrow_up_rounded,
                Alignment.topCenter,
                () => _tap('up'),
              ),
              _dpadBtn(
                Icons.keyboard_arrow_down_rounded,
                Alignment.bottomCenter,
                () => _tap('down'),
              ),
              _dpadBtn(
                Icons.keyboard_arrow_left_rounded,
                Alignment.centerLeft,
                () => _tap('left'),
              ),
              _dpadBtn(
                Icons.keyboard_arrow_right_rounded,
                Alignment.centerRight,
                () => _tap('right'),
              ),
              // OK
              GestureDetector(
                onTap: () => _tap('ok'),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'OK',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Volume / misc / channel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Volume bar
              _verticalBar(
                top: Icons.add_rounded,
                bottom: Icons.remove_rounded,
                label: _muted ? '🔇' : '$_volume',
                onTop: () => _tap('vol+'),
                onBottom: () => _tap('vol-'),
              ),
              // Middle row
              Column(
                children: [
                  _circleBtn(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    () => _tap('mute'),
                  ),
                  const SizedBox(height: 10),
                  _circleBtn(Icons.cast_rounded, () => _tap('cast')),
                  const SizedBox(height: 10),
                  _circleBtn(Icons.logout_rounded, () => _tap('back')),
                ],
              ),
              // Channel bar
              _verticalBar(
                top: Icons.keyboard_arrow_up_rounded,
                bottom: Icons.keyboard_arrow_down_rounded,
                label: 'CH',
                onTop: () => _tap('ch+'),
                onBottom: () => _tap('ch-'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dpadBtn(IconData icon, Alignment align, VoidCallback onTap) => Align(
    alignment: align,
    child: GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Icon(icon, color: Colors.white60, size: 30),
      ),
    ),
  );

  Widget _verticalBar({
    required IconData top,
    required IconData bottom,
    required String label,
    required VoidCallback onTop,
    required VoidCallback onBottom,
  }) => Container(
    width: 52,
    height: 130,
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: onTop,
          child: Icon(top, color: Colors.white60, size: 22),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: onBottom,
          child: Icon(bottom, color: Colors.white60, size: 22),
        ),
      ],
    ),
  );

  // Tab 1 — Number pad ──
  Widget _buildControlTab() {
    final buttons = [
      {'t': '1', 's': ''},
      {'t': '2', 's': 'ABC'},
      {'t': '3', 's': 'DEF'},
      {'t': '4', 's': 'GHI'},
      {'t': '5', 's': 'JKL'},
      {'t': '6', 's': 'MNO'},
      {'t': '7', 's': 'PQRS'},
      {'t': '8', 's': 'TUV'},
      {'t': '9', 's': 'WXYZ'},
      {'t': 'TTX', 's': ''},
      {'t': '0', 's': ''},
      {'t': 'PRE-CH', 's': ''},
    ];
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: buttons.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 20,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, i) {
          final b = buttons[i];
          return GestureDetector(
            onTap: () => _tapNumber(b['t']!),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    b['t']!,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (b['s']!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      b['s']!,
                      style: GoogleFonts.inter(
                        color: Colors.black45,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Tab 2 — Streaming apps with logo assets ──
  Widget _buildChannelsTab() {
    final apps = [
      {
        'name': 'Netflix',
        'asset': 'assets/icons/netflix.png',
        'color': const Color(0xFF8B0000),
      },
      {
        'name': 'YouTube',
        'asset': 'assets/icons/youtube.png',
        'color': const Color(0xFF8B0000),
      },
      {
        'name': 'Chrome',
        'asset': 'assets/icons/chrome.png',
        'color': const Color(0xFF0D3B6E),
      },
      {
        'name': 'PlayStation',
        'asset': 'assets/icons/playstation.png',
        'color': const Color(0xFF0D2060),
      },
      {
        'name': 'Disney+',
        'asset': 'assets/icons/disney.png',
        'color': const Color(0xFF0A1A4A),
      },
      {
        'name': 'Prime',
        'asset': 'assets/icons/prime.png',
        'color': const Color(0xFF003D5B),
      },
    ];
    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: apps.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (_, i) {
          final app = apps[i];
          final color = app['color'] as Color;
          return GestureDetector(
            onTap: () => _tapApp(app['name'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    app['asset'] as String,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white54,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app['name'] as String,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab Switcher ──
  Widget _buildTabSwitcher() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: List.generate(3, (i) {
              final selected = _tab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? _cyan : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          [
                            Icons.settings_remote_rounded,
                            Icons.dialpad_rounded,
                            Icons.apps_rounded,
                          ][i],
                          color: selected ? Colors.black : Colors.white54,
                          size: 18,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Text(
                            ['Remote', 'Control', 'Channels'][i],
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ),
  );
}
