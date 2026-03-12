import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/lesson_model.dart';
import '../../../shared/widgets/xp_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class LessonController extends GetxController {
  final _api     = Get.find<ApiService>();
  final _storage = Get.find<StorageService>();

  final lesson   = Rxn<LessonModel>();
  final loading  = true.obs;
  final errMsg   = RxnString();
  final phase    = 'intro'.obs; // intro → vocab → grammar → questions → done

  // question state
  final qIndex        = 0.obs;
  final hearts        = 5.obs;
  final xp            = 0.obs;
  final selected      = RxnString();
  final answered      = false.obs;
  final correct       = false.obs;
  final selectedWords = <String>[].obs;
  final wordBank      = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    errMsg.value  = null;
    final args = Get.arguments as Map<String, dynamic>? ?? {};

    final result = await _api.getLegacyLesson(
      nativeLanguage: _storage.getSelectedLanguage() ?? 'hindi',
      skillId:        args['skillId']    ?? 'english_greetings',
      skillName:      args['skillName']  ?? 'Hello bolna seekho',
      lessonNumber:   args['lessonNum']  ?? 1,
      cefrLevel:      _storage.getSelectedLevel() ?? 'A1',
      goal:           _storage.getUserGoal()       ?? 'daily',
      occupation:     _storage.getUserOccupation() ?? 'student',
    );

    if (result != null) {
      lesson.value = result;
      phase.value  = 'intro';
    } else {
      errMsg.value = _api.error.value ?? 'Lesson load nahi hua';
    }
    loading.value = false;
  }

  void startLesson()  => phase.value = 'vocab';
  void goGrammar()    => phase.value = 'grammar';
  void goQuestions()  { phase.value = 'questions'; _resetQ(); }

  void _resetQ() {
    qIndex.value = 0; selected.value = null;
    answered.value = false; correct.value = false;
    _initWordBank();
  }

  void _initWordBank() {
    final q = currentQ;
    if (q != null && q.type == QuestionType.arrangeWords) {
      final words = List<String>.from(q.jumbledWords ?? [])..shuffle();
      wordBank.assignAll(words);
      selectedWords.clear();
    }
  }

  QuestionModel? get currentQ {
    final l = lesson.value;
    if (l == null || qIndex.value >= l.questions.length) return null;
    return l.questions[qIndex.value];
  }

  double get progress {
    final l = lesson.value;
    if (l == null || l.questions.isEmpty) return 0;
    return qIndex.value / l.questions.length;
  }

  void pick(String opt) {
    if (answered.value) return;
    final q = currentQ;
    if (q == null) return;
    final ok = opt.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase();
    selected.value  = opt;
    answered.value  = true;
    correct.value   = ok;
    if (ok) {
      xp.value += q.points * 10;
    } else {
      hearts.value = (hearts.value - 1).clamp(0, 5);
    }
    HapticFeedback.mediumImpact();
  }

  void tapWord(String w) {
    if (answered.value) return;
    wordBank.remove(w);
    selectedWords.add(w);
    if (selectedWords.length == (currentQ?.jumbledWords?.length ?? 0)) {
      final attempt = selectedWords.join(' ');
      pick(attempt);
    }
  }

  void untapWord(String w) {
    if (answered.value) return;
    selectedWords.remove(w);
    wordBank.add(w);
  }

  void submitSpeak(String sttResult) {
    final q = currentQ;
    if (q == null) return;
    final score = _sttScore(sttResult, q.correctAnswer);
    pick(score >= q.acceptanceThreshold ? q.correctAnswer : '__failed__$sttResult');
  }

  double _sttScore(String got, String exp) {
    final g = got.toLowerCase().trim(), e = exp.toLowerCase().trim();
    if (g == e) return 1.0;
    final gW = g.split(' ').toSet(), eW = e.split(' ').toSet();
    return eW.isEmpty ? 0 : gW.intersection(eW).length / eW.length;
  }

  void next() {
    final l = lesson.value;
    if (l == null) return;
    if (qIndex.value < l.questions.length - 1) {
      qIndex.value++;
      selected.value = null;
      answered.value = false;
      correct.value  = false;
      selectedWords.clear();
      wordBank.clear();
      _initWordBank();
    } else {
      _finish();
    }
  }

  void _finish() {
    final l = lesson.value;
    if (l == null) return;
    _storage.addXp(xp.value);
    _storage.completeLesson(l.lessonId);
    phase.value = 'done';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(LessonController());
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Obx(() {
        if (ctrl.loading.value) return const _LoadingView();
        if (ctrl.errMsg.value != null) {
          return _ErrorView(msg: ctrl.errMsg.value!, onRetry: ctrl._load);
        }
        return switch (ctrl.phase.value) {
          'intro'     => _IntroPhase(ctrl: ctrl),
          'vocab'     => _VocabPhase(ctrl: ctrl),
          'grammar'   => _GrammarPhase(ctrl: ctrl),
          'questions' => _QuestionPhase(ctrl: ctrl),
          'done'      => _DonePhase(ctrl: ctrl),
          _           => const _LoadingView(),
        };
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE: INTRO
// ─────────────────────────────────────────────────────────────────────────────
class _IntroPhase extends StatelessWidget {
  final LessonController ctrl;
  const _IntroPhase({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final l = ctrl.lesson.value!;
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(children: [
          // close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              GestureDetector(onTap: () => Get.back(),
                child: const Icon(Icons.close, color: AppColors.textMuted, size: 28)),
            ]),
          ),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // emoji + title
              Row(children: [
                Text(l.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.titleNative, style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                  Text(l.title, style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary, fontFamily: 'Nunito')),
                ])),
              ]),
              const SizedBox(height: 20),
              // hook card
              _InfoCard(
                color: AppColors.saffronLight,
                border: AppColors.saffron,
                icon: '💡',
                title: 'Yeh kyun seekhna chahiye?',
                body: l.hookNative,
              ),
              const SizedBox(height: 14),
              // goal card
              _InfoCard(
                color: AppColors.primaryLight,
                border: AppColors.primary,
                icon: '🎯',
                title: 'Is lesson ke baad tum kar sakte ho:',
                body: l.goalNative,
              ),
              const SizedBox(height: 14),
              // accent card
              _InfoCard(
                color: AppColors.indigoLight,
                border: AppColors.indigo,
                icon: '🎤',
                title: 'Accent ke baare mein:',
                body: l.culturalConfidenceNote['messageNative'] ??
                    'Indian accent is perfectly fine. Sundar Pichai Indian accent mein bolte hain!',
              ),
              const SizedBox(height: 14),
              // meta chips
              Row(children: [
                _MetaChip('⏱️', '${l.estimatedMinutes} min'),
                const SizedBox(width: 8),
                _MetaChip('⚡', '${l.xpReward * 10} XP'),
                const SizedBox(width: 8),
                _MetaChip('📚', '${l.vocabulary.length} words'),
                const SizedBox(width: 8),
                _MetaChip('❓', '${l.questions.length} Q\'s'),
              ]),
            ],
          ))),
          // CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: _DuoBtn(text: 'Start Lesson', onTap: ctrl.startLesson),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE: VOCABULARY
