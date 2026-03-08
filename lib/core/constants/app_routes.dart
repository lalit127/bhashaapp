import 'package:get/get.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/onboarding/presentation/screens/language_select_screen.dart';
import '../../features/onboarding/presentation/screens/level_select_screen.dart';
import '../../features/onboarding/presentation/screens/goal_select_screen.dart';
import '../../features/onboarding/presentation/screens/pack_download_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/skill_tree/presentation/screens/skill_tree_screen.dart';
import '../../features/lesson_engine/presentation/lesson_screen.dart';
import '../../features/ai_tutor/presentation/screens/ai_chat_screen.dart';
import '../../features/ai_tutor/presentation/screens/pronunciation_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/gamification/presentation/league_screen.dart';
import '../../features/subscription/paywall_screen.dart';

class AppRoutes {
  static const String welcome        = '/';
  static const String languageSelect = '/language-select';
  static const String levelSelect    = '/level-select';
  static const String goalSelect     = '/goal-select';
  static const String packDownload   = '/pack-download';
  static const String home           = '/home';
  static const String skillTree      = '/skill-tree';
  static const String lesson         = '/lesson';
  static const String aiChat         = '/ai-chat';
  static const String pronunciation  = '/pronunciation';
  static const String grammarExplain = '/grammar-explain';
  static const String progress       = '/progress';
  static const String league         = '/league';
  static const String paywall        = '/paywall';

  static final List<GetPage> pages = [
    GetPage(name: welcome,        page: () => const WelcomeScreen()),
    GetPage(name: languageSelect, page: () => const LanguageSelectScreen()),
    GetPage(name: levelSelect,    page: () => const LevelSelectScreen()),
    // GetPage(name: goalSelect,     page: () => const level_select_screen()),
    GetPage(name: packDownload,   page: () => const PackDownloadScreen()),
    GetPage(name: home,           page: () => const HomeScreen()),
    GetPage(name: skillTree,      page: () => const SkillTreeScreen()),
    GetPage(name: lesson,         page: () => const LessonScreen()),
    GetPage(name: aiChat,         page: () => const AiChatScreen()),
    GetPage(name: pronunciation,  page: () => const PronunciationScreen()),
    GetPage(name: progress,       page: () => const ProgressScreen()),
    GetPage(name: league,         page: () => const LeagueScreen()),
    GetPage(name: paywall,        page: () => const PaywallScreen()),
  ];
}
