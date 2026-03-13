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

  // ── Skill Progress ─────────────────────────────────────────────────────────
  /// Get progress for a specific skill (returns completed lessons count)
  SkillProgress? getSkillProgress(String skillId) {
    final data = _settingsBox.get('skill_progress_$skillId') as Map?;
    if (data == null) return null;

    return SkillProgress(
      completedLessons: data['completedLessons'] as int? ?? 0,
      totalLessons: data['totalLessons'] as int? ?? 1,
    );
  }

  /// Update skill progress when a lesson is completed
  Future<void> updateSkillProgress(
      String skillId, int completedLessons, int totalLessons) async {
    await _settingsBox.put('skill_progress_$skillId', {
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
    });
  }

  /// Mark a lesson as complete and update the skill progress
  Future<void> completeLessonInSkill(
      String skillId, String lessonId, int totalLessonsInSkill) async {
    // Update global progress
    await completeLesson(lessonId);

    // Update skill-specific progress
    final current = getSkillProgress(skillId);
    final completed = (current?.completedLessons ?? 0) + 1;
    await updateSkillProgress(skillId, completed, totalLessonsInSkill);
  }

  // ── Onboarding settings ────────────────────────────────────────────────────
  String? getSelectedLanguage() =>
      _settingsBox.get('selectedLanguage') as String?;

  Future<void> saveSelectedLanguage(String code) =>
      _settingsBox.put('selectedLanguage', code);

  String? getSelectedLevel() => _settingsBox.get('selectedLevel') as String?;

  Future<void> setSelectedLevel(String level) =>
      _settingsBox.put('selectedLevel', level);

  String? getSelectedGoal() => _settingsBox.get('userGoal') as String?;

  Future<void> setSelectedGoal(String goal) =>
      _settingsBox.put('userGoal', goal);

  String? getUserGoal() =>
      getSelectedGoal(); // Alias for backward compatibility

  String? getUserOccupation() => _settingsBox.get('userOccupation') as String?;

  Future<void> saveUserOccupation(String occ) =>
      _settingsBox.put('userOccupation', occ);

  String? getUserName() => _settingsBox.get('userName') as String?;

  Future<void> saveUserName(String name) => _settingsBox.put('userName', name);

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

// ── Skill Progress Model ───────────────────────────────────────────────────
/// Simple model to track progress within a specific skill
class SkillProgress {
  final int completedLessons;
  final int totalLessons;

  SkillProgress({
    required this.completedLessons,
    required this.totalLessons,
  });

  double get progressPercent =>
      totalLessons > 0 ? completedLessons / totalLessons : 0.0;

  bool get isComplete => completedLessons >= totalLessons;

  Map<String, dynamic> toJson() => {
        'completedLessons': completedLessons,
        'totalLessons': totalLessons,
      };

  factory SkillProgress.fromJson(Map<String, dynamic> json) => SkillProgress(
        completedLessons: json['completedLessons'] as int? ?? 0,
        totalLessons: json['totalLessons'] as int? ?? 1,
      );
}
