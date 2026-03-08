import 'package:flutter/material.dart';
import '../../../../shared/models/lesson_model.dart';
import 'multiple_choice_widget.dart';
import 'translation_widget.dart';
import 'fill_blank_widget.dart';
import 'speech_practice_widget.dart';

class QuestionRendererFactory {
  static Widget build({
    required QuestionModel question,
    required Function(String) onAnswer,
    required bool isAnswered,
    bool? isCorrect,
  }) {
    switch (question.type) {
      case QuestionType.matchSituation:
        return MultipleChoiceWidget(question: question, onAnswer: onAnswer,
            isAnswered: isAnswered, isCorrect: isCorrect);
      case QuestionType.translateToEnglish:
        return TranslationWidget(question: question, onAnswer: onAnswer,
            isAnswered: isAnswered, isCorrect: isCorrect);
      case QuestionType.fillBlank:
        return FillBlankWidget(question: question, onAnswer: onAnswer,
            isAnswered: isAnswered, isCorrect: isCorrect);
      case QuestionType.speak:
        return SpeechPracticeWidget(question: question, onAnswer: onAnswer,
            isAnswered: isAnswered);
      default:
        return MultipleChoiceWidget(question: question, onAnswer: onAnswer,
            isAnswered: isAnswered, isCorrect: isCorrect);
    }
  }
}