// ─────────────────────────────────────────────────────────────────────────────
class _VocabPhase extends StatefulWidget {
  final LessonController ctrl;
  const _VocabPhase({required this.ctrl});
  @override State<_VocabPhase> createState() => _VocabPhaseState();
}

class _VocabPhaseState extends State<_VocabPhase> {
  int _idx = 0;
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final vocab = widget.ctrl.lesson.value!.vocabulary;
    final item  = vocab[_idx];
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Column(children: [
        _TopBar(
          onClose: () => Get.back(),
          center: Text('Words  ${_idx + 1}/${vocab.length}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, fontFamily: 'Nunito')),
        ),
        XpBar(value: (_idx + 1) / vocab.length, color: AppColors.gold, height: 10),
        Expanded(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          const SizedBox(height: 8),
          // Flip card
          GestureDetector(
            onTap: () => setState(() => _flipped = !_flipped),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _flipped ? _VocabBack(item: item, key: const ValueKey('back'))
                              : _VocabFront(item: item, key: const ValueKey('front')),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tap card to flip', style: TextStyle(
            fontSize: 12, color: AppColors.textMuted, fontFamily: 'Nunito')),
          const SizedBox(height: 20),
          // Indian mistake highlight
          if (item.indiansSayWrong.isNotEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorLight, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Text('⚠️', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text('Common Indian Mistake:', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: AppColors.error, fontFamily: 'Nunito')),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _MistakeChip(item.indiansSayWrong, isWrong: true)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 18)),
                  Expanded(child: _MistakeChip(item.correctEnglish, isWrong: false)),
                ]),
                if (item.whyWrong.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(item.whyWrong, style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Nunito')),
                ],
              ]),
            ),
          const SizedBox(height: 12),
          // Memory trick
          if (item.memoryTrick.isNotEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Text('🧠', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(item.memoryTrick, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary, fontFamily: 'Nunito'))),
              ]),
            ),
        ]))),
        // Navigation
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Row(children: [
            if (_idx > 0) Expanded(child: _DuoBtn(
              text: '← Back', outlined: true,
              onTap: () => setState(() { _idx--; _flipped = false; }))),
            if (_idx > 0) const SizedBox(width: 12),
            Expanded(child: _DuoBtn(
              text: _idx < vocab.length - 1 ? 'Next Word →' : 'Go to Grammar →',
              onTap: () {
                if (_idx < vocab.length - 1) {
                  setState(() { _idx++; _flipped = false; });
                } else {
                  widget.ctrl.goGrammar();
                }
              },
            )),
          ]),
        ),
      ])),
    );
  }
}

