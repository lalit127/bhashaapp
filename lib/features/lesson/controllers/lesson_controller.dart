// lib/features/lesson/controllers/lesson_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/lesson_model.dart';

class LessonController extends GetxController {
  final _api = Get.find<ApiService>();
  final _storage = Get.find<StorageService>();
  final _tts = FlutterTts();

  // Lesson metadata
  late String skillId;
  late String skillName;
  late int lessonNum;
  late int totalLessonsInSkill;
  late String cefrLevel;

  // Lesson state
  final isLoading = true.obs;
  final errorMsg = RxnString();
  final isComplete = false.obs;

  // Activities (mapped from questions)
  final activities = <Map<String, dynamic>>[].obs;
  final currentIndex = 0.obs;

  // Feedback
  final showFeedback = false.obs;
  final lastCorrect = false.obs;
  final feedbackText = ''.obs;
  final selectedAnswer = ''.obs;

  // Score tracking
  final correctCount = 0.obs;
  final score = 0.obs;
  final xpEarned = 0.obs;

  Map<String, dynamic>? get currentActivity =>
      activities.isNotEmpty && currentIndex.value < activities.length
          ? activities[currentIndex.value]
          : null;

  int get totalActivities => activities.length;

  double get progressRatio =>
      totalActivities > 0 ? (currentIndex.value + 1) / totalActivities : 0.0;

  @override
  void onInit() {
    super.onInit();
    _initializeLesson();
  }

  @override
  void onClose() {
    _tts.stop();
    super.onClose();
  }

  void _initializeLesson() {
    try {
      final args = (Get.arguments as Map<String, dynamic>?) ?? {};

      skillId = args['skillId']?.toString() ?? 'unknown';
      skillName = args['skillName']?.toString() ?? 'Lesson';
      lessonNum = args['lessonNum'] as int? ?? 1;
      totalLessonsInSkill = args['totalLessons'] as int? ?? 3;
      cefrLevel = args['cefrLevel']?.toString() ?? 'A1';

      debugPrint('📚 Starting lesson:');
      debugPrint('   Skill: $skillId');
      debugPrint('   Lesson: $lessonNum');
      debugPrint('   Total lessons: $totalLessonsInSkill');
      debugPrint('   Level: $cefrLevel');

      _loadLesson();
    } catch (e) {
      debugPrint('❌ Error initializing lesson: $e');
      errorMsg.value = 'Failed to load lesson data';
      isLoading.value = false;
    }
  }

