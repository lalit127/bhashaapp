import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/progress_model.dart';

class StorageService extends GetxService {
  late Box<UserProgress> _progressBox;
  late Box _settingsBox;

  @override
  void onInit() {
    super.onInit();
    _progressBox = Hive.box<UserProgress>('progress');
    _settingsBox = Hive.box('settings');
  }

  // ── Progress ───────────────────────────────────────────────────────────────
  UserProgress getProgress() => _progressBox.get('current') ?? UserProgress();

  Future<void> saveProgress(UserProgress p) async =>
      _progressBox.put('current', p);

  Future<void> addXp(int amount) async {
    final p = getProgress()..addXp(amount);
    await saveProgress(p);
  }

  Future<void> completeLesson(String lessonId) async {
    final p = getProgress();
    if (!p.completedLessons.contains(lessonId)) {
      p.completedLessons.add(lessonId);
      p.totalLessons++;
      p.updateStreak();
      await saveProgress(p);
    }
  }

  // ── Onboarding settings ────────────────────────────────────────────────────
  String? getSelectedLanguage() => _settingsBox.get('selectedLanguage') as String?;
  Future<void> saveSelectedLanguage(String code) =>
      _settingsBox.put('selectedLanguage', code);

  String? getSelectedLevel()    => _settingsBox.get('selectedLevel') as String?;
  Future<void> setSelectedLevel(String level) =>
      _settingsBox.put('selectedLevel', level);

  String? getSelectedGoal()         => _settingsBox.get('userGoal') as String?;
  Future<void> setSelectedGoal(String goal) =>
      _settingsBox.put('userGoal', goal);

  String? getUserGoal() => getSelectedGoal(); // Alias for backward compatibility

  String? getUserOccupation()   => _settingsBox.get('userOccupation') as String?;
  Future<void> saveUserOccupation(String occ) =>
      _settingsBox.put('userOccupation', occ);

  String? getUserName()         => _settingsBox.get('userName') as String?;
  Future<void> saveUserName(String name) =>
      _settingsBox.put('userName', name);

  bool isOnboardingComplete() =>
      _settingsBox.get('onboardingComplete', defaultValue: false) as bool;
  Future<void> setOnboardingComplete() =>
      _settingsBox.put('onboardingComplete', true);

  bool isPackDownloaded(String langCode) =>
      _settingsBox.get('pack_$langCode', defaultValue: false) as bool;
  Future<void> setPackDownloaded(String langCode) =>
      _settingsBox.put('pack_$langCode', true);

  // ── Lesson cache (JSON strings keyed by lessonId) ─────────────────────────
  Future<void> cacheLesson(String lessonId, String json) =>
      _settingsBox.put('lesson_$lessonId', json);
  String? getCachedLesson(String lessonId) =>
      _settingsBox.get('lesson_$lessonId') as String?;
}
