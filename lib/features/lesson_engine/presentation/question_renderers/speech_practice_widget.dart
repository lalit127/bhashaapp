import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/lesson_model.dart';

class SpeechPracticeWidget extends StatefulWidget {
  final QuestionModel question;
  final Function(String) onAnswer;
  final bool isAnswered;
  const SpeechPracticeWidget({super.key, required this.question,
      required this.onAnswer, required this.isAnswered});
  @override
  State<SpeechPracticeWidget> createState() => _SpeechPracticeWidgetState();
}

class _SpeechPracticeWidgetState extends State<SpeechPracticeWidget>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(widget.question.correctAnswer,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTapDown: (_) => setState(() => _isRecording = true),
          onTapUp: (_) {
            setState(() => _isRecording = false);
            // In production: process speech via SpeechToTextService
            widget.onAnswer(widget.question.correctAnswer);
          },
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _isRecording ? _pulseAnim.value : 1.0,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? AppColors.rose.withOpacity(0.2)
                      : AppColors.saffron.withOpacity(0.15),
                  border: Border.all(
                    color: _isRecording ? AppColors.rose : AppColors.saffron, width: 3),
                  boxShadow: _isRecording ? [BoxShadow(
                    color: AppColors.rose.withOpacity(0.4), blurRadius: 20)] : [],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: _isRecording ? AppColors.rose : AppColors.saffron, size: 40),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(_isRecording ? 'Listening...' : 'Hold to speak',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
      ],
    );
  }
}
