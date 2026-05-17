import 'package:ai_voice_chat/screens/remote/tv_remote/tvremotescreen.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class ConnectTVDetailsScreen extends StatefulWidget {
  const ConnectTVDetailsScreen({super.key});
  @override
  State<ConnectTVDetailsScreen> createState() => _ConnectTVDetailsScreenState();
}

class _ConnectTVDetailsScreenState extends State<ConnectTVDetailsScreen> {
  double _volume = 0.45;
  bool _resumeLast = true;
  bool _muteOnConnect = false;
  bool _vibration = true;
  bool _isTestingSound = false;
  bool _isFindingTV = false;
  String _tvName = 'Living Room TV';
  String _room = 'Living room';

  final _nameCtrl = TextEditingController(text: 'Living Room TV');

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _testSound() async {
    setState(() => _isTestingSound = true);
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isTestingSound = false);
      Get.snackbar(
        'Test Sound',
        'Audio signal sent to TV',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _findTV() async {
    setState(() => _isFindingTV = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isFindingTV = false);
      Get.snackbar(
        'Find TV',
        'On-screen message sent to Living Room TV',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4FD8EB).withOpacity(0.8),
        colorText: Colors.black,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _editTVName() async {
    _nameCtrl.text = _tvName;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2229),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit TV Name',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: _nameCtrl,
          autofocus: true,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter TV name',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0D1117),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF4FD8EB)),
            ),
          ),
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
            onPressed: () => Navigator.pop(ctx, _nameCtrl.text.trim()),
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF4FD8EB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) setState(() => _tvName = result);
  }

  void _forgetTV() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2229),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Forget TV',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Remove "$_tvName" from your devices?',
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Forget',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      Get.snackbar(
        'Device Removed',
        '$_tvName has been forgotten',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF4FD8EB);
    const surface = Color(0xFF161B22);

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
                          color: cyan,
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
                            'Connect TV',
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Display · Adding Device',
                            style: GoogleFonts.jetBrainsMono(
                              color: cyan,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.settings_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ── TV Status Card ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cyan.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.tv_rounded,
                                color: cyan,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _tvName,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _chip('ON', const Color(0xFF22C55E)),
                                      const SizedBox(width: 8),
                                      _chip('Same Wi-Fi network', cyan),
                                      const SizedBox(width: 8),
                                      _chip(
                                        'Remote active',
                                        const Color(0xFFB06EFF),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── TV Details ──
                      _card(
                        title: 'TV Details',
                        subtitle: 'For this device only',
                        children: [
                          _row(
                            'TV name',
                            _tvName,
                            editIcon: true,
                            onEdit: _editTVName,
                          ),
                          Divider(color: Colors.white.withOpacity(0.06)),
                          _row('Room', _room),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Remote Preferences ──
                      _card(
                        title: 'Remote Preferences',
                        children: [
                          Text(
                            'Default volume when connecting',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.volume_down_rounded,
                                color: Colors.white38,
                                size: 18,
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: cyan,
                                    inactiveTrackColor: Colors.white12,
                                    thumbColor: cyan,
                                    overlayColor: cyan.withOpacity(0.2),
                                    trackHeight: 3,
                                  ),
                                  child: Slider(
                                    value: _volume,
                                    onChanged: (v) =>
                                        setState(() => _volume = v),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.volume_up_rounded,
                                color: Colors.white38,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(_volume * 100).round()}%',
                                style: GoogleFonts.jetBrainsMono(
                                  color: cyan,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Start Behavior',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _toggleChip(
                                'Resume Last channel',
                                _resumeLast,
                                () => setState(() {
                                  _resumeLast = true;
                                  _muteOnConnect = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              _toggleChip(
                                'Mute on connect',
                                _muteOnConnect,
                                () => setState(() {
                                  _muteOnConnect = true;
                                  _resumeLast = false;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Light vibration on button press',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              Switch(
                                value: _vibration,
                                onChanged: (v) =>
                                    setState(() => _vibration = v),
                                activeTrackColor: cyan,
                                activeColor: Colors.white,
                                inactiveTrackColor: Colors.white12,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Quick Actions ──
                      _card(
                        title: 'Quick Actions',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isTestingSound ? null : _testSound,
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      children: [
                                        _isTestingSound
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFF4FD8EB),
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.volume_up_outlined,
                                                color: cyan,
                                                size: 26,
                                              ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Test Sound',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Play a short tone to confirm audio',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            color: Colors.white38,
                                            fontSize: 10,
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
                                  onTap: _isFindingTV ? null : _findTV,
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      children: [
                                        _isFindingTV
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFF4FD8EB),
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.search_rounded,
                                                color: cyan,
                                                size: 26,
                                              ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Find TV',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Show on-screen message to locate this TV',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            color: Colors.white38,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Connection Info ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connection',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Changes apply only to $_tvName.',
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Forget TV ──
                      GestureDetector(
                        onTap: _forgetTV,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Forget this TV',
                            style: GoogleFonts.inter(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Done ──
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TvRemoteScreen(),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4FD8EB), Color(0xFF00C9FF)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: cyan.withOpacity(0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Done',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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

  Widget _card({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
            ),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool editIcon = false,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              ),
              if (editIcon) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF4FD8EB),
                    size: 15,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _toggleChip(String label, bool selected, VoidCallback onTap) {
    const cyan = Color(0xFF4FD8EB);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? cyan.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? cyan : Colors.white12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? cyan : Colors.white54,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