class _VocabFront extends StatelessWidget {
  final VocabItem item;
  const _VocabFront({required this.item, super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, height: 200,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF00BFA5)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3),
        blurRadius: 16, offset: const Offset(0, 8))]),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(item.english, style: const TextStyle(
        fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Nunito')),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20)),
        child: Text(item.pronunciationRoman, style: const TextStyle(
          fontSize: 14, color: Colors.white, fontFamily: 'Nunito'))),
      const SizedBox(height: 6),
      Text(item.wordType.toUpperCase(), style: const TextStyle(
        fontSize: 11, color: Colors.white60, fontFamily: 'Nunito', letterSpacing: 1)),
    ]),
  );
}

class _VocabBack extends StatelessWidget {
  final VocabItem item;
  const _VocabBack({required this.item, super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, height: 200,
    decoration: BoxDecoration(
      color: AppColors.indigoLight,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.indigo.withValues(alpha: 0.3), width: 2)),
    child: Padding(padding: const EdgeInsets.all(20), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.native, style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: AppColors.indigo, fontFamily: 'Nunito')),
        const SizedBox(height: 8),
        Text(item.pronunciation, style: const TextStyle(
          fontSize: 14, color: AppColors.textMuted, fontFamily: 'Nunito')),
        if (item.hinglishBridge.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.bgWhite, borderRadius: BorderRadius.circular(10)),
            child: Text('→ ${item.hinglishBridge}', style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary, fontFamily: 'Nunito'))),
        ],
      ],
    )),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE: GRAMMAR
