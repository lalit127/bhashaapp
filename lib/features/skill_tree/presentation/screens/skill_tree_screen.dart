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
  final _api = Get.find<ApiService>();
  final _storage = Get.find<StorageService>();

  final roadmap = Rxn<RoadmapModel>();
  final loading = true.obs;
  final errMsg = RxnString();
  final stageIdx = 0.obs;
  final animatedSkills = <String>{}.obs; // Track which skills have animated

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    errMsg.value = null;

    try {
      final lang = _storage.getSelectedLanguage() ?? 'hindi';
      final level = _storage.getSelectedLevel() ?? 'A1';
      final goal = _storage.getUserGoal() ?? 'daily';
      final occ = _storage.getUserOccupation() ?? 'student';

      debugPrint('🗺️ Loading roadmap: lang=$lang level=$level goal=$goal occ=$occ');

      final result = await _api.getRoadmap(
        nativeLanguage: lang,
        goal: goal,
        occupation: occ,
        currentLevel: level,
      );

      if (result != null) {
        debugPrint('✅ Roadmap loaded: ${result.stages.length} stages, ${result.totalSkills} skills');
        roadmap.value = result;
      } else {
        final err = _api.error.value ?? 'getRoadmap returned null';
        debugPrint('❌ Roadmap failed: $err');
        errMsg.value = err;
      }
    } catch (e, stack) {
      debugPrint('💥 Roadmap exception: $e');
      debugPrint(stack.toString());
      errMsg.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  int get userXp => _storage.getProgress().xp;

  bool isSkillUnlocked(SkillNode skill) => userXp >= skill.xpRequired;

  int getSkillProgress(SkillNode skill) {
    // Get lesson progress from storage
    final progress = _storage.getSkillProgress(skill.skillId);
    return progress?.completedLessons ?? 0;
  }

  void tapSkill(SkillNode skill) {
    if (!isSkillUnlocked(skill)) {
      Get.snackbar(
        '🔒 Locked',
        'Need ${skill.xpRequired} XP — You have ${userXp} XP',
        backgroundColor: AppColors.bgWhite,
        colorText: AppColors.textPrimary,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    if (skill.requiresPro) {
      Get.toNamed(AppRoutes.paywall, arguments: {'trigger': 'skill_tree'});
      return;
    }
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
      'skillId': skill.skillId,
      'skillName': skill.skillNameEnglish,
      'lessonNum': _getNextLessonNumber(skill),
      'totalLessons': skill.totalLessons,
      'cefrLevel': _storage.getSelectedLevel() ?? 'A1',
    });
  }
  int _getNextLessonNumber(SkillNode skill) {
    final progress = _storage.getSkillProgress(skill.skillId);
    final completed = progress?.completedLessons ?? 0;

    // Start from lesson 1 if none completed, otherwise next lesson
    return completed + 1;
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
        if (ctrl.errMsg.value != null) {
          return _ErrorView(msg: ctrl.errMsg.value!, onRetry: ctrl._load);
        }
        return _TreeBody(ctrl: ctrl);
      }),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────────
