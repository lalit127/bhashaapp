import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/lesson_model.dart';

class TranslationWidget extends StatefulWidget {
  final QuestionModel question;
  final Function(String) onAnswer;
  final bool isAnswered;
  final bool? isCorrect;
  const TranslationWidget({super.key, required this.question,
      required this.onAnswer, required this.isAnswered, this.isCorrect});
  @override
  State<TranslationWidget> createState() => _TranslationWidgetState();
}

class _TranslationWidgetState extends State<TranslationWidget> {
  final _controller = TextEditingController();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.question.hintNative != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.indigo.withOpacity(0.3)),
            ),
            child: Text('💡 ${widget.question.hintNative}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
        TextField(
          controller: _controller,
          enabled: !_submitted,
          style: const TextStyle(fontSize: 18, color: AppColors.textPrimary,
              fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.saffron, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!_submitted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_controller.text.isEmpty) return;
                setState(() => _submitted = true);
                widget.onAnswer(_controller.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffron,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Check', style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
      ],
    );
  }
}
