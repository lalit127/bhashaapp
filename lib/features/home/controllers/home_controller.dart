// lib/features/home/controllers/home_controller.dart

import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../services/gemini_service.dart';
import '../../auth/controllers/auth_controller.dart';

class HomeController extends GetxController {
  final _repo    = FirestoreRepository();
  final _gemini  = Get.find<GeminiService>();
  final _auth    = Get.find<AuthController>();

  // ── Observables ───────────────────────────────────────────────────────────
  final roadmap          = Rxn<Map<String, dynamic>>();
  final progressList     = <LessonProgress>[].obs;
  final isLoadingRoadmap = false.obs;
  final isLoadingProgress= false.obs;
  final errorMsg         = RxnString();

  // ── Computed ──────────────────────────────────────────────────────────────
  UserModel? get currentUser => _auth.user.value;
  int get totalXp    => currentUser?.totalXp     ?? 0;
  int get streak     => currentUser?.currentStreak ?? 0;
  String get level   => currentUser?.cefrLevel    ?? 'A1';
  String get name    => currentUser?.name         ?? '';

  // Skills from roadmap phases (flat list)
  List<Map<String, dynamic>> get allSkills {
    final phases = roadmap.value?['phases'] as List?;
    if (phases == null) return [];
    return phases.expand((phase) =>
        (phase['skills'] as List? ?? []).cast<Map<String, dynamic>>()).toList();
  }

  // Check if skill is unlocked (based on progress)
  bool isSkillUnlocked(String skillId) {
    // Always unlock skills marked as unlocked in roadmap
    final skill = allSkills.firstWhereOrNull((s) => s['skill_id'] == skillId);
    if (skill?['is_unlocked'] == true) return true;
    // Or if previous skill is completed
    final skills = allSkills;
    final idx = skills.indexWhere((s) => s['skill_id'] == skillId);
    if (idx <= 0) return true;
    final prevId = skills[idx - 1]['skill_id'] as String?;
    if (prevId == null) return true;
    return progressList.any((p) => p.skillId == prevId && p.isCompleted);
  }

  LessonProgress? progressFor(String skillId) =>
      progressList.firstWhereOrNull((p) => p.skillId == skillId);

  @override
  void onInit() {
    super.onInit();
    ever(_auth.user, (_) => _load());
    _load();
  }

  Future<void> _load() async {
    final uid = _auth.uid;
    if (uid.isEmpty) return;
    await Future.wait([
      loadRoadmap(),
      loadProgress(),
    ]);
    // Update streak
    await _repo.updateStreak(uid);
    // Refresh user
    final updated = await _repo.getUser(uid);
    if (updated != null) _auth.user.value = updated;
  }

  Future<void> loadRoadmap() async {
    if (roadmap.value != null) return; // already loaded
    isLoadingRoadmap.value = true;
    errorMsg.value         = null;
    try {
      final u = currentUser;
      if (u == null) return;
      final data = await _gemini.generateRoadmap(
        nativeLanguage:  u.nativeLanguage,
        cefrLevel:   u.cefrLevel,
        goal:        u.goal,
        occupation:  u.occupation,
      );
      roadmap.value = data;
    } catch (e) {
      errorMsg.value = 'Could not load roadmap: $e';
    } finally {
      isLoadingRoadmap.value = false;
    }
  }

  Future<void> loadProgress() async {
    final uid = _auth.uid;
    if (uid.isEmpty) return;
    isLoadingProgress.value = true;
    try {
      final list = await _repo.getAllProgress(uid);
      progressList.assignAll(list);
    } finally {
      isLoadingProgress.value = false;
    }
  }

  Future<void> refreshAll() => _load();

  // ── Called after lesson completion ───────────────────────────────────────
  Future<void> onLessonComplete(
      String skillId, String skillName, int xp, double score) async {
    final uid = _auth.uid;
    if (uid.isEmpty) return;
    await _repo.incrementLesson(uid, skillId, skillName, xp, score);
    await _repo.addXp(uid, xp);
    await loadProgress();
    // Refresh user XP
    final updated = await _repo.getUser(uid);
    if (updated != null) _auth.user.value = updated;
  }

  Future<void> onVoiceSessionComplete(int xp) async {
    final uid = _auth.uid;
    if (uid.isEmpty) return;
    await _repo.addXp(uid, xp);
    final updated = await _repo.getUser(uid);
    if (updated != null) _auth.user.value = updated;
  }
}
