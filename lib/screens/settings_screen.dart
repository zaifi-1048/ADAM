============================================================
PATCH FOR: lib/screens/settings_screen.dart
Only replace the 3 broken _switchRow calls in build()
============================================================

FIND this (Notification toggle):
─────────────────────────────────
_switchRow("Notification", isNotification, (val) async {
                  setState(() => isNotification = val);
                  await _settingsService.setNotifications(val);
                  Get.snackbar(val ? 'Notifications On' : 'Notifications Off', val ? 'You will receive notifications' : 'Notifications disabled', snackPosition: SnackPosition.BOTTOM, backgroundColor: val ? Colors.green.withOpacity(0.8) : Colors.orange.withOpacity(0.8), colorText: Colors.white, duration: const Duration(seconds: 2));
                }),

REPLACE WITH:
─────────────────────────────────
_switchRow("Notification", isNotification, (val) async {
  setState(() => isNotification = val);
  await _settingsService.setNotifications(val);
  Get.snackbar(
    val ? 'Notifications On' : 'Notifications Off',
    val ? 'You will receive notifications' : 'Notifications disabled',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: val ? Colors.green.withOpacity(0.8) : Colors.orange.withOpacity(0.8),
    colorText: Colors.white,
    duration: const Duration(seconds: 2),
  );
}),

============================================================

FIND this (Learning Mode toggle):
─────────────────────────────────
_switchRow("Learning Mode", isLearningMode, (val) async {
                  setState(() => isLearningMode = val);
                  await _settingsService.setLearningMode(val);
                  Get.snackbar(val ? 'Learning Mode On' : 'Learning Mode Off', val ? 'ADAM will learn from your conversations' : 'Learning mode disabled', snackPosition: SnackPosition.BOTTOM, backgroundColor: val ? Colors.green.withOpacity(0.8) : Colors.orange.withOpacity(0.8), colorText: Colors.white, duration: const Duration(seconds: 2));
                }),

REPLACE WITH:
─────────────────────────────────
_switchRow("Learning Mode", isLearningMode, (val) async {
  setState(() => isLearningMode = val);
  await _settingsService.setLearningMode(val);
  Get.snackbar(
    val ? 'Learning Mode On' : 'Learning Mode Off',
    val ? 'ADAM will learn from your conversations' : 'Learning mode disabled',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: val ? Colors.green.withOpacity(0.8) : Colors.orange.withOpacity(0.8),
    colorText: Colors.white,
    duration: const Duration(seconds: 2),
  );
}),

============================================================

FIND this (Data Encryption toggle):
─────────────────────────────────
_switchRow("Data Encryption", isDataEncryption, (val) async {
                  setState(() => isDataEncryption = val);
                  await _settingsService.setDataEncryption(val);
                  Get.snackbar(val ? 'Encryption On' : 'Encryption Off', val ? 'Your data is encrypted' : 'Encryption disabled', snackPosition: SnackPosition.BOTTOM, backgroundColor: val ? Colors.green.withOpacity(0.8) : Colors.orange.withOpacity(0.8), colorText: Colors.white, duration: const Duration(seconds: 2));
                }),

REPLACE WITH:
─────────────────────────────────
_switchRow("Data Encryption", isDataEncryption, (val) async {
  setState(() => isDataEncryption = val);
  await _settingsService.setDataEncryption(val);
  Get.snackbar(
    val ? 'Encryption On' : 'Encryption Off',
    val ? 'Your data is encrypted' : 'Encryption disabled',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: val ? Colors.green.withOpacity(0.8) : Colors.orange.withOpacity(0.8),
    colorText: Colors.white,
    duration: const Duration(seconds: 2),
  );
}),

============================================================

ALSO fix _loadSettings() — add the 3 new fields:
─────────────────────────────────
FIND:
  Future<void> _loadSettings() async {
    await _settingsService.loadSettings();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSaveHistory    = _settingsService.saveHistory;
      isNotification   = _settingsService.notifications;
      isLearningMode   = _settingsService.learningMode;
      isDataEncryption = _settingsService.dataEncryption;
      isWakeWord       = prefs.getBool('wake_word_enabled') ?? false;
    });
  }

REPLACE WITH:
  Future<void> _loadSettings() async {
    await _settingsService.loadSettings();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSaveHistory    = _settingsService.saveHistory;
      isNotification   = _settingsService.notifications;
      isLearningMode   = _settingsService.learningMode;
      isDataEncryption = _settingsService.dataEncryption;
      isWakeWord       = prefs.getBool('wake_word_enabled') ?? false;
    });
  }
