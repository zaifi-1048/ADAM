import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LearningTimelineScreen extends StatefulWidget {
  const LearningTimelineScreen({super.key});

  @override
  State<LearningTimelineScreen> createState() => _LearningTimelineScreenState();
}

class _LearningTimelineScreenState extends State<LearningTimelineScreen> {
  bool _isEditing = true;

  static const Color accentCyan = Color(0xFF4FD8EB);
  static const Color bgDark = Color(0xFF0D1117);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const CustomNavBar(),
      backgroundColor: bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF1C2229), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressCard(),
                      const SizedBox(height: 25),
                      Text(
                        "Timeline",
                        style: GoogleFonts.poppins(
                          color: accentCyan,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (_isEditing) ...[
                        _buildTimelineItem(),
                        const SizedBox(height: 15),
                        _buildEditForm(),
                      ] else ...[
                        _buildFullTimeline(),
                      ],
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: GestureDetector(
                          onTap: () => setState(() => _isEditing = true),
                          child: _actionButton(
                            Icons.edit,
                            "Edit Item",
                            const Color(0xFF1C2D35),
                            accentCyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Spanish Basics",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              "Learning • Progress Timeline",
              style: GoogleFonts.jetBrainsMono(color: accentCyan, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: accentCyan.withOpacity(.15),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.green, size: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Spanish Basics",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "A1 goal • 6 weeks • Flashcards + Daily Practice",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _actionButton(
            Icons.push_pin_outlined,
            "Pin",
            Colors.white10,
            Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.circle, color: Colors.orange, size: 12),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Kickoff Session",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Icon(Icons.edit_outlined, color: Colors.white24, size: 18),
            ],
          ),
          SizedBox(height: 6),
          Text(
            "Set learning plan and downloaded",
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            "Duolingo + Anki decks",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            "Done • Mon, 3 Jun 08:00 pm",
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(.35)),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Edit Timeline Entry",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _formField(Icons.title, "Greetings & Introductions"),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _FormField(
                  icon: Icons.calendar_today,
                  text: "Thu, 6 Jun 2025",
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _FormField(icon: Icons.access_time, text: "19:30"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _formField(Icons.notes, "ytidnvnjdnvnc..."),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  Icons.notifications_none,
                  "Notify 30 min before",
                  const Color(0xFF1C222D),
                  Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  Icons.repeat,
                  "Repeat: None",
                  const Color(0xFF1C222D),
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isEditing = false),
                  child: _actionButton(
                    Icons.close,
                    "Cancel",
                    Colors.transparent,
                    Colors.white,
                    showBorder: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isEditing = false),
                  child: _actionButton(
                    Icons.save,
                    "Save Changes",
                    accentCyan,
                    Colors.black,
                    isBold: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullTimeline() {
    return Column(
      children: [
        _timelineNode(
          "Alphabet & Pronunciation",
          "Set learning plan and downloaded",
          "Done • Mon, 3 Jun 08:00 pm",
          Colors.orange,
        ),
        _timelineConnector(),
        _timelineNode(
          "Greetings & Introductions",
          "Set learning plan and downloaded",
          "Next • Mon, 3 Jun 08:00 pm",
          Colors.red,
          showNotify: true,
        ),
      ],
    );
  }

  Widget _timelineNode(
    String title,
    String desc,
    String time,
    Color dotColor, {
    bool showNotify = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, color: dotColor, size: 14),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.white12)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  if (showNotify) ...[
                    const SizedBox(height: 8),
                    _actionButton(
                      Icons.info_outline,
                      "Notify: 30 min before",
                      Colors.white10,
                      accentCyan,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timelineConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      height: 28,
      width: 1,
      color: Colors.white12,
    );
  }

  Widget _formField(IconData icon, String text) {
    return _FormField(icon: icon, text: text);
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color bg,
    Color textColor, {
    bool showBorder = false,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: showBorder ? Border.all(color: Colors.white24) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FormField({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C222D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4FD8EB), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
