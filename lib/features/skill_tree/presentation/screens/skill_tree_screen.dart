import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/models/lesson_model.dart';

// ── Controller ─────────────────────────────────────────────────────────────────
class SkillTreeController extends GetxController {
  final _api     = Get.find<ApiService>();
  final _storage = Get.find<StorageService>();

  final roadmap  = Rxn<RoadmapModel>();
  final loading  = true.obs;
  final errMsg   = RxnString();
  final stageIdx = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    errMsg.value  = null;
    final result = await _api.getRoadmap(
      nativeLanguage: _storage.getSelectedLanguage() ?? 'hindi',
      goal:           _storage.getUserGoal()       ?? 'daily',
      occupation:     _storage.getUserOccupation() ?? 'student',
      currentLevel:   _storage.getSelectedLevel()  ?? 'A1',
    );
    if (result != null) {
      roadmap.value = result;
    } else {
      errMsg.value = _api.error.value ?? 'Roadmap load nahi hua';
    }
    loading.value = false;
  }

  int get userXp => _storage.getProgress().xp;

  bool isSkillUnlocked(SkillNode skill) => userXp >= skill.xpRequired;

  void tapSkill(SkillNode skill) {
    if (!isSkillUnlocked(skill)) {
      Get.snackbar(
        '🔒 Locked',
        '${skill.xpRequired} XP chahiye — abhi ${userXp} XP hai',
        backgroundColor: AppColors.bgWhite,
        colorText: AppColors.textPrimary,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    if (skill.requiresPro) {
      Get.toNamed(AppRoutes.paywall, arguments: {'trigger': 'skill_tree'});
      return;
    }
    // Show skill detail bottom sheet, then start lesson
    _showSkillDetail(skill);
  }

  void _showSkillDetail(SkillNode skill) {
    Get.bottomSheet(
      _SkillDetailSheet(skill: skill, ctrl: this),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void startLesson(SkillNode skill) {
    Get.back();
    Get.toNamed(AppRoutes.lesson, arguments: {
      'skillId':   skill.skillId,
      'skillName': skill.skillNameEnglish,
      'lessonNum': 1,
      'cefrLevel': _storage.getSelectedLevel() ?? 'A1',
    });
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class SkillTreeScreen extends StatelessWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SkillTreeController());
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Obx(() {
        if (ctrl.loading.value) return const _Loading();
        if (ctrl.errMsg.value != null)
          return _ErrorView(msg: ctrl.errMsg.value!, onRetry: ctrl._load);
        return _TreeBody(ctrl: ctrl);
      }),
    );
  }
}

class _TreeBody extends StatelessWidget {
  final SkillTreeController ctrl;
  const _TreeBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final rm = ctrl.roadmap.value!;
    return SafeArea(child: Column(children: [
      // Header
      Container(
        color: AppColors.bgWhite,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          GestureDetector(onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rm.tagline, style: const TextStyle(
              fontSize: 12, color: AppColors.textMuted, fontFamily: 'Nunito')),
            Text(rm.taglineEnglish, style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w900,
              color: AppColors.textPrimary, fontFamily: 'Nunito')),
          ])),
          // XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⚡', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('${ctrl.userXp} XP', style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.gold, fontFamily: 'Nunito')),
            ])),
        ])),
      // Stage tabs
      Obx(() => Container(
        color: AppColors.bgWhite,
        child: SingleChildScrollView(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: rm.stages.asMap().entries.map((e) {
            final active = ctrl.stageIdx.value == e.key;
            final stage  = e.value;
            final color  = _hex(stage.colorHex);
            return GestureDetector(
              onTap: () => ctrl.stageIdx.value = e.key,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? color.withOpacity(0.15) : AppColors.bgSection,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? color : AppColors.border,
                    width: active ? 2 : 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(stage.iconEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(stage.stageNameEnglish, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                    color: active ? color : AppColors.textMuted)),
                  if (stage.requiresPro) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(6)),
                      child: const Text('PRO', style: TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white))),
                  ],
                ])));
          }).toList())))),
      const Divider(height: 1, color: AppColors.border),
      // Skill tree for selected stage
      Expanded(child: Obx(() {
        final stage = rm.stages[ctrl.stageIdx.value];
        return _StageTree(stage: stage, ctrl: ctrl);
      })),
    ]));
  }
}