// ─────────────────────────────────────────────────────────────────────────────
class _GrammarPhase extends StatelessWidget {
  final LessonController ctrl;
  const _GrammarPhase({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final g = ctrl.lesson.value!.grammarPoint;
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Column(children: [
        _TopBar(onClose: () => Get.back(),
          center: const Text('Grammar', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary, fontFamily: 'Nunito'))),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.titleNative, style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900,
              color: AppColors.textPrimary, fontFamily: 'Nunito')),
            const SizedBox(height: 14),
            _InfoCard(color: AppColors.indigoLight, border: AppColors.indigo,
              icon: '📖', title: 'Explanation:', body: g.explanationNative),
            const SizedBox(height: 14),
            // Language comparison
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.bgWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Language Structure Comparison', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: AppColors.textMuted, fontFamily: 'Nunito')),
                const SizedBox(height: 10),
                Text(g.nativeLanguageComparison, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary, fontFamily: 'Nunito')),
              ]),
            ),
            const SizedBox(height: 14),
            // Mistake → fix
            Row(children: [
              Expanded(child: _MistakeBox(g.commonIndianMistake, isWrong: true)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 22)),
              Expanded(child: _MistakeBox(g.correctedForm, isWrong: false)),
            ]),
            const SizedBox(height: 14),
            _InfoCard(color: AppColors.goldLight, border: AppColors.gold,
              icon: '💡', title: 'Simple Rule:', body: g.simpleRule),
            const SizedBox(height: 14),
            // Examples
            if (g.examples.isNotEmpty) ...[
              const Text('More Examples:', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary, fontFamily: 'Nunito')),
              const SizedBox(height: 10),
              ...g.examples.map((ex) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('❌ ', style: TextStyle(fontSize: 14)),
                      Expanded(child: Text(ex['wrong'] ?? '', style: const TextStyle(
                        fontSize: 14, color: AppColors.error, fontFamily: 'Nunito',
                        decoration: TextDecoration.lineThrough))),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Text('✅ ', style: TextStyle(fontSize: 14)),
                      Expanded(child: Text(ex['right'] ?? '', style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark, fontFamily: 'Nunito'))),
                    ]),
                    if ((ex['nativeThinking'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(ex['nativeThinking']!, style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted,
                        fontFamily: 'Nunito', fontStyle: FontStyle.italic)),
                    ],
                  ]),
                ),
              )),
            ],
          ],
        ))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: _DuoBtn(text: 'Start Questions →', onTap: ctrl.goQuestions),
        ),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE: QUESTIONS
// ─────────────────────────────────────────────────────────────────────────────
class _QuestionPhase extends StatelessWidget {
  final LessonController ctrl;
  const _QuestionPhase({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final q = ctrl.currentQ;
      if (q == null) return const _LoadingView();
      return Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(child: Column(children: [
          _QTopBar(ctrl: ctrl),
          _QProgressBar(ctrl: ctrl),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _QTypeLabel(q: q),
              const SizedBox(height: 18),
              _QPrompt(q: q),
              const SizedBox(height: 24),
              if (q.indianMistakeWarning != null)
                Padding(padding: const EdgeInsets.only(bottom: 14),
                  child: _WarningChip(q.indianMistakeWarning!)),
              _QInput(ctrl: ctrl, q: q),
            ]),
          )),
          _QBottomBar(ctrl: ctrl, q: q),
        ])),
      );
    });
  }
}

class _QTopBar extends StatelessWidget {
  final LessonController ctrl;
  const _QTopBar({required this.ctrl});
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bgWhite,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Obx(() => Row(children: [
      GestureDetector(onTap: () => Get.back(),
        child: const Icon(Icons.close, color: AppColors.textMuted, size: 28)),
      const Spacer(),
      Row(children: List.generate(5, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(Icons.favorite, size: 22,
          color: i < ctrl.hearts.value ? AppColors.heart : AppColors.border)))),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Text('⚡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('${ctrl.xp.value} XP', style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.gold, fontFamily: 'Nunito')),
        ]),
      ),
    ])),
  );
}

class _QProgressBar extends StatelessWidget {
  final LessonController ctrl;
  const _QProgressBar({required this.ctrl});
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bgWhite,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    child: Obx(() => XpBar(value: ctrl.progress, color: AppColors.primary, height: 10)),
  );
}

class _QTypeLabel extends StatelessWidget {
  final QuestionModel q;
  const _QTypeLabel({required this.q});
  @override
  Widget build(BuildContext context) {
    final labels = {
      QuestionType.translateToEnglish: ('🔤', 'Translate to English'),
      QuestionType.fixMistake:         ('❌', 'Fix the Mistake'),
      QuestionType.fillBlank:          ('✏️', 'Fill the Blank'),
      QuestionType.matchSituation:     ('🎯', 'Match the Situation'),
      QuestionType.speak:              ('🎙️', 'Speak English'),
      QuestionType.arrangeWords:       ('🔀', 'Arrange the Words'),
      QuestionType.listenSelect:       ('👂', 'Listen & Select'),
    };
    final diffColors = {
      'easy': AppColors.success, 'medium': AppColors.gold, 'hard': AppColors.saffron};
    final label = labels[q.type] ?? ('📚', 'Question');
    final dc = diffColors[q.difficulty] ?? AppColors.textMuted;
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.indigoLight, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label.$1, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label.$2, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.indigo, fontFamily: 'Nunito')),
        ])),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: dc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: dc.withValues(alpha: 0.3))),
        child: Text(q.difficulty.toUpperCase(), style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w800, color: dc, fontFamily: 'Nunito'))),
    ]);
  }
}

