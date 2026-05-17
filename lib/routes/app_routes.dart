import 'package:ai_voice_chat/bindings/dashboard_binding.dart';
import 'package:ai_voice_chat/screens/chat/chat.dart';
import 'package:ai_voice_chat/screens/chat/image_gallery_screen.dart';
import 'package:ai_voice_chat/screens/chat/payment/subscription.dart';
import 'package:ai_voice_chat/screens/chat/translation_screen.dart';
import 'package:ai_voice_chat/screens/memory/memory.dart';
import 'package:ai_voice_chat/screens/remote/ac_remote/ac_remote.dart';
import 'package:ai_voice_chat/screens/remote/selectremote.dart';
import 'package:ai_voice_chat/screens/remote/tv_remote/connecttvscan.dart';
import 'package:ai_voice_chat/screens/dashboard.dart';
import 'package:ai_voice_chat/screens/onboarding.dart';
import 'package:ai_voice_chat/screens/remote/tv_remote/tvremotescreen.dart';
import 'package:ai_voice_chat/screens/settings.dart';
import 'package:ai_voice_chat/screens/splash/splash.dart';
import 'package:ai_voice_chat/screens/tasks/task_manager_screen.dart';
import 'package:ai_voice_chat/screens/voice/ai_voice_chat_screen.dart';
import 'package:ai_voice_chat/screens/welcome.dart';
import 'package:ai_voice_chat/auth/login.dart';
import 'package:ai_voice_chat/auth/signup.dart';
import 'package:ai_voice_chat/auth/forget.dart';
import 'package:get/get.dart';
import '../bindings/welcome_binding.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String dashboard = '/dashboard';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String tvremote = '/tv-remote';
  static const String acremote = '/acremote';
  static const String connecttv = '/connecttv';
  static const String scantv = '/scantv';
  static const String selectremote = '/selectremote';
  static const String chat = '/chat';
  static const String premium = '/premium';
  static const String memory = '/memory';
  static const String settings = '/settings';
  static const String translation = '/translation';
  static const String tasks = '/tasks';
  static const String voice = '/voice';
  static const String imageGallery = '/image-gallery';

  static final List<GetPage> pages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(
      name: welcome,
      page: () => const WelcomeScreen(),
      binding: WelcomeBinding(),
    ),
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: signup, page: () => const SignupScreen()),
    GetPage(
      name: dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
    ),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: scantv, page: () => const ConnectTVScanScreen()),
    GetPage(name: tvremote, page: () => const TvRemoteScreen()),
    GetPage(
      name: acremote,
      page: () => const AcRemoteScreen(brand: ''),
    ),
    GetPage(name: connecttv, page: () => const ConnectTVScanScreen()),
    GetPage(name: selectremote, page: () => const SelectRemoteScreen()),
    GetPage(
      name: chat,
      page: () {
        final args = Get.arguments;
        final sessionId = args is Map ? args['sessionId'] as String? : null;
        return ChatScreen(initialSessionId: sessionId);
      },
    ),
    GetPage(
      name: voice,
      page: () {
        final args = Get.arguments;
        final sessionId = args is Map ? args['sessionId'] as String? : null;
        return VoiceChatScreen(initialSessionId: sessionId);
      },
    ),
    GetPage(
      name: translation,
      page: () {
        final args = Get.arguments;
        final sessionId = args is Map ? args['sessionId'] as String? : null;
        return TranslationScreen(initialSessionId: sessionId);
      },
    ),
    GetPage(name: premium, page: () => const SubscriptionScreen()),
    GetPage(name: memory, page: () => const MemoryScreen()),
    GetPage(name: settings, page: () => const SettingsScreen()),
    GetPage(name: tasks, page: () => const TaskManagerScreen()),
    GetPage(name: imageGallery, page: () => const ImageGalleryScreen()),
  ];
}


