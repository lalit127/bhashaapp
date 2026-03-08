import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HeartsRow extends StatelessWidget {
  final int hearts;
  final int maxHearts;
  const HeartsRow({super.key, required this.hearts, this.maxHearts = 5});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxHearts, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          Icons.favorite,
          size: 20,
          color: i < hearts ? AppColors.heart : AppColors.border,
        ),
      )),
    );
  }
}
