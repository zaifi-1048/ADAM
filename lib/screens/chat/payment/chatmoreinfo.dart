import 'dart:io';
import 'dart:typed_data';
import 'package:ai_voice_chat/screens/chat/image_gallery_screen.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _cyan = Color(0xFF4FD8EB);
const _purple = Color(0xFFB06EFF);
const _pink = Color(0xFFFF6B9D);
const _amber = Color(0xFFFFC947);
const _green = Color(0xFF22C55E);
const _surface = Color(0xFF161B22);
const _bg = Color(0xFF0D1117);

class ChatMoreInfoScreen extends StatefulWidget {
  const ChatMoreInfoScreen({super.key});
  @override
  State<ChatMoreInfoScreen> createState() => _ChatMoreInfoScreenState();
}

class _ChatMoreInfoScreenState extends State<ChatMoreInfoScreen>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;

  static const _pollinationsUrl = 'https://image.pollinations.ai/prompt';

  String _selectedSize = 'Square';
  String _selectedStyle = 'None';
  String _quality = 'standard';
  bool _isGenerating = false;
  Uint8List? _generatedImage;
  String _statusText = '';

  final List<Map<String, dynamic>> _sizes = [
    {
      'label': 'Square',
      'icon': Icons.crop_square,
      'width': 1024,
      'height': 1024,
      'dim': '1024×1024',
    },
    {
      'label': 'Landscape',
      'icon': Icons.crop_landscape,
      'width': 1280,
      'height': 720,
      'dim': '1280×720',
    },
    {
      'label': 'Portrait',
      'icon': Icons.crop_portrait,
      'width': 720,
      'height': 1280,
      'dim': '720×1280',
    },
  ];

  final List<Map<String, dynamic>> _styles = [
    {
      'label': 'None',
      'prompt': '',
      'icon': Icons.block_rounded,
      'color': Colors.white38,
    },
    {
      'label': 'Realistic',
      'prompt': 'photorealistic, ultra detailed, 8k',
      'icon': Icons.camera_alt_rounded,
      'color': _cyan,
    },
    {
      'label': 'Anime',
      'prompt': 'anime style, manga, japanese animation',
      'icon': Icons.auto_awesome_rounded,
      'color': _pink,
    },
    {
      'label': '3D',
      'prompt': '3D render, octane render, cinema 4D',
      'icon': Icons.view_in_ar_rounded,
      'color': _purple,
    },
    {
      'label': 'Oil Paint',
      'prompt': 'oil painting, classical art style',
      'icon': Icons.brush_rounded,
      'color': _amber,
    },
    {
      'label': 'Watercolor',
      'prompt': 'watercolor painting, soft colors',
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFF38BDF8),
    },
  ];

  final List<String> _surprisePrompts = [
    'A futuristic city at night with neon lights',
    'A magical forest with glowing mushrooms',
    'An astronaut riding a horse on Mars',
    'A dragon flying over mountains at sunset',
    'A cyberpunk samurai in Tokyo rain',
    'An underwater palace with mermaids',
    'A cozy cabin in a snowy forest',
    'A robot gardening in a flower field',
  ];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _surpriseMe() {
    final random = (List<String>.from(_surprisePrompts)..shuffle()).first;
    setState(() => _promptController.text = random);
  }

  // ════════════════════════════════════════════
  // ── Pollinations AI Image Generation ──
  // ════════════════════════════════════════════
  Future<void> _generateImage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      Get.snackbar(
        'Empty Prompt',
        'Please describe the image you want',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.85),
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedImage = null;
      _statusText = 'Sending request...';
    });

    try {
      final stylePrompt =
          (_styles.firstWhere((s) => s['label'] == _selectedStyle)['prompt']
              as String?) ??
          '';
      final fullPrompt = stylePrompt.isNotEmpty
          ? '$prompt, $stylePrompt'
          : prompt;

      final size = _sizes.firstWhere((s) => s['label'] == _selectedSize);
      final width = size['width'] as int;
      final height = size['height'] as int;
      final enhance = _quality == 'hd';
      final encodedPrompt = Uri.encodeComponent(fullPrompt);
      final seed = DateTime.now().millisecondsSinceEpoch % 1000000;

      final url =
          '$_pollinationsUrl/$encodedPrompt'
          '?width=$width&height=$height'
          '&enhance=$enhance'
          '&nologo=true'
          '&seed=$seed';

      setState(() => _statusText = 'Painting your image...');

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        setState(() {
          _generatedImage = response.bodyBytes;
          _isGenerating = false;
          _statusText = '';
        });
      } else {
        setState(() {
          _isGenerating = false;
          _statusText = 'Generation failed. Try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _statusText = 'Connection error — check your network.';
      });
      debugPrint('Pollinations error: $e');
    }
  }

  Future<void> _saveImage() async {
    if (_generatedImage == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/ADAM_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(_generatedImage!);
      Get.snackbar(
        'Saved ✅',
        'Image saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not save image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _shareImage() async {
    if (_generatedImage == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ADAM_generated.png');
      await file.writeAsBytes(_generatedImage!);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Generated by ADAM AI\nPrompt: ${_promptController.text}');
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not share image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // ════════════════════════════════════════════
  // ── BUILD ──
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomNavBar(),
      backgroundColor: _bg,
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
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPromptCard(),
                      const SizedBox(height: 22),
                      _buildSizeSection(),
                      const SizedBox(height: 22),
                      _buildStyleSection(),
                      const SizedBox(height: 16),
                      _buildQualityToggle(),
                      if (_statusText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildStatusBanner(),
                      ],
                      if (_generatedImage != null) ...[
                        const SizedBox(height: 22),
                        _buildResultSection(),
                      ],
                    ],
                  ),
                ),
              ),
              _buildGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Image Studio',
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Pollinations AI',
                    style: GoogleFonts.jetBrainsMono(
                      color: _cyan,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _green.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Free',
                      style: GoogleFonts.jetBrainsMono(
                        color: _green,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Get.to(() => const ImageGalleryScreen()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _purple.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.photo_library_rounded,
                  color: _purple,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  'Gallery',
                  style: GoogleFonts.inter(
                    color: _purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildPromptCard() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: _surface,
      border: Border.all(color: _cyan.withOpacity(0.22)),
      boxShadow: [BoxShadow(color: _cyan.withOpacity(0.05), blurRadius: 20)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: _cyan.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            border: Border(bottom: BorderSide(color: _cyan.withOpacity(0.12))),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _cyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Describe Your Image',
                style: GoogleFonts.inter(
                  color: _cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _surpriseMe,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: _amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Surprise Me',
                        style: GoogleFonts.inter(
                          color: _amber,
                          fontSize: 10,
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
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _promptController,
            maxLines: 4,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. A futuristic city at night with neon lights...',
              hintStyle: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.25),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSizeSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Canvas Size', 'Select output dimensions'),
      const SizedBox(height: 12),
      SizedBox(
        height: 86,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _sizes.length,
          itemBuilder: (_, i) {
            final selected = _sizes[i]['label'] == _selectedSize;
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedSize = _sizes[i]['label'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                width: 90,
                decoration: BoxDecoration(
                  color: selected ? _cyan.withOpacity(0.12) : _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? _cyan : Colors.white.withOpacity(0.07),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _sizes[i]['icon'] as IconData,
                      color: selected ? _cyan : Colors.white38,
                      size: 22,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _sizes[i]['label'] as String,
                      style: GoogleFonts.inter(
                        color: selected ? _cyan : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _sizes[i]['dim'] as String,
                      style: GoogleFonts.jetBrainsMono(
                        color: selected
                            ? _cyan.withOpacity(0.7)
                            : Colors.white24,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _buildStyleSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Art Style', 'Visual aesthetic (added to prompt)'),
      const SizedBox(height: 12),
      SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _styles.length,
          itemBuilder: (_, i) {
            final selected = _styles[i]['label'] == _selectedStyle;
            final color = _styles[i]['color'] as Color;
            return GestureDetector(
              onTap: () => setState(
                () => _selectedStyle = _styles[i]['label'] as String,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                width: 76,
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.12) : _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? color : Colors.white.withOpacity(0.07),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _styles[i]['icon'] as IconData,
                      color: selected ? color : Colors.white38,
                      size: 22,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _styles[i]['label'] as String,
                      style: GoogleFonts.inter(
                        color: selected ? color : Colors.white38,
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
      ),
    ],
  );

  // ── Quality toggle ──
  Widget _buildQualityToggle() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Quality', 'HD enables prompt enhancement'),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _quality = 'standard'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _quality == 'standard'
                      ? _cyan.withOpacity(0.12)
                      : _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _quality == 'standard' ? _cyan : Colors.white12,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Standard',
                  style: GoogleFonts.inter(
                    color: _quality == 'standard' ? _cyan : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _quality = 'hd'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _quality == 'hd' ? _amber.withOpacity(0.08) : _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _quality == 'hd' ? _amber : Colors.white12,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'HD',
                      style: GoogleFonts.inter(
                        color: _quality == 'hd' ? _amber : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star_rounded,
                      color: _quality == 'hd' ? _amber : Colors.white24,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildStatusBanner() {
    final isError =
        _statusText.toLowerCase().contains('error') ||
        _statusText.toLowerCase().contains('failed') ||
        _statusText.toLowerCase().contains('not exist');
    final color = _isGenerating
        ? _amber
        : isError
        ? Colors.redAccent
        : _green;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          if (_isGenerating)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(color: color, strokeWidth: 2),
            )
          else
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: color,
              size: 16,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusText,
              style: GoogleFonts.inter(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Generated',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withOpacity(0.3)),
            ),
            child: Text(
              'Pollinations · ${(_sizes.firstWhere((s) => s['label'] == _selectedSize)['dim'] as String)}',
              style: GoogleFonts.jetBrainsMono(color: _green, fontSize: 9),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cyan.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: _cyan.withOpacity(0.08),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Image.memory(
            _generatedImage!,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _actionBtn(
              icon: Icons.download_rounded,
              label: 'Save',
              color: _cyan,
              onTap: _saveImage,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionBtn(
              icon: Icons.share_rounded,
              label: 'Share',
              color: _purple,
              onTap: _shareImage,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionBtn(
              icon: Icons.refresh_rounded,
              label: 'Regenerate',
              color: _amber,
              onTap: _generateImage,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildGenerateButton() => Container(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
    decoration: BoxDecoration(
      color: _bg,
      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
    ),
    child: GestureDetector(
      onTap: _isGenerating ? null : _generateImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isGenerating
              ? LinearGradient(
                  colors: [Colors.grey.shade800, Colors.grey.shade700],
                )
              : const LinearGradient(
                  colors: [_cyan, Color(0xFF00C9FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isGenerating
              ? []
              : [
                  BoxShadow(
                    color: _cyan.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: _isGenerating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Generating...',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Generate Image',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );

  Widget _sectionLabel(String title, String sub) => Column(
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
      Text(sub, style: GoogleFonts.inter(color: Colors.white30, fontSize: 10)),
    ],
  );
}