class _TreeBody extends StatelessWidget {
  final SkillTreeController ctrl;
  const _TreeBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final rm = ctrl.roadmap.value!;
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(rm),
          // Stage tabs
          _buildStageTabs(rm),
          const Divider(height: 1, color: AppColors.border),
          // Skill tree
          Expanded(
            child: Obx(() {
              final stage = rm.stages[ctrl.stageIdx.value];
              return _DuolingoSkillTree(stage: stage, ctrl: ctrl);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(RoadmapModel rm) {
    return Container(
      color: AppColors.bgWhite,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rm.tagline,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontFamily: 'Nunito')),
                Text(rm.taglineEnglish,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito')),
              ],
            ),
          ),
          // XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('${ctrl.userXp} XP',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                        fontFamily: 'Nunito')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageTabs(RoadmapModel rm) {
    return Obx(() => Container(
      color: AppColors.bgWhite,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: rm.stages.asMap().entries.map((e) {
            final active = ctrl.stageIdx.value == e.key;
            final stage = e.value;
            final color = _hex(stage.colorHex);
            return GestureDetector(
              onTap: () => ctrl.stageIdx.value = e.key,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? color.withOpacity(0.15)
                      : AppColors.bgSection,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? color : AppColors.border,
                      width: active ? 2 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(stage.iconEmoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(stage.stageNameEnglish,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                            color: active
                                ? color
                                : AppColors.textMuted)),
                    if (stage.requiresPro) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('PRO',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ));
  }
}

// ── Duolingo-Style Skill Tree ─────────────────────────────────────────────────
class _DuolingoSkillTree extends StatefulWidget {
  final RoadmapStage stage;
  final SkillTreeController ctrl;

  const _DuolingoSkillTree({required this.stage, required this.ctrl});

  @override
  State<_DuolingoSkillTree> createState() => _DuolingoSkillTreeState();
}

class _DuolingoSkillTreeState extends State<_DuolingoSkillTree> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final skills = widget.stage.skills;

        // Calculate positions in Duolingo style (vertical progression)
        final positions = _calculateDuolingoPositions(skills, width);
        final totalHeight = positions.isEmpty ? 0.0 : positions.last.dy + 200;

        return Container(
          color: AppColors.bgPage,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: width,
              height: math.max(totalHeight, constraints.maxHeight),
              child: Stack(
                children: [
                  // Background decorative elements
                  ..._buildBackgroundDecor(width, totalHeight),

                  // Paths between nodes
                  CustomPaint(
                    size: Size(width, totalHeight),
                    painter: _DuolingoPathPainter(
                      positions: positions,
                      skills: skills,
                      ctrl: widget.ctrl,
                    ),
                  ),

                  // Skill nodes with staggered animation
                  ...List.generate(skills.length, (i) {
                    final skill = skills[i];
                    final pos = positions[i];
                    final isCheckpoint = (i + 1) % 5 == 0; // Every 5th skill

                    return Positioned(
                      left: pos.dx - 40,
                      top: pos.dy - 40,
                      child: TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (i * 50)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: _DuolingoSkillNode(
                          skill: skill,
                          ctrl: widget.ctrl,
                          isCheckpoint: isCheckpoint,
                        ),
                      ),
                    );
                  }),

                  // Stage completion banner
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: _StageBanner(stage: widget.stage),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Offset> _calculateDuolingoPositions(List<SkillNode> skills, double width) {
    final positions = <Offset>[];
    const verticalSpacing = 140.0;
    final centerX = width / 2;
    final leftX = width * 0.25;
    final rightX = width * 0.75;

    for (int i = 0; i < skills.length; i++) {
      final y = 100.0 + (i * verticalSpacing);

      // Duolingo pattern: alternates center, left, right, center...
      double x;
      final pattern = i % 6;
      switch (pattern) {
        case 0:
          x = centerX;
          break;
        case 1:
          x = leftX;
          break;
        case 2:
          x = rightX;
          break;
        case 3:
          x = centerX;
          break;
        case 4:
          x = rightX;
          break;
        case 5:
          x = leftX;
          break;
        default:
          x = centerX;
      }

      positions.add(Offset(x, y));
    }

    return positions;
  }

  List<Widget> _buildBackgroundDecor(double width, double height) {
    return [
      // Subtle gradient overlay
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgPage,
                AppColors.bgPage.withOpacity(0.95),
                AppColors.bgPage,
              ],
            ),
          ),
        ),
      ),
      // Decorative circles
      ...List.generate(5, (i) {
        return Positioned(
          left: (i % 2 == 0) ? -50 : width - 50,
          top: i * (height / 5),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.03),
            ),
          ),
        );
      }),
    ];
  }
}

// ── Duolingo Path Painter ─────────────────────────────────────────────────────
class _DuolingoPathPainter extends CustomPainter {
  final List<Offset> positions;
  final List<SkillNode> skills;
  final SkillTreeController ctrl;