class _QPrompt extends StatelessWidget {
  final QuestionModel q;
  const _QPrompt({required this.q});
  @override
  Widget build(BuildContext context) {
    final isFix = q.type == QuestionType.fixMistake;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (q.promptNative != null)
        Text(q.promptNative!, style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: AppColors.textPrimary, fontFamily: 'Nunito', height: 1.3)),
      if (isFix && q.promptEnglish != null) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.4))),
          child: Row(children: [
            const Text('❌ ', style: TextStyle(fontSize: 20)),
            Expanded(child: Text(q.promptEnglish!, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.error, fontFamily: 'Nunito'))),
          ])),
      ] else if (!isFix && q.promptEnglish != null) ...[
        const SizedBox(height: 8),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.bgWhite, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
          child: Text(q.promptEnglish!, style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary, fontFamily: 'Nunito'))),
      ],
    ]);
  }
}

class _QInput extends StatelessWidget {
  final LessonController ctrl;
  final QuestionModel q;
  const _QInput({required this.ctrl, required this.q});
  @override
  Widget build(BuildContext context) => switch (q.type) {
    QuestionType.arrangeWords => _ArrangeInput(ctrl: ctrl, q: q),
    QuestionType.speak        => _SpeakInput(ctrl: ctrl, q: q),
    _                         => _OptionsInput(ctrl: ctrl, q: q),
  };
}

class _OptionsInput extends StatelessWidget {
  final LessonController ctrl;
  final QuestionModel q;
  const _OptionsInput({required this.ctrl, required this.q});
  @override
  Widget build(BuildContext context) => Obx(() => Column(
    children: q.options.map((opt) {
      Color border = AppColors.border, bg = AppColors.bgWhite, text = AppColors.textPrimary;
      IconData? icon;
      if (ctrl.answered.value) {
        if (ctrl.selected.value == opt) {
          if (ctrl.correct.value) {
            border = AppColors.success; bg = AppColors.successLight;
            text = AppColors.primaryDark; icon = Icons.check_circle;
          } else {
            border = AppColors.error; bg = AppColors.errorLight;
            text = AppColors.error; icon = Icons.cancel;
          }
        } else if (opt == q.correctAnswer) {
          border = AppColors.success; bg = AppColors.successLight;
          text = AppColors.primaryDark; icon = Icons.check_circle;
        }
      }
      return GestureDetector(
        onTap: () => ctrl.pick(opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
            boxShadow: [BoxShadow(color: border.withValues(alpha: 0.2),
              blurRadius: 0, offset: const Offset(0, 3))]),
          child: Row(children: [
            Expanded(child: Text(opt, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: text, fontFamily: 'Nunito'))),
            if (icon != null) Icon(icon, color: border, size: 22),
          ]),
        ),
      );
    }).toList(),
  ));
}

