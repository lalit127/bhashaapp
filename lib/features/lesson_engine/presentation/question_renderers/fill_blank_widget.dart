import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/lesson_model.dart';

class FillBlankWidget extends StatefulWidget {
  final QuestionModel question;
  final Function(String) onAnswer;
  final bool isAnswered;
  final bool? isCorrect;
  const FillBlankWidget({super.key, required this.question,
      required this.onAnswer, required this.isAnswered, this.isCorrect});
  @override
  State<FillBlankWidget> createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: (widget.question.options ?? []).map((option) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              if (widget.isAnswered) return;
              setState(() => _selected = option);
              widget.onAnswer(option);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _selected == option ? AppColors.saffron.withOpacity(0.1) : AppColors.bgCard,
                border: Border.all(
                  color: _selected == option ? AppColors.saffron : AppColors.border, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(option, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: _selected == option ? AppColors.saffron : AppColors.textPrimary)),
            ),
          ),
        ),
      ).toList(),
    );
  }
}
