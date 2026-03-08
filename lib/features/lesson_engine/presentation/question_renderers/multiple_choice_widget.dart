import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/lesson_model.dart';

class MultipleChoiceWidget extends StatefulWidget {
  final QuestionModel question;
  final Function(String) onAnswer;
  final bool isAnswered;
  final bool? isCorrect;
  const MultipleChoiceWidget({super.key, required this.question,
      required this.onAnswer, required this.isAnswered, this.isCorrect});
  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  String? _selected;

  Color _getOptionColor(String option) {
    if (!widget.isAnswered || _selected != option) return AppColors.bgCard;
    return widget.isCorrect! ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15);
  }

  Color _getOptionBorder(String option) {
    if (_selected == option && widget.isAnswered) {
      return widget.isCorrect! ? AppColors.success : AppColors.error;
    }
    if (widget.isAnswered && option == widget.question.correctAnswer) {
      return AppColors.success;
    }
    if (_selected == option) return AppColors.saffron;
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.question.options.map((option) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              if (widget.isAnswered) return;
              setState(() => _selected = option);
              widget.onAnswer(option);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: _getOptionColor(option),
                border: Border.all(color: _getOptionBorder(option), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(option, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary))),
                  if (widget.isAnswered && option == widget.question.correctAnswer)
                    const Text('✓', style: TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.w900)),
                  if (widget.isAnswered && _selected == option && option != widget.question.correctAnswer)
                    const Text('✗', style: TextStyle(color: AppColors.error, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ),
      ).toList(),
    );
  }
}