class _ArrangeInput extends StatelessWidget {
  final LessonController ctrl;
  final QuestionModel q;
  const _ArrangeInput({required this.ctrl, required this.q});
  @override
  Widget build(BuildContext context) {
    if (ctrl.wordBank.isEmpty && ctrl.selectedWords.isEmpty) ctrl._initWordBank();
    return Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Sentence builder area
      Container(
        width: double.infinity, constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgWhite, borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ctrl.answered.value
              ? (ctrl.correct.value ? AppColors.success : AppColors.error)
              : AppColors.border, width: 2)),
        child: ctrl.selectedWords.isEmpty
          ? const Text('Tap words below to make a sentence →',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Nunito'))
          : Wrap(spacing: 8, runSpacing: 8,
              children: ctrl.selectedWords.map((w) => GestureDetector(
                onTap: () => ctrl.untapWord(w),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.indigoLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.indigo.withValues(alpha: 0.4)),
                    boxShadow: [BoxShadow(color: AppColors.indigo.withValues(alpha: 0.25),
                      offset: const Offset(0, 2))]),
                  child: Text(w, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.indigo, fontFamily: 'Nunito'))),
              )).toList()),
      ),
      const SizedBox(height: 20),
      // Word bank
      const Text('Available words:', style: TextStyle(
        fontSize: 12, color: AppColors.textMuted, fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8,
        children: ctrl.wordBank.map((w) => GestureDetector(
          onTap: () => ctrl.tapWord(w),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppColors.bgWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: const [BoxShadow(color: AppColors.border,
                offset: Offset(0, 3), blurRadius: 0)]),
            child: Text(w, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, fontFamily: 'Nunito'))),
        )).toList()),
    ]));
  }
}

class _SpeakInput extends StatelessWidget {
  final LessonController ctrl;
  final QuestionModel q;
  const _SpeakInput({required this.ctrl, required this.q});
  @override
  Widget build(BuildContext context) => Obx(() => Column(
    children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.indigoLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.indigo.withValues(alpha: 0.3))),
        child: Column(children: [
          const Text('🎙️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(q.correctAnswer, textAlign: TextAlign.center, style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w900,
            color: AppColors.indigo, fontFamily: 'Nunito')),
          if (q.pronunciationGuide != null) ...[
            const SizedBox(height: 8),
            Text(q.pronunciationGuide!, style: const TextStyle(
              fontSize: 14, color: AppColors.textMuted, fontFamily: 'Nunito')),
          ],
        ])),
      const SizedBox(height: 24),
      if (!ctrl.answered.value)
        GestureDetector(
          onTap: () => ctrl.submitSpeak(q.correctAnswer), // real STT hook point
          child: Container(
            width: 88, height: 88,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.indigo,
              boxShadow: [BoxShadow(color: AppColors.indigo.withValues(alpha: 0.4),
                blurRadius: 24, offset: const Offset(0, 8))]),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 40))),
      if (ctrl.answered.value)
        Icon(ctrl.correct.value ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: ctrl.correct.value ? AppColors.success : AppColors.error, size: 72),
    ]));
}

