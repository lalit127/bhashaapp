import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Get.find<StorageService>().getProgress();
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('My Progress')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              const Text('👤', style: TextStyle(fontSize: 48)),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Language Learner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('${p.league[0].toUpperCase()}${p.league.substring(1)} League', style: const TextStyle(color: Colors.white70)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _Stat('🔥', '${p.streak}', 'Streak', AppColors.saffron)),
            const SizedBox(width: 12),
            Expanded(child: _Stat('⚡', '${p.xp}', 'Total XP', AppColors.gold)),
            const SizedBox(width: 12),
            Expanded(child: _Stat('📖', '${p.totalLessons}', 'Lessons', AppColors.teal)),
          ]),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String icon, value, label;
  final Color color;
  const _Stat(this.icon, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    ]),
  );
}
