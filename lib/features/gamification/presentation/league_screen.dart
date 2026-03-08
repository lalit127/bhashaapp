import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';

class LeagueScreen extends StatelessWidget {
  const LeagueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Get.find<StorageService>().getProgress();
    final leaderboard = [
      {'name': 'Priya S.', 'xp': 1240, 'emoji': '👑'},
      {'name': 'Rahul M.', 'xp': 980,  'emoji': '🥈'},
      {'name': 'Anjali K.', 'xp': 870, 'emoji': '🥉'},
      {'name': 'You',       'xp': p.weeklyXp, 'emoji': '😊'},
      {'name': 'Vikram P.', 'xp': 310, 'emoji': '😐'},
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('League')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: Column(children: [
            const Text('🥈', style: TextStyle(fontSize: 72)),
            Text('${p.league[0].toUpperCase()}${p.league.substring(1)} League',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.silver)),
            const Text('Weekly XP Leaderboard', style: TextStyle(color: AppColors.textMuted)),
          ])),
          const SizedBox(height: 32),
          ...leaderboard.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: e.value['name'] == 'You' ? AppColors.saffron.withOpacity(0.1) : AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: e.value['name'] == 'You' ? AppColors.saffron : AppColors.border)),
            child: Row(children: [
              Text('#${e.key + 1}', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(width: 12),
              Text(e.value['emoji'] as String, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Text(e.value['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
              Text('${e.value['xp']} XP', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
            ]),
          )),
        ],
      ),
    );
  }
}