class _QBottomBar extends StatelessWidget {
  final LessonController ctrl;
  final QuestionModel q;
  const _QBottomBar({required this.ctrl, required this.q});
  @override
  Widget build(BuildContext context) => Obx(() {
    if (!ctrl.answered.value) {
      return Container(
        color: AppColors.bgWhite, padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: AppColors.bgSection,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2)),
          child: const Center(child: Text('SELECT AN ANSWER', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w900,
            color: AppColors.textMuted, fontFamily: 'Nunito', letterSpacing: 0.5)))));
    }
    final ok = ctrl.correct.value;
    final totalQ = ctrl.lesson.value?.questions.length ?? 1;
    final isLast = ctrl.qIndex.value >= totalQ - 1;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: ok ? AppColors.successLight : AppColors.errorLight,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: ok ? AppColors.success : AppColors.error, size: 26),
            const SizedBox(width: 10),
            Text(ok ? 'Sahi hai! 🎉' : 'Galat! Ek aur baar try karo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
                color: ok ? AppColors.primaryDark : AppColors.error, fontFamily: 'Nunito')),
            if (ok) ...[const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                child: Text('+${q.points * 10} XP', style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Nunito')))],
          ]),
          if (q.explanationNative != null) ...[
            const SizedBox(height: 8),
            Text(q.explanationNative!, style: TextStyle(
              fontSize: 13, color: ok ? AppColors.primaryDark : AppColors.textSecondary,
              fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
          ],
          if (!ok && q.wrongAnswerExplanations[ctrl.selected.value ?? ''] != null) ...[
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡 ', style: TextStyle(fontSize: 13)),
              Expanded(child: Text(q.wrongAnswerExplanations[ctrl.selected.value!]!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Nunito'))),
            ]),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: ctrl.next,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: ok ? AppColors.primary : AppColors.error,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: ok ? AppColors.primaryDark : const Color(0xFFCC0000),
                  offset: const Offset(0, 4), blurRadius: 0)]),
              child: Center(child: Text(isLast ? 'FINISH LESSON' : 'CONTINUE',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
                  color: Colors.white, fontFamily: 'Nunito', letterSpacing: 0.5))))),
          const SizedBox(height: 8),
        ])));
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PHASE: DONE
// ─────────────────────────────────────────────────────────────────────────────
class _DonePhase extends StatelessWidget {
  final LessonController ctrl;
  const _DonePhase({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    final l = ctrl.lesson.value!;
    final summary = l.summary;
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(child: Column(children: [
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text('Lesson Complete!', style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900,
              color: AppColors.textPrimary, fontFamily: 'Nunito')),
            const SizedBox(height: 6),
            Text(l.confidenceBooster['messageNative'] ?? 'Bahut acha kiya!',
              textAlign: TextAlign.center, style: const TextStyle(
                fontSize: 15, color: AppColors.textMuted, fontFamily: 'Nunito')),
            const SizedBox(height: 28),
            // Stats row
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _StatBox('⚡', '+${ctrl.xp.value}', 'XP Earned', AppColors.xpBlue, const Color(0xFFE3F5FD)),
              _StatBox('❤️', '${ctrl.hearts.value}/5', 'Hearts', AppColors.heart, AppColors.roseLight),
              _StatBox('📚', '${summary['wordsLearned'] ?? l.vocabulary.length}', 'Words', AppColors.indigo, AppColors.indigoLight),
            ]),
            const SizedBox(height: 20),
            // Today's challenge
            if (l.confidenceBooster['todayChallenge'] != null)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Text('🎯', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Today's Challenge:", style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark, fontFamily: 'Nunito')),
                    const SizedBox(height: 4),
                    Text(l.confidenceBooster['todayChallenge']!, style: const TextStyle(
                      fontSize: 14, color: AppColors.primaryDark, fontFamily: 'Nunito')),
                  ])),
                ])),
            const SizedBox(height: 16),
            // Next lesson preview
            if ((summary['nextLessonPreviewNative'] ?? '').toString().isNotEmpty)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Text('🔜', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(summary['nextLessonPreviewNative'].toString(),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Nunito'))),
                ])),
            // Indian mistakes learned
            if (l.indianMistakesSpecial.isNotEmpty) ...[
              const SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child: const Text('Mistakes you fixed today:', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary, fontFamily: 'Nunito'))),
              const SizedBox(height: 10),
              ...l.indianMistakesSpecial.take(2).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.bgPage,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Expanded(child: Text(m.wrong, style: const TextStyle(
                      fontSize: 13, color: AppColors.error, fontFamily: 'Nunito',
                      decoration: TextDecoration.lineThrough))),
                    const Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 16),
                    Expanded(child: Text(m.right, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark, fontFamily: 'Nunito'))),
                  ])))),
            ],
          ],
        ))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: _DuoBtn(text: 'Continue', onTap: () => Get.back())),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING / ERROR
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgPage,
    body: SafeArea(child: Column(children: [
      _TopBar(onClose: () => Get.back(),
        center: const Text('Loading...', style: TextStyle(
          fontSize: 14, color: AppColors.textMuted, fontFamily: 'Nunito'))),
      Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🤖', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        const Text('AI tera lesson bana raha hai...', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
            color: AppColors.textPrimary, fontFamily: 'Nunito')),
        const SizedBox(height: 8),
        const Text('Just a few seconds ⏳', style: TextStyle(
          fontSize: 14, color: AppColors.textMuted, fontFamily: 'Nunito')),
        const SizedBox(height: 36),
        const SizedBox(width: 220, child: LinearProgressIndicator(
          backgroundColor: AppColors.bgSection,
          valueColor: AlwaysStoppedAnimation(AppColors.primary))),
      ]))),
    ])),
  );
}