class _StageTree extends StatelessWidget {
  final RoadmapStage stage;
  final SkillTreeController ctrl;
  const _StageTree({required this.stage, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final canvasH = math.max(constraints.maxHeight, stage.skills.length * 160.0);
      return SingleChildScrollView(
        child: SizedBox(height: canvasH, child: Stack(children: [
          // Paths
          CustomPaint(
            size: Size(w, canvasH),
            painter: _PathPainter(skills: stage.skills, ctrl: ctrl, canvasH: canvasH, w: w)),
          // Nodes
          ...stage.skills.map((skill) {
            final x = skill.positionX * w;
            final y = skill.positionY * canvasH;
            return Positioned(
              left: x - 40, top: y - 40,
              child: _SkillNode(skill: skill, ctrl: ctrl));
          }),
          // Stage info banner at bottom
          Positioned(left: 0, right: 0, bottom: 0,
            child: _StageBanner(stage: stage)),
        ])));
    });
  }
}

class _PathPainter extends CustomPainter {
  final List<SkillNode> skills;
  final SkillTreeController ctrl;
  final double canvasH, w;
  const _PathPainter({required this.skills, required this.ctrl, required this.canvasH, required this.w});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < skills.length - 1; i++) {
      final from = skills[i], to = skills[i + 1];
      final start = Offset(from.positionX * w, from.positionY * canvasH);
      final end   = Offset(to.positionX * w, to.positionY * canvasH);
      final bothUnlocked = ctrl.isSkillUnlocked(from) && ctrl.isSkillUnlocked(to);

      final paint = Paint()
        ..color = bothUnlocked ? AppColors.primary.withOpacity(0.5) : AppColors.border
        ..strokeWidth = bothUnlocked ? 3.5 : 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(mid.dx + 20, mid.dy, end.dx, end.dy);

      if (!bothUnlocked) _dashed(canvas, path, paint);
      else canvas.drawPath(path, paint);
    }
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 8, m.length)), paint);
        d += 16;
      }
    }
  }

  @override bool shouldRepaint(_) => true;
}

class _SkillNode extends StatelessWidget {
  final SkillNode skill;
  final SkillTreeController ctrl;
  const _SkillNode({required this.skill, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final unlocked = ctrl.isSkillUnlocked(skill);
    final color    = _hex(skill.colorHex);
    return GestureDetector(
      onTap: () => ctrl.tapSkill(skill),
      child: SizedBox(width: 80, height: 100, child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked ? color.withOpacity(0.15) : AppColors.bgSection,
              border: Border.all(
                color: unlocked ? color : AppColors.border,
                width: unlocked ? 3 : 2),
              boxShadow: unlocked ? [BoxShadow(
                color: color.withOpacity(0.35), blurRadius: 12,
                offset: const Offset(0, 5))] : []),
            child: Stack(alignment: Alignment.center, children: [
              Text(skill.iconEmoji, style: TextStyle(
                fontSize: 28, color: unlocked ? null : Colors.grey)),
              if (!unlocked)
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.35)),
                  child: const Icon(Icons.lock_rounded, color: Colors.white54, size: 24)),
              if (skill.requiresPro && unlocked)
                Positioned(top: 2, right: 2,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
                    child: const Center(child: Text('★', style: TextStyle(
                      fontSize: 10, color: Colors.white))))),
            ])),
          const SizedBox(height: 6),
          Text(skill.skillName, maxLines: 2, textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
              color: unlocked ? AppColors.textPrimary : AppColors.textMuted)),
        ],
      )),
    );
  }
}

class _StageBanner extends StatelessWidget {
  final RoadmapStage stage;
  const _StageBanner({required this.stage});
  @override
  Widget build(BuildContext context) {
    final color = _hex(stage.colorHex);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(stage.iconEmoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(stage.stageNameEnglish, style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w900,
            color: color, fontFamily: 'Nunito'))),
          Text('~${stage.estimatedDays} days', style: const TextStyle(
            fontSize: 11, color: AppColors.textMuted, fontFamily: 'Nunito')),
        ]),
        const SizedBox(height: 8),
        ...stage.whatYouLearn.take(2).map((w) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Icon(Icons.check_circle_outline, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(w, style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Nunito'))),
          ]))),
      ]));
  }
}

