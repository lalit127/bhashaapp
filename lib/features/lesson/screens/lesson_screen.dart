// lib/features/lesson/screens/lesson_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/lesson_controller.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(LessonController());

    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: Obx(() {
        if (ctrl.isLoading.value) return const _LessonLoader();
        if (ctrl.errorMsg.value != null) return _LessonError(ctrl: ctrl);
        if (ctrl.isComplete.value) return _LessonComplete(ctrl: ctrl);
        return _LessonBody(ctrl: ctrl);
      }),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────
class _LessonLoader extends StatelessWidget {
  const _LessonLoader();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080810),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7B5EA7), Color(0xFF00D4FF)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 40),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 800.ms),
            const SizedBox(height: 20),
            Text('Generating your lesson…',
                style: GoogleFonts.dmSans(
                    color: const Color(0xFFB0B0CC), fontSize: 15)),
            const SizedBox(height: 8),
            const Text('Personalizing for your level',
                style: TextStyle(color: Color(0xFF444466), fontSize: 12)),
          ],
        )),
      );
}

// ── Main body ─────────────────────────────────────────────────────────────────
class _LessonBody extends StatelessWidget {
  final LessonController ctrl;
  const _LessonBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Top bar ──────────────────────────────────────────────────────
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: Get.back,
            ),
            Expanded(
                child: Obx(() => ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: ctrl.progressRatio,
                        minHeight: 6,
                        backgroundColor: const Color(0xFF1E1E32),
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF7B5EA7)),
                      ),
                    ))),
            const SizedBox(width: 8),
            Obx(() => Text(
                  '${ctrl.currentIndex.value + 1}/${ctrl.totalActivities}',
                  style:
                      const TextStyle(color: Color(0xFF666688), fontSize: 12),
                )),
          ]),
        ),
      ),

      // ── Content pages ─────────────────────────────────────────────────
      Expanded(
        child: PageView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Each activity
            Obx(() {
              final act = ctrl.currentActivity;
              if (act == null) return const SizedBox();
              return _ActivityCard(ctrl: ctrl, activity: act);
            }),
          ],
        ),
      ),
    ]);
  }
}

// ── Activity card ─────────────────────────────────────────────────────────────
class _ActivityCard extends StatefulWidget {
  final LessonController ctrl;
  final Map<String, dynamic> activity;
  const _ActivityCard({required this.ctrl, required this.activity});
  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activity;
    final type = act['type']?.toString() ?? '';
    final instr = act['instruction']?.toString() ?? '';
    final q = act['question']?.toString() ?? '';
    final opts = (act['options'] as List?)?.cast<String>() ?? [];
    final xp = act['xp'] as int? ?? 10;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Type badge
        _TypeBadge(type: type),
        const SizedBox(height: 16),

        // XP chip
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7B5EA7), Color(0xFF00D4FF)]),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text('+$xp XP',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 12),

        // Instruction
        Text(instr,
            style: const TextStyle(color: Color(0xFF888899), fontSize: 13)),
        const SizedBox(height: 14),

        // Question
        _QuestionText(text: q, onSpeak: () => widget.ctrl.speakSentence(q)),

        const SizedBox(height: 24),

        // Input area
        if (type == 'multiple_choice' ||
            type == 'match_pairs' ||
            type == 'rearrange')
          _MultipleChoice(options: opts, ctrl: widget.ctrl)
        else
          _TextInput(controller: _textCtrl, ctrl: widget.ctrl),

        const SizedBox(height: 20),

        // Feedback
        Obx(() => widget.ctrl.showFeedback.value
            ? _FeedbackCard(ctrl: widget.ctrl)
            : const SizedBox()),

        // Next / Submit
        Obx(() => widget.ctrl.showFeedback.value
            ? _NextButton(ctrl: widget.ctrl)
            : (type == 'multiple_choice' || type == 'match_pairs'
                ? const SizedBox()
                : _SubmitButton(ctrl: widget.ctrl, textCtrl: _textCtrl))),
      ]),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'translation' => ('🔄 Translation', const Color(0xFF7B5EA7)),
      'fill_blank' => ('✏️ Fill the Blank', const Color(0xFF00D4FF)),
      'multiple_choice' => ('🎯 Multiple Choice', const Color(0xFFFF6B9D)),
      'rearrange' => ('🔀 Rearrange', const Color(0xFFFFB547)),
      'speak_sentence' => ('🎙️ Speak', const Color(0xFF00E5A0)),
      'error_correction' => ('🔍 Spot the Error', const Color(0xFFFF6B9D)),
      _ => ('📝 Practice', const Color(0xFF7B5EA7)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _QuestionText extends StatelessWidget {
  final String text;
  final VoidCallback onSpeak;
  const _QuestionText({required this.text, required this.onSpeak});
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Text(text,
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700))),
          IconButton(
            onPressed: onSpeak,
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF7B5EA7)),
          ),
        ],
      );
}

