import 'dart:async';
import 'package:ai_voice_chat/screens/remote/tv_remote/connecttvdetails.dart';
import 'package:ai_voice_chat/screens/remote/tv_remote/tvremotescreen.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ConnectTVScanScreen extends StatefulWidget {
  const ConnectTVScanScreen({super.key});
  @override
  State<ConnectTVScanScreen> createState() => _ConnectTVScanScreenState();
}

class _ConnectTVScanScreenState extends State<ConnectTVScanScreen>
    with TickerProviderStateMixin {
  bool _isScanning = false;
  bool _bluetoothOn = false;
  bool _wifiOn = true;
  bool _permissionsOk = false;

  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  // Simulated discovered devices
  final List<Map<String, dynamic>> _devices = [];

  final List<Map<String, dynamic>> _savedDevices = [
    {'name': 'Living Room TV', 'status': 'Manage', 'isManage': true},
    {'name': 'Bedroom TV', 'status': 'Connected', 'isManage': false},
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.linear));
    _checkPermissions();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final bt = await Permission.bluetooth.status;
    final btScan = await Permission.bluetoothScan.status;
    final loc = await Permission.locationWhenInUse.status;
    setState(() {
      _bluetoothOn = bt.isGranted || btScan.isGranted;
      _permissionsOk = loc.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    final results = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = results.values.every((s) => s.isGranted);
    setState(() {
      _bluetoothOn = results[Permission.bluetooth]?.isGranted ?? false;
      _permissionsOk = allGranted;
    });

    if (allGranted) {
      Get.snackbar(
        'Permissions Granted',
        'You can now scan for devices',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Permission Required',
        'Please allow Bluetooth & Location to scan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _scanForTV() async {
    if (!_permissionsOk) {
      await _requestPermissions();
      if (!_permissionsOk) return;
    }

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    // Simulate progressive device discovery
    final found = [
      {'name': 'Samsung Smart TV', 'ip': '192.168.1.101', 'signal': 'Strong'},
      {'name': 'LG OLED TV', 'ip': '192.168.1.105', 'signal': 'Good'},
      {'name': 'Sony Bravia', 'ip': '192.168.1.108', 'signal': 'Weak'},
    ];

    for (final device in found) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _devices.add(device));
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isScanning = false);
      Get.snackbar(
        'Scan Complete',
        '${_devices.length} device${_devices.length == 1 ? '' : 's'} found',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4FD8EB).withOpacity(0.8),
        colorText: Colors.black,
        duration: const Duration(seconds: 2),
      );
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

                      // ── Phone Status Card ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Phone',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Control TV over Bluetooth or Wi-Fi',
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _statusChip(
                                  Icons.bluetooth_rounded,
                                  'Bluetooth ${_bluetoothOn ? "ON" : "OFF"}',
                                  _bluetoothOn ? cyan : Colors.white24,
                                  _bluetoothOn,
                                ),
                                const SizedBox(width: 10),
                                _statusChip(
                                  Icons.wifi_rounded,
                                  'Wi-Fi ${_wifiOn ? "ON" : "OFF"}',
                                  _wifiOn
                                      ? const Color(0xFF22C55E)
                                      : Colors.white24,
                                  _wifiOn,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Scan Button ──
                      GestureDetector(
                        onTap: _isScanning ? null : _scanForTV,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: _isScanning
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
                            boxShadow: _isScanning
                                ? []
                                : [
                                    BoxShadow(
                                      color: cyan.withOpacity(0.3),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: _isScanning
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    RotationTransition(
                                      turns: _scanAnim,
                                      child: const Icon(
                                        Icons.radar_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Scanning...',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.radar_rounded,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Scan for TV',
                                      style: GoogleFonts.inter(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // ── Discovered Devices ──
                      if (_devices.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Found Devices',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._devices.map((d) => _foundDeviceTile(d, cyan)),
                      ],

                      const SizedBox(height: 20),

                      // ── Saved Devices ──
                      Text(
                        'Saved Devices',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._savedDevices.map((d) => _savedDeviceTile(d, context)),

                      const SizedBox(height: 20),

                      // ── Requirements Card ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cyan.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cyan.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Make Sure Before Connecting',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _bullet(
                              'Phone and TV are on the same Wi-Fi network',
                            ),
                            _bullet('TV is powered ON'),
                            _bullet(
                              'Bluetooth & location permission are allowed',
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _bullet('Adjust app permission'),
                                ),
                                GestureDetector(
                                  onTap: _requestPermissions,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cyan.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: cyan.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Permission',
                                      style: GoogleFonts.inter(
                                        color: cyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Continue Button ──
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TvRemoteScreen(),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4FD8EB), Color(0xFF00C9FF)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: cyan.withOpacity(0.3),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Continue to Remote',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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

  Widget _foundDeviceTile(Map<String, dynamic> d, Color cyan) {
    final signal = d['signal'] as String;
    final signalColor = signal == 'Strong'
        ? const Color(0xFF22C55E)
        : signal == 'Good'
        ? cyan
        : Colors.orangeAccent;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConnectTVDetailsScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cyan.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tv_rounded,
                color: Color(0xFF4FD8EB),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d['name'] as String,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    d['ip'] as String,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: signalColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: signalColor.withOpacity(0.3)),
              ),
              child: Text(
                'Signal $signal',
                style: GoogleFonts.inter(
                  color: signalColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedDeviceTile(Map<String, dynamic> d, BuildContext context) {
    final isManage = d['isManage'] as bool;
    final color = isManage ? const Color(0xFF4FD8EB) : const Color(0xFF22C55E);
    return GestureDetector(
      onTap: isManage
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConnectTVDetailsScreen()),
            )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.tv_rounded, color: Colors.white38, size: 18),
                const SizedBox(width: 10),
                Text(
                  d['name'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  d['status'] as String,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isManage) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, color: color, size: 12),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(IconData icon, String label, Color color, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(active ? 0.1 : 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(active ? 0.4 : 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? color : Colors.white24,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: active ? color : Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Color(0xFF4FD8EB))),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
