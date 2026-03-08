import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class XpBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final double height;

  const XpBar({super.key, required this.value, this.color = AppColors.xpBlue, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgSection,
        borderRadius: BorderRadius.circular(height),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
            // Shine stripe
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(left: 6, top: 2),
                    width: 20, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
