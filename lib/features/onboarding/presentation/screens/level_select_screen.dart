import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/storage_service.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});
  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  String? _selectedLevel;
  String? _selectedGoal;

  final _levels = const [
    {'id': 'beginner',     'label': 'Beginner',     'desc': 'Just starting out',     'emoji': '🌱'},
    {'id': 'intermediate', 'label': 'Intermediate', 'desc': 'Know some basics',       'emoji': '🌿'},
    {'id': 'advanced',     'label': 'Advanced',     'desc': 'Looking to get fluent',  'emoji': '🌳'},
  ];

  final _goals = const [
    {'id': 'travel',       'label': 'Travel',       'emoji': '✈️'},
    {'id': 'conversation', 'label': 'Conversation', 'emoji': '💬'},
    {'id': 'exam',         'label': 'Exam Prep',    'emoji': '📚'},
    {'id': 'daily',        'label': 'Daily Life',   'emoji': '🏡'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildStepBadge('Step 2 of 4'),
              const SizedBox(height: 12),
              const Text('Tell us about yourself',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary, fontFamily: 'Nunito')),
              const SizedBox(height: 32),
              _buildSectionLabel('Your level'),
              const SizedBox(height: 12),
              ..._levels.map((l) => _LevelCard(
                level: l,
                isSelected: _selectedLevel == l['id'],
                onTap: () => setState(() => _selectedLevel = l['id']),
              )),
              const SizedBox(height: 28),
              _buildSectionLabel('Your learning goal'),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _goals.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10,
                  mainAxisSpacing: 10, childAspectRatio: 1.6,
                ),
                itemBuilder: (_, i) => _GoalCard(
                  goal: _goals[i],
                  isSelected: _selectedGoal == _goals[i]['id'],
                  onTap: () => setState(() => _selectedGoal = _goals[i]['id']),
                ),
              ),
              const SizedBox(height: 28),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.saffron.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.saffron,
        fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
  );

  Widget _buildSectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
        letterSpacing: 1.5, color: AppColors.textMuted, fontFamily: 'Nunito'),
  );

  Widget _buildContinueButton() {
    final isEnabled = _selectedLevel != null && _selectedGoal != null;
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isEnabled ? AppColors.primaryGradient : null,
          color: isEnabled ? null : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isEnabled ? [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12, offset: const Offset(0, 4))
          ] : [],
        ),
        child: TextButton(
          onPressed: isEnabled ? () async {
            final storage = Get.find<StorageService>();
            await storage.setSelectedLevel(_selectedLevel!);
            await storage.setSelectedGoal(_selectedGoal!);
            Get.toNamed(AppRoutes.packDownload);
          } : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          child: Text('Continue →',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: isEnabled ? Colors.white : AppColors.textMuted, fontFamily: 'Nunito')),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final Map<String, String> level;
  final bool isSelected;
  final VoidCallback onTap;
  const _LevelCard({required this.level, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal.withValues(alpha: 0.12) : AppColors.bgCard,
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(level['emoji']!, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level['label']!, style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'Nunito',
                    color: isSelected ? AppColors.teal : AppColors.textPrimary)),
                  Text(level['desc']!, style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted, fontFamily: 'Nunito')),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.teal, size: 22),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Map<String, String> goal;
  final bool isSelected;
  final VoidCallback onTap;
  const _GoalCard({required this.goal, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.indigo.withValues(alpha: 0.15) : AppColors.bgCard,
          border: Border.all(
            color: isSelected ? AppColors.indigo : AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(goal['emoji']!, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(goal['label']!, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Nunito',
              color: isSelected ? AppColors.indigo : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
