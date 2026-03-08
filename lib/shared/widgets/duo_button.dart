// Duolingo-style button with bottom shadow "pressed" effect
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DuoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final Color shadowColor;
  final Color textColor;
  final double? width;
  final bool outlined;
  final String? emoji;

  const DuoButton({
    super.key,
    required this.text,
    this.onTap,
    this.color = AppColors.primary,
    this.shadowColor = AppColors.primaryDark,
    this.textColor = Colors.white,
    this.width,
    this.outlined = false,
    this.emoji,
  });

  factory DuoButton.saffron({required String text, VoidCallback? onTap, double? width, String? emoji}) =>
      DuoButton(text: text, onTap: onTap, color: AppColors.saffron, shadowColor: AppColors.saffronDark,
        width: width, emoji: emoji);

  factory DuoButton.outline({required String text, VoidCallback? onTap, double? width}) =>
      DuoButton(text: text, onTap: onTap, color: AppColors.bgWhite, shadowColor: AppColors.border,
        textColor: AppColors.textPrimary, width: width, outlined: true);

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.width,
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        child: Container(
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            border: widget.outlined ? Border.all(color: AppColors.border, width: 2) : null,
            boxShadow: _pressed ? [] : [
              BoxShadow(
                color: widget.shadowColor,
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.emoji != null) ...[
                  Text(widget.emoji!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: widget.textColor,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
