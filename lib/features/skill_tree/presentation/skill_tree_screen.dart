import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/language_pack_model.dart';
import '../../../shared/models/progress_model.dart';

class SkillTreeScreen extends StatefulWidget {
  const SkillTreeScreen({super.key});
  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> {
  // Demo data — in production, load from course.json via PackService
  final List<SkillNode> _nodes = [
    SkillNode(skillId: 'greetings', name: 'Greetings', iconEmoji: '👋',
        xpRequired: 0,   lessonIds: ['l1','l2','l3'], positionX: 0.5,  positionY: 0.05, color: '#FF6B2B'),
    SkillNode(skillId: 'numbers',   name: 'Numbers',   iconEmoji: '🔢',
        xpRequired: 30,  lessonIds: ['l4','l5'],      positionX: 0.25, positionY: 0.18, color: '#FF4081', prerequisites: ['greetings']),
    SkillNode(skillId: 'colors',    name: 'Colors',    iconEmoji: '🎨',
        xpRequired: 30,  lessonIds: ['l6','l7'],      positionX: 0.75, positionY: 0.18, color: '#3D5AFE', prerequisites: ['greetings']),
    SkillNode(skillId: 'family',    name: 'Family',    iconEmoji: '👨‍👩‍👧',
        xpRequired: 80,  lessonIds: ['l8','l9'],      positionX: 0.5,  positionY: 0.33, color: '#00BFA5', prerequisites: ['numbers','colors']),
    SkillNode(skillId: 'food',      name: 'Food',      iconEmoji: '🍛',
        xpRequired: 130, lessonIds: ['l10','l11'],    positionX: 0.3,  positionY: 0.48, color: '#FFD600', prerequisites: ['family']),
    SkillNode(skillId: 'travel',    name: 'Travel',    iconEmoji: '✈️',
        xpRequired: 130, lessonIds: ['l12','l13'],    positionX: 0.7,  positionY: 0.48, color: '#E91E8C', prerequisites: ['family']),
    SkillNode(skillId: 'business',  name: 'Business',  iconEmoji: '💼',
        xpRequired: 200, lessonIds: ['l14','l15'],    positionX: 0.5,  positionY: 0.64, color: '#00C853', prerequisites: ['food','travel']),
    SkillNode(skillId: 'advanced',  name: 'Advanced',  iconEmoji: '🏆',
        xpRequired: 300, lessonIds: ['l16','l17'],    positionX: 0.5,  positionY: 0.80, color: '#00E5FF', prerequisites: ['business']),
  ];

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    final progress = storage.getProgress();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text('${progress.streak}', style: const TextStyle(
                color: AppColors.saffron, fontWeight: FontWeight.w900)),
            const SizedBox(width: 16),
            const Text('⚡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text('${progress.xp} XP', style: const TextStyle(
                color: AppColors.gold, fontWeight: FontWeight.w900)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back()),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              height: 900,
              child: Stack(
                children: [
                  // Draw curved paths between nodes
                  CustomPaint(
                    size: Size(constraints.maxWidth, 900),
                    painter: _TreePathPainter(nodes: _nodes, userProgress: progress),
                  ),
                  // Draw skill nodes
                  ..._nodes.map((node) => _buildNode(node, constraints.maxWidth, progress)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isUnlocked(SkillNode node, UserProgress progress) {
    return progress.xp >= node.xpRequired;
  }

  Widget _buildNode(SkillNode node, double width, UserProgress progress) {
    final unlocked = _isUnlocked(node, progress);
    final completed = progress.completedSkills.contains(node.skillId);
    final x = node.positionX * width;
    final y = node.positionY * 900;
    final color = Color(int.parse('0xFF${node.color.substring(1)}'));

    return Positioned(
      left: x - 36,
      top: y - 36,
      child: GestureDetector(
        onTap: () {
          if (unlocked) {
            Get.toNamed(AppRoutes.lesson, arguments: {'skillId': node.skillId});
          } else {
            Get.snackbar('🔒 Locked',
                'Need ${node.xpRequired} XP to unlock. You have ${progress.xp} XP.',
                backgroundColor: AppColors.bgCard,
                colorText: AppColors.textPrimary,
                snackPosition: SnackPosition.BOTTOM);
          }
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked ? color.withOpacity(0.15) : AppColors.bgCard,
                border: Border.all(
                  color: unlocked ? color : AppColors.border, width: 3),
                boxShadow: unlocked ? [BoxShadow(
                  color: color.withOpacity(0.4), blurRadius: 16)] : [],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(unlocked ? node.iconEmoji : '🔒',
                        style: TextStyle(fontSize: unlocked ? 28 : 22)),
                    if (completed)
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 18, height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.emerald, shape: BoxShape.circle),
                          child: const Center(
                            child: Text('✓', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900))),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(node.name, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: unlocked ? AppColors.textPrimary : AppColors.textMuted)),
            if (!unlocked)
              Text('${node.xpRequired} XP', style: const TextStyle(
                  fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _TreePathPainter extends CustomPainter {
  final List<SkillNode> nodes;
  final UserProgress userProgress;
  _TreePathPainter({required this.nodes, required this.userProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, SkillNode> nodeMap = {for (var n in nodes) n.skillId: n};

    for (final node in nodes) {
      for (final prereqId in node.prerequisites) {
        final prereq = nodeMap[prereqId];
        if (prereq == null) continue;

        final startX = prereq.positionX * size.width;
        final startY = prereq.positionY * 900;
        final endX = node.positionX * size.width;
        final endY = node.positionY * 900;

        final isActive = userProgress.xp >= node.xpRequired;

        final paint = Paint()
          ..color = isActive ? AppColors.saffron.withOpacity(0.4) : AppColors.border
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        if (isActive) {
          paint.shader = LinearGradient(
            colors: [AppColors.saffron.withOpacity(0.7), AppColors.rose.withOpacity(0.5)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ).createShader(Rect.fromPoints(
              Offset(startX, startY), Offset(endX, endY)));
        }

        final path = Path();
        path.moveTo(startX, startY + 36);
        final midY = (startY + 36 + endY - 36) / 2;
        path.cubicTo(startX, midY, endX, midY, endX, endY - 36);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
