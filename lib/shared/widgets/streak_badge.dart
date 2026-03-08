import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  const StreakBadge({super.key, required this.streak});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.saffron.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.saffron.withOpacity(0.4))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('🔥', style: TextStyle(fontSize: 16)),
      const SizedBox(width: 4),
      Text('$streak', style: const TextStyle(color: AppColors.saffron,
          fontWeight: FontWeight.w900, fontSize: 15)),
    ]),
  );
}
