import 'dart:convert';
import 'dart:typed_data';
import 'package:ai_voice_chat/services/wake_word_service.dart';
import 'package:ai_voice_chat/widgets/customnavbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_voice_chat/routes/app_routes.dart';
import 'package:ai_voice_chat/controller/voice_controller.dart';
import 'package:ai_voice_chat/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isNotification = true;
  bool isWakeWord = false;
  bool isLearningMode = true;
  bool isSaveHistory = true;
  bool isDataEncryption = true;
  bool _isUploadingPhoto = false;
  String? _photoBase64;

  final _settingsService = SettingsService.to;
  User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPhotoFromFirestore();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.loadSettings();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSaveHistory = _settingsService.saveHistory;
      isWakeWord = prefs.getBool('wake_word_enabled') ?? false;
    });
  }

  Future<void> _loadPhotoFromFirestore() async {
    final uid = _user?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data()?['photoBase64'] != null) {
        setState(() => _photoBase64 = doc.data()!['photoBase64'] as String);
      }
    } catch (_) {}
  }

  String get _initials {
    if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
      final parts = _user!.displayName!.trim().split(' ');
      if (parts.length >= 2)
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return parts[0][0].toUpperCase();
    }
    return _user?.email?[0].toUpperCase() ?? 'U';
  }

  String get _displayName {
    if (_user?.displayName != null && _user!.displayName!.isNotEmpty)
      return _user!.displayName!;
    return _user?.email?.split('@')[0] ?? 'User';
  }

  String get _email => _user?.email ?? 'No email';

  Future<void> _editName() async {
    final controller = TextEditingController(text: _displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2229),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0B0D0F),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
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
    if (newName != null && newName.isNotEmpty && newName != _displayName) {
      try {
        await _user?.updateDisplayName(newName);
        await _user?.reload();
        setState(() => _user = FirebaseAuth.instance.currentUser);
        Get.snackbar(
          'Success',
          'Name updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Could not update name.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2229),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Profile Photo',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Choose photo source',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text(
              'Camera',
              style: TextStyle(color: Color(0xFF4FD8EB)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text(
              'Gallery',
              style: TextStyle(color: Color(0xFF4FD8EB)),
            ),
          ),
        ],
      ),
    );
    if (source == null) return;
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 300,
    );
    if (pickedFile == null) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final uid = _user?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'photoBase64': base64Image,
      }, SetOptions(merge: true));
      setState(() => _photoBase64 = base64Image);
      Get.snackbar(
        'Success',
        'Profile photo updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not upload photo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  Widget _buildAvatar() {
    const Color accentCyan = Color(0xFF4FD8EB);
    Widget avatarChild;
    if (_isUploadingPhoto) {
      avatarChild = const CircularProgressIndicator(
        color: Colors.black,
        strokeWidth: 2,
      );
    } else if (_photoBase64 != null) {
      try {
        final bytes = base64Decode(_photoBase64!.split(',').last);
        avatarChild = ClipOval(
          child: Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover),
        );
      } catch (_) {
        avatarChild = Text(
          _initials,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        );
      }
    } else if (_user?.photoURL != null && _user!.photoURL!.isNotEmpty) {
      avatarChild = ClipOval(
        child: Image.network(
          _user!.photoURL!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(
            _initials,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      );
    } else {
      avatarChild = Text(
        _initials,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      );
    }
    return GestureDetector(
      onTap: _changeProfilePhoto,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: accentCyan,
            child: avatarChild,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF4FD8EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.black,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2229),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      WakeWordService.instance.disable();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wake_word_enabled', false);
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed(AppRoutes.welcome);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2229),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: const Text(
          'This will permanently delete your account and all data.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        WakeWordService.instance.disable();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('wake_word_enabled', false);
        await _user?.delete();
        Get.offAllNamed(AppRoutes.welcome);
      } on FirebaseAuthException catch (e) {
        Get.snackbar(
          'Error',
          e.code == 'requires-recent-login'
              ? 'Please sign out and sign in again.'
              : e.message ?? 'Could not delete account.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  Future<bool> _deleteAllSessionsFromFirestore() async {
    final uid = _user?.uid;
    if (uid == null) return false;
    try {
      final sessionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sessions');
      final sessions = await sessionsRef.get();
      if (sessions.docs.isEmpty) return true;
      for (final session in sessions.docs) {
        final messages = await session.reference.collection('messages').get();
        for (final msg in messages.docs) await msg.reference.delete();
        await session.reference.delete();
      }
      return true;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  Future<void> _clearHistory() async {
    final uid = _user?.uid;
    if (uid == null) {
      Get.snackbar(
        'Error',
        'No user logged in',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2229),
        title: const Text(
          'Clear All History',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete ALL your chat, voice and translation history.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF4FD8EB))),
      barrierDismissible: false,
    );
    final success = await _deleteAllSessionsFromFirestore();
    if (Get.isDialogOpen == true) Get.back();
    Get.snackbar(
      success ? 'Done' : 'Error',
      success ? 'All history cleared' : 'Could not clear history.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: success
          ? Colors.green.withOpacity(0.8)
          : Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _deleteSingleSession(DocumentSnapshot doc, String title) async {
    try {
      final messages = await doc.reference.collection('messages').get();
      for (final msg in messages.docs) await msg.reference.delete();
      await doc.reference.delete();
      Get.snackbar(
        'Deleted',
        '"$title" removed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not delete: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void _showManageHistory() {
    final uid = _user?.uid;
    if (uid == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Manage History",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Swipe left to delete",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('sessions')
                      .orderBy('updatedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4FD8EB),
                        ),
                      );
                    final sessions = snapshot.data?.docs ?? [];
                    if (sessions.isEmpty)
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              color: Colors.white24,
                              size: 60,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No history found",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final doc = sessions[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] as String? ?? 'New Chat';
                        final type = data['type'] as String? ?? 'chat';
                        final msgCount = data['messageCount'] as int? ?? 0;
                        final updatedAt = data['updatedAt'] as Timestamp?;
                        final date = updatedAt != null
                            ? _formatDate(updatedAt.toDate())
                            : '';
                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                Text(
                                  "Delete",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (direction) async =>
                              await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1C2229),
                                  title: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Text(
                                    'Delete "$title"?',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          onDismissed: (_) async =>
                              await _deleteSingleSession(doc, title),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1C2229),
                              child: Icon(
                                _getSessionIcon(type),
                                color: _getSessionColor(type),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '$msgCount messages  •  $date',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.swipe_left,
                              color: Colors.white24,
                              size: 16,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _clearHistory();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_sweep,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Clear All History",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getSessionIcon(String? type) {
    switch (type) {
      case 'voice':
        return Icons.mic;
      case 'translation':
        return Icons.translate;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  Color _getSessionColor(String? type) {
    switch (type) {
      case 'voice':
        return Colors.greenAccent;
      case 'translation':
        return Colors.orangeAccent;
      default:
        return const Color(0xFF4FD8EB);
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2229),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF4FD8EB))),
          ),
        ],
      ),
    );
  }

  void _showVoicePickerDialog() {
    final ctrl = VoiceController.to;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Obx(
        () => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Select Voice Type",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await ctrl.setMale();
                        Navigator.pop(ctx);
                        Get.snackbar(
                          'Male Voice Selected',
                          'ADAM will now speak in male voice',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(
                            0xFF4FD8EB,
                          ).withOpacity(0.8),
                          colorText: Colors.black,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: ctrl.isMaleVoice.value
                              ? const Color(0xFF4FD8EB).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ctrl.isMaleVoice.value
                                ? const Color(0xFF4FD8EB)
                                : Colors.white24,
                            width: ctrl.isMaleVoice.value ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.man,
                              color: ctrl.isMaleVoice.value
                                  ? const Color(0xFF4FD8EB)
                                  : Colors.white54,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Male",
                              style: TextStyle(
                                color: ctrl.isMaleVoice.value
                                    ? const Color(0xFF4FD8EB)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Deep voice",
                              style: TextStyle(
                                color: ctrl.isMaleVoice.value
                                    ? const Color(0xFF4FD8EB).withOpacity(0.7)
                                    : Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            if (ctrl.isMaleVoice.value) ...[
                              const SizedBox(height: 8),
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF4FD8EB),
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await ctrl.setFemale();
                        Navigator.pop(ctx);
                        Get.snackbar(
                          'Female Voice Selected',
                          'ADAM will now speak in female voice',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.pinkAccent.withOpacity(0.8),
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: !ctrl.isMaleVoice.value
                              ? Colors.pinkAccent.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !ctrl.isMaleVoice.value
                                ? Colors.pinkAccent
                                : Colors.white24,
                            width: !ctrl.isMaleVoice.value ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.woman,
                              color: !ctrl.isMaleVoice.value
                                  ? Colors.pinkAccent
                                  : Colors.white54,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Female",
                              style: TextStyle(
                                color: !ctrl.isMaleVoice.value
                                    ? Colors.pinkAccent
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "High voice",
                              style: TextStyle(
                                color: !ctrl.isMaleVoice.value
                                    ? Colors.pinkAccent.withOpacity(0.7)
                                    : Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            if (!ctrl.isMaleVoice.value) ...[
                              const SizedBox(height: 8),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.pinkAccent,
                                size: 20,
                              ),
                            ],
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
    );
  }

  Future<void> _toggleWakeWord(bool val) async {
    setState(() => isWakeWord = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wake_word_enabled', val);
    if (val) {
      WakeWordService.instance.enable();
      Get.snackbar(
        'Wake Word Enabled',
        'Say "Hey ADAM", "Hello ADAM", "OK ADAM" or "ADAM Listen"',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4FD8EB).withOpacity(0.9),
        colorText: Colors.black,
        duration: const Duration(seconds: 4),
      );
    } else {
      WakeWordService.instance.disable();
      Get.snackbar(
        'Wake Word Disabled',
        'ADAM will no longer listen in background',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accentCyan = Color(0xFF4FD8EB);
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const CustomNavBar(),
      body: Container(
        // ── ONLY CHANGE: Background now matches dashboard ──
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E1A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: accentCyan,
                        size: 20,
                      ),
                    ),
                    const Text(
                      "Settings",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    "Display  •  Adding Device",
                    style: GoogleFonts.jetBrainsMono(
                      color: accentCyan,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 12),
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _editName,
                        icon: const Icon(
                          Icons.edit,
                          color: accentCyan,
                          size: 16,
                        ),
                        label: const Text(
                          'Edit Name',
                          style: TextStyle(color: accentCyan),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: accentCyan),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                _sectionHeader("ASSISTANT"),
                _settingRow("Name", "ADAM"),
                InkWell(
                  onTap: _showVoicePickerDialog,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Voice",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Obx(
                          () => Row(
                            children: [
                              Icon(
                                VoiceController.to.isMaleVoice.value
                                    ? Icons.man
                                    : Icons.woman,
                                color: VoiceController.to.isMaleVoice.value
                                    ? accentCyan
                                    : Colors.pinkAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                VoiceController.to.voiceLabel,
                                style: TextStyle(
                                  color: VoiceController.to.isMaleVoice.value
                                      ? accentCyan
                                      : Colors.pinkAccent,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _settingRow("Style", "Friendly"),
                const Divider(color: Colors.white10, height: 40),
                _sectionHeader("PREFERENCES"),
                _switchRow(
                  "Notification",
                  isNotification,
                  (val) => setState(() => isNotification = val),
                ),
                _switchRow("Wake Word", isWakeWord, _toggleWakeWord),
                _switchRow(
                  "Learning Mode",
                  isLearningMode,
                  (val) => setState(() => isLearningMode = val),
                ),
                const Divider(color: Colors.white10, height: 40),
                _sectionHeader("PRIVACY"),
                _switchRow("Save History", isSaveHistory, (val) async {
                  setState(() => isSaveHistory = val);
                  await _settingsService.setSaveHistory(val);
                  Get.snackbar(
                    val ? 'History Enabled' : 'History Disabled',
                    val
                        ? 'Your chats will now be saved'
                        : 'New chats will not be saved',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: val
                        ? Colors.green.withOpacity(0.8)
                        : Colors.orange.withOpacity(0.8),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                }),
                _switchRow(
                  "Data Encryption",
                  isDataEncryption,
                  (val) => setState(() => isDataEncryption = val),
                ),
                _actionRow(
                  "Manage History",
                  onTap: _showManageHistory,
                  icon: Icons.history,
                ),
                _actionRow(
                  "Clear All History",
                  onTap: _clearHistory,
                  isDestructive: true,
                  icon: Icons.delete_sweep,
                ),
                const SizedBox(height: 30),
                _sectionHeader("ACCOUNT"),
                _actionRow(
                  "Help & Support",
                  onTap: () => _showInfoDialog(
                    'Help & Support',
                    'For support, contact us at:\nsupport@adamai.com',
                  ),
                ),
                _actionRow(
                  "Terms of Service",
                  onTap: () => _showInfoDialog(
                    'Terms of Service',
                    'By using ADAM AI, you agree to our terms of service.',
                  ),
                ),
                _actionRow(
                  "Privacy Policy",
                  onTap: () => _showInfoDialog(
                    'Privacy Policy',
                    'ADAM AI respects your privacy. We do not sell your data.',
                  ),
                ),
                _actionRow("Sign Out", onTap: _signOut),
                _actionRow(
                  "Delete Account",
                  onTap: _deleteAccount,
                  isDestructive: true,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: GoogleFonts.jetBrainsMono(
        color: Colors.grey,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _settingRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text(value, style: const TextStyle(color: Colors.grey, fontSize: 16)),
      ],
    ),
  );

  Widget _switchRow(String label, bool value, Function(bool) onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF4FD8EB),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[800],
            ),
          ],
        ),
      );

  Widget _actionRow(
    String label, {
    required VoidCallback onTap,
    bool isDestructive = false,
    IconData? icon,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isDestructive ? Colors.redAccent : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isDestructive ? Colors.redAccent : Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (!isDestructive)
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        ],
      ),
    ),
  );
}