class _MultipleChoice extends StatelessWidget {
  final List<String> options;
  final LessonController ctrl;
  const _MultipleChoice({required this.options, required this.ctrl});
  @override
  Widget build(BuildContext context) => Column(
        children: options
            .map((opt) => Obx(() {
                  final selected = ctrl.selectedAnswer.value == opt;
                  final correct =
                      ctrl.currentActivity?['correct_answer']?.toString() ?? '';
                  Color? bg;
                  if (ctrl.showFeedback.value && selected) {
                    bg = ctrl.lastCorrect.value
                        ? const Color(0xFF00E5A0).withOpacity(0.15)
                        : const Color(0xFFFF4D6A).withOpacity(0.15);
                  } else if (ctrl.showFeedback.value && opt == correct) {
                    bg = const Color(0xFF00E5A0).withOpacity(0.15);
                  }
                  return GestureDetector(
                    onTap: ctrl.showFeedback.value
                        ? null
                        : () => ctrl.submitAnswer(opt),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bg ?? const Color(0xFF12121E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: selected
                                ? const Color(0xFF7B5EA7)
                                : const Color(0xFF1E1E32)),
                      ),
                      child: Row(children: [
                        Expanded(
                            child: Text(opt,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15))),
                        if (ctrl.showFeedback.value && opt == correct)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF00E5A0), size: 20),
                      ]),
                    ),
                  );
                }))
            .toList(),
      );
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final LessonController ctrl;
  const _TextInput({required this.controller, required this.ctrl});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type your answer here…',
              hintStyle: const TextStyle(color: Color(0xFF444466)),
              filled: true,
              fillColor: const Color(0xFF12121E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF7B5EA7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF1E1E32)),
              ),
            ),
          ),
        ),
      );
}

class _FeedbackCard extends StatelessWidget {
  final LessonController ctrl;
  const _FeedbackCard({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    final correct = ctrl.lastCorrect.value;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: correct
            ? const Color(0xFF00E5A0).withOpacity(0.1)
            : const Color(0xFFFF4D6A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: correct
                ? const Color(0xFF00E5A0).withOpacity(0.3)
                : const Color(0xFFFF4D6A).withOpacity(0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(correct ? '✅' : '❌', style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(ctrl.feedbackText.value,
                style: const TextStyle(
                    color: Color(0xFFB0B0CC), fontSize: 13, height: 1.5))),
      ]),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _SubmitButton extends StatelessWidget {
  final LessonController ctrl;
  final TextEditingController textCtrl;
  const _SubmitButton({required this.ctrl, required this.textCtrl});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () => ctrl.submitAnswer(textCtrl.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B5EA7),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text('Check Answer',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );
}

class _NextButton extends StatelessWidget {
  final LessonController ctrl;
  const _NextButton({required this.ctrl});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: ctrl.nextActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B5EA7),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              ctrl.currentIndex.value + 1 >= ctrl.totalActivities
                  ? 'Complete Lesson 🎉'
                  : 'Next →',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ]),
        ),
      );
}

// ── Lesson complete ────────────────────────────────────────────────────────────
class _LessonComplete extends StatelessWidget {
  final LessonController ctrl;
  const _LessonComplete({required this.ctrl});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080810),
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🎉', style: TextStyle(fontSize: 72)).animate().scale(
                begin: const Offset(0.5, 0.5),
                duration: 600.ms,
                curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text('Lesson Complete!',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800))
                .animate(delay: 200.ms)
                .fadeIn()
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 12),
            Obx(() => Text(
                  'Score: ${ctrl.score.value}%  ·  +${ctrl.xpEarned.value} XP',
                  style: const TextStyle(
                      color: Color(0xFF7B5EA7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                )).animate(delay: 350.ms).fadeIn(),
            const SizedBox(height: 32),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: ctrl.retry,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7B5EA7)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: Color(0xFF7B5EA7))),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                onPressed: Get.back,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5EA7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Continue',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              )),
            ]).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2, end: 0),
          ]),
        )),
      );
}

class _LessonError extends StatelessWidget {
  final LessonController ctrl;
  const _LessonError({required this.ctrl});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080810),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(ctrl.errorMsg.value ?? 'Error loading lesson',
                style: const TextStyle(color: Color(0xFF888899)),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: ctrl.retry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5EA7)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        )),
      );
}