  Future<void> _loadLesson() async {
    isLoading.value = true;
    errorMsg.value = null;

    try {
      // Call generateLesson with all required parameters
      final result = await _api.generateLesson(
        nativeLanguage: _storage.getSelectedLanguage() ?? 'hindi',
        skillId: skillId,
        skillName: skillName,
        lessonNumber: lessonNum,
        totalLessons: totalLessonsInSkill,
        cefrLevel: cefrLevel,
        goal: _storage.getUserGoal() ?? 'daily',
        occupation: _storage.getUserOccupation() ?? 'student',
      );

      if (result != null) {
        // Map the LessonModel questions to the format expected by the activities list
        activities.value = result.questions.map((q) => {
          'type': q.type.name,
          'question_id': q.questionId,
          'prompt': q.promptNative ?? q.promptEnglish ?? '',
          'options': q.options,
          'correct_answer': q.correctAnswer,
          'explanation': q.explanationNative ?? '',
          'feedback_correct': '✅ Shabaash! Sahi jawab.',
          'feedback_incorrect': q.wrongAnswerExplanations[q.correctAnswer] ?? '❌ Galat jawab. Sahi hai: ${q.correctAnswer}',
          'jumbled_words': q.jumbledWords,
          'pronunciation_guide': q.pronunciationGuide,
        }).toList();
        
        debugPrint('✅ Loaded ${activities.length} activities');
      } else {
        throw Exception(_api.error.value ?? 'No activities returned from API');
      }
    } catch (e) {
      debugPrint('💥 Error loading lesson: $e');
      errorMsg.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> speakSentence(String text) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  void submitAnswer(String answer) {
    if (showFeedback.value) return;

    selectedAnswer.value = answer;
    final activity = currentActivity;
    if (activity == null) return;

    final correctAnswer = activity['correct_answer']?.toString().trim() ?? '';
    final userAnswer = answer.trim();

    // Check if correct (case-insensitive)
    final isCorrect = userAnswer.toLowerCase() == correctAnswer.toLowerCase();

    lastCorrect.value = isCorrect;

    if (isCorrect) {
      correctCount.value++;
      feedbackText.value = activity['feedback_correct']?.toString() ??
          '✅ Correct! Well done!';
    } else {
      feedbackText.value = activity['feedback_incorrect']?.toString() ??
          '❌ Not quite. The correct answer is: $correctAnswer';
    }

    showFeedback.value = true;
  }

  void nextActivity() {
    if (currentIndex.value + 1 >= totalActivities) {
      _completeLesson();
    } else {
      currentIndex.value++;
      showFeedback.value = false;
      selectedAnswer.value = '';
    }
  }

  Future<void> _completeLesson() async {
    // Calculate final score
    final totalQuestions = totalActivities;
    final scorePercent = totalQuestions > 0
        ? ((correctCount.value / totalQuestions) * 100).round()
        : 0;

    score.value = scorePercent;

    // Calculate XP based on score
    int baseXp = 10;
    if (scorePercent >= 95) {
      xpEarned.value = 15; // Perfect: +50% bonus
    } else if (scorePercent >= 80) {
      xpEarned.value = 12; // Great: +20% bonus
    } else {
      xpEarned.value = baseXp;
    }

    // Save progress
    try {
      final lessonId = '${skillId}_lesson_$lessonNum';

      debugPrint('✅ Completing lesson: $lessonId');
      debugPrint('   Score: $scorePercent%');
      debugPrint('   XP earned: ${xpEarned.value}');

      // Update skill progress
      await _storage.completeLesson(lessonId);

      // Award XP
      await _storage.addXp(xpEarned.value);

      // Show completion screen
      isComplete.value = true;

      // Show detailed dialog after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        _showCompletionDialog();
      });
    } catch (e) {
      debugPrint('❌ Error completing lesson: $e');
      Get.snackbar(
        'Error',
        'Failed to save progress',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.white,
      );
      isComplete.value = true;
    }
  }

  void _showCompletionDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF12121E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF7B5EA7).withOpacity(0.1),
                const Color(0xFF00D4FF).withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF7B5EA7).withOpacity(0.3),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7B5EA7).withOpacity(0.2),
                      const Color(0xFF00D4FF).withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '🎉',
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Lesson Complete!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                skillName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888899),
                  fontFamily: 'Nunito',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Score
                  _StatCard(
                    icon: '📊',
                    label: 'Score',
                    value: '${score.value}%',
                  ),
                  // XP
                  _StatCard(
                    icon: '⚡',
                    label: 'XP Earned',
                    value: '+${xpEarned.value}',
                    highlighted: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: retry,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7B5EA7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          color: Color(0xFF7B5EA7),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // Close dialog
                        Get.back(); // Return to previous screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5EA7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void retry() {
    // Reset state
    currentIndex.value = 0;
    showFeedback.value = false;
    selectedAnswer.value = '';
    correctCount.value = 0;
    score.value = 0;
    xpEarned.value = 0;
    isComplete.value = false;

    // Reload lesson
    _loadLesson();
  }
}

// ── Stat Card Widget ──────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool highlighted;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: highlighted
            ? LinearGradient(
          colors: [
            const Color(0xFFFFB547).withOpacity(0.2),
            const Color(0xFFFF6B9D).withOpacity(0.1),
          ],
        )
            : null,
        color: highlighted ? null : const Color(0xFF1E1E32).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFFFB547).withOpacity(0.4)
              : const Color(0xFF2A2A40).withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: highlighted ? const Color(0xFFFFB547) : Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF666688),
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}