  const _DuolingoPathPainter({
    required this.positions,
    required this.skills,
    required this.ctrl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < positions.length - 1; i++) {
      final from = positions[i];
      final to = positions[i + 1];
      final fromSkill = skills[i];
      final toSkill = skills[i + 1];

      final bothUnlocked = ctrl.isSkillUnlocked(fromSkill) &&
          ctrl.isSkillUnlocked(toSkill);

      // Different colors based on state
      Color pathColor;
      double strokeWidth;

      if (bothUnlocked) {
        pathColor = AppColors.primary;
        strokeWidth = 4.0;
      } else if (ctrl.isSkillUnlocked(fromSkill)) {
        pathColor = AppColors.border;
        strokeWidth = 3.0;
      } else {
        pathColor = AppColors.border.withOpacity(0.3);
        strokeWidth = 2.0;
      }

      final paint = Paint()
        ..color = pathColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Create smooth S-curve path (Duolingo style)
      final path = Path();
      path.moveTo(from.dx, from.dy);

      final deltaY = to.dy - from.dy;
      final deltaX = to.dx - from.dx;

      // Control points for smooth curve
      final cp1 = Offset(from.dx + deltaX * 0.3, from.dy + deltaY * 0.3);
      final cp2 = Offset(to.dx - deltaX * 0.3, to.dy - deltaY * 0.3);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, to.dx, to.dy);

      if (bothUnlocked) {
        // Solid line for unlocked paths
        canvas.drawPath(path, paint);

        // Add subtle glow effect
        final glowPaint = Paint()
          ..color = pathColor.withOpacity(0.3)
          ..strokeWidth = strokeWidth + 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawPath(path, glowPaint);
      } else {
        // Dashed line for locked paths
        _drawDashedPath(canvas, path, paint);
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        final extractPath = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        canvas.drawPath(extractPath, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DuolingoPathPainter oldDelegate) => true;
}

// ── Duolingo Skill Node ───────────────────────────────────────────────────────
class _DuolingoSkillNode extends StatefulWidget {
  final SkillNode skill;
  final SkillTreeController ctrl;
  final bool isCheckpoint;

  const _DuolingoSkillNode({
    required this.skill,
    required this.ctrl,
    this.isCheckpoint = false,
  });

  @override
  State<_DuolingoSkillNode> createState() => _DuolingoSkillNodeState();
}

class _DuolingoSkillNodeState extends State<_DuolingoSkillNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPressing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.ctrl.isSkillUnlocked(widget.skill);
    final color = _hex(widget.skill.colorHex);
    final progress = widget.ctrl.getSkillProgress(widget.skill);
    final totalLessons = widget.skill.totalLessons;
    final progressPercent = totalLessons > 0 ? progress / totalLessons : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressing = true),
      onTapUp: (_) {
        setState(() => _isPressing = false);
        widget.ctrl.tapSkill(widget.skill);
      },
      onTapCancel: () => setState(() => _isPressing = false),
      child: AnimatedScale(
        scale: _isPressing ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: 80,
          height: widget.isCheckpoint ? 120 : 100,
          child: Column(
            children: [
              // Node circle
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse animation for unlocked next skill
                  if (unlocked && progress == 0)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 72 + (_pulseController.value * 12),
                          height: 72 + (_pulseController.value * 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withOpacity(
                                  0.3 - (_pulseController.value * 0.3)),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),

                  // Progress ring
                  if (unlocked && totalLessons > 0)
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progressPercent,
                        strokeWidth: 5,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),

                  // Main circle
                  Container(
                    width: widget.isCheckpoint ? 80 : 72,
                    height: widget.isCheckpoint ? 80 : 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked
                          ? color.withOpacity(0.15)
                          : AppColors.bgSection,
                      border: Border.all(
                        color: unlocked ? color : AppColors.border,
                        width: unlocked ? 4 : 2,
                      ),
                      boxShadow: unlocked
                          ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                          : [],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Icon
                        Text(
                          widget.skill.iconEmoji,
                          style: TextStyle(
                            fontSize: widget.isCheckpoint ? 32 : 28,
                            color: unlocked ? null : Colors.grey,
                          ),
                        ),

                        // Lock overlay
                        if (!unlocked)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.4),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Colors.white70,
                              size: 28,
                            ),
                          ),