class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgPage,
    body: SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('😕', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 20),
        const Text('Lesson load nahi hua', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: AppColors.textPrimary, fontFamily: 'Nunito')),
        const SizedBox(height: 8),
        Text(msg, textAlign: TextAlign.center, style: const TextStyle(
          fontSize: 14, color: AppColors.textMuted, fontFamily: 'Nunito')),
        const SizedBox(height: 32),
        _DuoBtn(text: 'Try Again', onTap: onRetry),
      ]),
    ))),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED MICRO-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final Widget? center;
  const _TopBar({required this.onClose, this.center});
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bgWhite,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(children: [
      GestureDetector(onTap: onClose,
        child: const Icon(Icons.close, color: AppColors.textMuted, size: 28)),
      const Spacer(),
      if (center != null) center!,
      const Spacer(),
      const SizedBox(width: 28),
    ]));
}

class _DuoBtn extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool outlined;
  const _DuoBtn({required this.text, this.onTap, this.outlined = false});
  @override State<_DuoBtn> createState() => _DuoBtnState();
}
class _DuoBtnState extends State<_DuoBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.outlined ? AppColors.bgWhite : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: widget.outlined ? Border.all(color: AppColors.border, width: 2) : null,
          boxShadow: _pressed ? [] : [BoxShadow(
            color: widget.outlined ? AppColors.border : AppColors.primaryDark,
            offset: const Offset(0, 4), blurRadius: 0)]),
        child: Center(child: Text(widget.text, style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w900, fontFamily: 'Nunito',
          color: widget.outlined ? AppColors.textPrimary : Colors.white))))));
}

class _InfoCard extends StatelessWidget {
  final Color color, border;
  final String icon, title, body;
  const _InfoCard({required this.color, required this.border,
    required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border.withValues(alpha: 0.4), width: 1.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
          color: border, fontFamily: 'Nunito')),
      ]),
      const SizedBox(height: 8),
      Text(body, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, fontFamily: 'Nunito', height: 1.5)),
    ]));
}

class _MetaChip extends StatelessWidget {
  final String icon, label;
  const _MetaChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: AppColors.bgSection, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.textSecondary, fontFamily: 'Nunito')),
    ]));
}

class _MistakeChip extends StatelessWidget {
  final String text;
  final bool isWrong;
  const _MistakeChip(this.text, {required this.isWrong});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: isWrong ? AppColors.errorLight : AppColors.successLight,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: isWrong ? AppColors.error.withValues(alpha: 0.4) : AppColors.success.withValues(alpha: 0.4))),
    child: Text(text, textAlign: TextAlign.center, style: TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: isWrong ? AppColors.error : AppColors.primaryDark,
      fontFamily: 'Nunito',
      decoration: isWrong ? TextDecoration.lineThrough : null)));
}

class _MistakeBox extends StatelessWidget {
  final String text;
  final bool isWrong;
  const _MistakeBox(this.text, {required this.isWrong});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isWrong ? AppColors.errorLight : AppColors.successLight,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isWrong ? AppColors.error.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3))),
    child: Column(children: [
      Text(isWrong ? '❌' : '✅', style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 6),
      Text(text, textAlign: TextAlign.center, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700,
        color: isWrong ? AppColors.error : AppColors.primaryDark,
        fontFamily: 'Nunito',
        decoration: isWrong ? TextDecoration.lineThrough : null)),
    ]));
}

class _WarningChip extends StatelessWidget {
  final String msg;
  const _WarningChip(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4))),
    child: Row(children: [
      const Text('⚠️', style: TextStyle(fontSize: 16)),
      const SizedBox(width: 8),
      Expanded(child: Text('Indian mistake: $msg', style: const TextStyle(
        fontSize: 12, color: AppColors.gold, fontFamily: 'Nunito', fontWeight: FontWeight.w600))),
    ]));
}

class _StatBox extends StatelessWidget {
  final String emoji, value, label;
  final Color color, bg;
  const _StatBox(this.emoji, this.value, this.label, this.color, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
        color: color, fontFamily: 'Nunito')),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Nunito')),
    ]));
}
