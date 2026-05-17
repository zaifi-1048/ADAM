import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();
  static SettingsService get to => _instance;

  bool _saveHistory = true;
  bool _notifications = true;
  bool _learningMode = true;
  bool _dataEncryption = true;
  bool _initialized = false;

  bool get saveHistory => _saveHistory;
  bool get notifications => _notifications;
  bool get learningMode => _learningMode;
  bool get dataEncryption => _dataEncryption;

  Future<void> init() async {
    if (_initialized) return;
    await loadSettings();
    _initialized = true;
  }

  Future<void> loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        _saveHistory = data['saveHistory'] as bool? ?? true;
        _notifications = data['notifications'] as bool? ?? true;
        _learningMode = data['learningMode'] as bool? ?? true;
        _dataEncryption = data['dataEncryption'] as bool? ?? true;
      }
    } catch (e) {
      // keep defaults
    }
  }

  Future<void> setSaveHistory(bool value) async {
    _saveHistory = value;
    await _save({'saveHistory': value});
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    await _save({'notifications': value});
  }

  Future<void> setLearningMode(bool value) async {
    _learningMode = value;
    await _save({'learningMode': value});
  }

  Future<void> setDataEncryption(bool value) async {
    _dataEncryption = value;
    await _save({'dataEncryption': value});
  }

  Future<void> _save(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      // revert handled by caller
    }
  }
}
