import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:ai_voice_chat/firebase_options.dart';
import 'package:ai_voice_chat/routes/app_routes.dart';
import 'package:ai_voice_chat/controller/voice_controller.dart';
import 'package:ai_voice_chat/services/wake_word_service.dart';
import 'package:ai_voice_chat/services/voice_reminder_service.dart';
import 'package:ai_voice_chat/services/background_reminder_service.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initializeNotifications() async {
  tz.initializeTimeZones();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      final payload = details.payload;
      if (payload != null && payload.contains('|||')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          VoiceReminderService.instance.speakFromNotificationTap(payload);
        });
      }
    },
  );
  final plugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await plugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'adam_wake_word_ch',
      'ADAM Wake Word',
      description: 'ADAM listens for Hey ADAM',
      importance: Importance.low,
    ),
  );
  await plugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      'adam_reminders_ch',
      'ADAM Reminders',
      description: 'Task and reminder alerts from ADAM',
      importance: Importance.high,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeNotifications();
  await Permission.notification.request();
  await Permission.scheduleExactAlarm.request();
  Get.put(VoiceController());
  await VoiceReminderService.instance.init(flutterLocalNotificationsPlugin);
  await BackgroundReminderService.init();
  await WakeWordService.instance.initialize(navigatorKey);
  final prefs = await SharedPreferences.getInstance();
  final wakeWordEnabled = prefs.getBool('wake_word_enabled') ?? false;
  if (wakeWordEnabled) {
    WakeWordService.instance.enable();
  }

  // Handle app launched from a notification tap (killed state)
  final launchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp == true) {
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null && payload.contains('|||')) {
      Future.delayed(const Duration(seconds: 2), () {
        VoiceReminderService.instance.speakFromNotificationTap(payload);
      });
    }
  }

  runApp(const MyApp());
}

// ── StatefulWidget to observe app lifecycle ──
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Auto-restart ADAM when app comes back to foreground ──
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      debugPrint('ADAM: App resumed — restarting listening');
      Future.delayed(const Duration(milliseconds: 1200), () {
        WakeWordService.instance.onAppResumed();
      });
    } else if (appState == AppLifecycleState.paused) {
      debugPrint('ADAM: App paused/minimized');
      WakeWordService.instance.onAppPaused();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ADAM AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      navigatorKey: navigatorKey,
    );
  }
}