class _SkillDetailSheet extends StatelessWidget {
  final SkillNode skill;
  final SkillTreeController ctrl;
  const _SkillDetailSheet({required this.skill, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final color = _hex(skill.colorHex);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 48, height: 4, margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Row(children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.4))),
            child: Center(child: Text(skill.iconEmoji, style: const TextStyle(fontSize: 28)))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(skill.skillName, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900,
              color: AppColors.textPrimary, fontFamily: 'Nunito')),
            Text('${skill.totalLessons} lessons • ${skill.vocabularyCount} words',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Nunito')),
          ])),
        ]),
        const SizedBox(height: 16),
        if (skill.realLifeScenario.isNotEmpty)
          _SheetCard(color: color, icon: '📍', title: 'Real situation:', body: skill.realLifeScenario),
        const SizedBox(height: 10),
        if (skill.confidentWith.isNotEmpty)
          _SheetCard(color: AppColors.success, icon: '✅', title: 'After this skill:', body: skill.confidentWith),
        const SizedBox(height: 10),
        if (skill.keyPhrases.isNotEmpty) ...[
          const Align(alignment: Alignment.centerLeft, child: Text('Key Phrases:', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary, fontFamily: 'Nunito'))),
          const SizedBox(height: 8),
          ...skill.keyPhrases.take(2).map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.bgPage, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.english, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary, fontFamily: 'Nunito')),
                Text(p.native, style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted, fontFamily: 'Nunito')),
              ])),
              if (p.neverSay.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('Not: ${p.neverSay}', style: const TextStyle(
                    fontSize: 10, color: AppColors.error,
                    fontFamily: 'Nunito', fontWeight: FontWeight.w600))),
            ]))),
        ],
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => ctrl.startLesson(skill),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: _darken(color), offset: const Offset(0, 4), blurRadius: 0)]),
            child: const Center(child: Text('Start Lesson', style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Nunito'))))),
      ]));
  }
}

class _SheetCard extends StatelessWidget {
  final Color color;
  final String icon, title, body;
  const _SheetCard({required this.color, required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
          color: color, fontFamily: 'Nunito')),
      ]),
      const SizedBox(height: 6),
      Text(body, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary,
        fontFamily: 'Nunito', height: 1.4)),
    ]));
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.bgPage,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('🌳', style: TextStyle(fontSize: 64)),
      SizedBox(height: 20),
      Text('Tera learning path ban raha hai...', style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w900,
        color: AppColors.textPrimary, fontFamily: 'Nunito')),
      SizedBox(height: 8),
      Text('AI personalising your roadmap', style: TextStyle(
        fontSize: 13, color: AppColors.textMuted, fontFamily: 'Nunito')),
      SizedBox(height: 28),
      SizedBox(width: 180, child: LinearProgressIndicator(
        backgroundColor: AppColors.bgSection,
        valueColor: AlwaysStoppedAnimation(AppColors.primary))),
    ])));
}

class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgPage,
    body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('😕', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        const Text('Roadmap load nahi hua', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900,
          color: AppColors.textPrimary, fontFamily: 'Nunito')),
        const SizedBox(height: 8),
        Text(msg, textAlign: TextAlign.center, style: const TextStyle(
          fontSize: 13, color: AppColors.textMuted, fontFamily: 'Nunito')),
        const SizedBox(height: 28),
        GestureDetector(onTap: onRetry, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: AppColors.primaryDark, offset: Offset(0, 4), blurRadius: 0)]),
          child: const Text('Retry', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Nunito')))),
      ]))));
}

// helpers
Color _hex(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return AppColors.saffron;
  }
}

Color _darken(Color c) => Color.fromARGB(
    c.alpha, (c.red * 0.75).toInt(), (c.green * 0.75).toInt(), (c.blue * 0.75).toInt());