                        // Completed checkmark
                        if (progressPercent >= 1.0)
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success,
                                border: Border.all(
                                    color: AppColors.bgPage, width: 2),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),

                        // Pro badge
                        if (widget.skill.requiresPro && unlocked)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.goldGradient,
                              ),
                              child: const Center(
                                child: Text(
                                  '★',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white),
                                ),
                              ),
                            ),
                          ),

                        // Checkpoint star
                        if (widget.isCheckpoint && unlocked)
                          Positioned(
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Skill name
              Text(
                widget.skill.skillName,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito',
                  color: unlocked
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  height: 1.2,
                ),
              ),

              // Progress indicator
              if (unlocked && totalLessons > 0 && progress > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '$progress/$totalLessons',
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stage Banner ──────────────────────────────────────────────────────────────
class _StageBanner extends StatelessWidget {
  final RoadmapStage stage;
  const _StageBanner({required this.stage});

  @override
  Widget build(BuildContext context) {
    final color = _hex(stage.colorHex);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                Text(stage.iconEmoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.stageNameEnglish,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: color,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    Text(
                      stage.stageName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '~${stage.estimatedDays}d',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...stage.whatYouLearn.take(3).map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFamily: 'Nunito',
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Skill Detail Sheet ────────────────────────────────────────────────────────
class _SkillDetailSheet extends StatelessWidget {
  final SkillNode skill;
  final SkillTreeController ctrl;
  const _SkillDetailSheet({required this.skill, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final color = _hex(skill.colorHex);
    final progress = ctrl.getSkillProgress(skill);
    final totalLessons = skill.totalLessons;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(skill.iconEmoji,
                      style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.skillName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.library_books, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          '$totalLessons lessons',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.record_voice_over,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${skill.vocabularyCount} words',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar
          if (totalLessons > 0) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    Text(
                      '$progress / $totalLessons lessons',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / totalLessons,
                    minHeight: 8,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Content cards
          if (skill.realLifeScenario.isNotEmpty)
            _SheetCard(
              color: color,
              icon: '🎯',
              title: 'Real-Life Scenario',
              body: skill.realLifeScenario,
            ),

          const SizedBox(height: 12),

          if (skill.confidentWith.isNotEmpty)
            _SheetCard(
              color: AppColors.success,
              icon: '✅',
              title: 'You\'ll be confident with',
              body: skill.confidentWith,
            ),

          const SizedBox(height: 12),

          // Key phrases
          if (skill.keyPhrases.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Key Phrases You\'ll Learn:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...skill.keyPhrases.take(3).map((phrase) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: color.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phrase.english,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phrase.native,
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  if (phrase.neverSay.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close,
                              size: 12, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text(
                            'Never say: ${phrase.neverSay}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )),
          ],

          const SizedBox(height: 20),

          // Start button
          GestureDetector(
            onTap: () => ctrl.startLesson(skill),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, _darken(color, 0.15)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    offset: const Offset(0, 6),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    progress > 0 ? 'Continue Learning' : 'Start Lesson',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Card ───────────────────────────────────────────────────────────────
class _SheetCard extends StatelessWidget {
  final Color color;
  final String icon, title, body;
  const _SheetCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌳', style: TextStyle(fontSize: 64)),
            SizedBox(height: 24),
            Text(
              'Building your learning path...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'AI is personalizing your roadmap',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.bgSection,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              const Text(
                'Couldn\'t load roadmap',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.primaryDark,
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
Color _hex(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return AppColors.saffron;
  }
}

Color _darken(Color c, [double amount = 0.1]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(c);
  final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return darkened.toColor();
}