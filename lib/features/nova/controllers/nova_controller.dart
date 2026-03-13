// lib/features/nova/controllers/nova_controller.dart

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../services/gemini_service.dart';
import '../../../services/tts_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../../data/models/user_model.dart';


class MiraMessage {
  final String  id;
  final bool    isUser;
  final String  text;
  final String? translation;
  final String? grammarNote;
  final String? encouragement;
  final int     xp;
  final DateTime time;

  MiraMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.translation,
    this.grammarNote,
    this.encouragement,
    this.xp = 0,
    required this.time,
  });
}

class MiraController extends GetxController {
  final _gemini = Get.find<GeminiService>();
  final _tts    = Get.find<TtsService>();
  final _auth   = Get.find<AuthController>();
  final _home   = Get.find<HomeController>();
  final _repo   = FirestoreRepository();

  // ── Args (Get.arguments) ──────────────────────────────────────────────────
  late final String skillId;
  late final String skillName;
  late final String grammarRule;
  late final String sentencePattern;

  // ── Observables ───────────────────────────────────────────────────────────
  final messages   = <MiraMessage>[].obs;
  final isTyping   = false.obs;
  final totalXp    = 0.obs;
  final errorMsg   = RxnString();

  // Internal history for multi-turn context
  final List<Map<String, String>> _history = [];
  late final String _sessionId;
  DateTime? _startTime;

  @override
  void onInit() {
    super.onInit();
    final args   = Get.arguments as Map<String, dynamic>? ?? {};
    skillId          = args['skillId']          as String? ?? '';
    skillName        = args['skillName']        as String? ?? 'English Practice';
    grammarRule      = args['grammarRule']      as String? ?? '';
    sentencePattern  = args['sentencePattern']  as String? ?? '';
    _sessionId       = const Uuid().v4();
    _startTime       = DateTime.now();
    _sendWelcome();
  }

  // ── Send welcome from Mira ────────────────────────────────────────────────
  Future<void> _sendWelcome() async {
    final user = _auth.user.value;
    final lang = user?.nativeLanguage ?? 'hindi';
    final welcome = MiraMessage(
      id:          const Uuid().v4(),
      isUser:      false,
      text:        "Hi! I'm Mira 👋 Let's practice \"$skillName\" together. "
                   "Try using: $sentencePattern",
      translation: null,
      time:        DateTime.now(),
    );
    messages.add(welcome);
    await _tts.speakEnglish(welcome.text);
  }

  // ── Send user message ─────────────────────────────────────────────────────
  Future<void> send(String text) async {
    if (text.trim().isEmpty || isTyping.value) return;

    final user    = _auth.user.value;
    final userMsg = MiraMessage(
      id:     const Uuid().v4(),
      isUser: true,
      text:   text.trim(),
      time:   DateTime.now(),
    );
    messages.add(userMsg);
    _history.add({'role': 'user', 'content': text.trim()});

    isTyping.value = true;
    errorMsg.value = null;

    try {
      final resp = await _gemini.miraChat(
        skillId:         skillId,
        skillName:       skillName,
        grammarRule:     grammarRule,
        sentencePattern: sentencePattern,
        userMessage:     text.trim(),
        nativeLang:      user?.nativeLanguage ?? 'hindi',
        cefrLevel:       user?.cefrLevel      ?? 'A1',
        history:         List.from(_history),
      );

      if (resp == null) {
        errorMsg.value = 'Mira is thinking… please retry.';
        return;
      }

      final reply       = resp['reply']               as String? ?? '';
      final translation = resp['reply_translation']   as String?;
      final encourage   = resp['encouragement']       as String?;
      final xpTurn      = resp['xp_this_turn']        as int?    ?? AppK.xpPerChat;

      // Grammar note
      String? grammarNote;
      final gn = resp['grammar_note'] as Map?;
      if (gn?['has_error'] == true) {
        final err  = gn?['error_text']  as String? ?? '';
        final fix  = gn?['correction']  as String? ?? '';
        final exp  = gn?['explanation'] as String? ?? '';
        grammarNote = '❌ "$err" → ✅ "$fix"\n$exp';
      }

      final novaMsg = MiraMessage(
        id:           const Uuid().v4(),
        isUser:       false,
        text:         reply,
        translation:  translation,
        grammarNote:  grammarNote,
        encouragement: encourage,
        xp:           xpTurn,
        time:         DateTime.now(),
      );

      messages.add(novaMsg);
      _history.add({'role': 'assistant', 'content': reply});
      totalXp.value += xpTurn;

      // Speak reply
      await _tts.speakEnglish(reply);

      // Save XP every 5 turns
      if (_history.length % 10 == 0) _flushXp();

    } catch (e) {
      errorMsg.value = 'Error: $e';
    } finally {
      isTyping.value = false;
    }
  }

  // ── Speak any message ─────────────────────────────────────────────────────
  Future<void> speakMessage(String text) => _tts.speakEnglish(text);
  Future<void> speakNative(String text) {
    final lang = _auth.user.value?.nativeLanguage ?? 'hindi';
    return _tts.speakNative(text, lang);
  }

  // ── Flush XP to Firestore ─────────────────────────────────────────────────
  Future<void> _flushXp() async {
    if (totalXp.value == 0) return;
    await _repo.addXp(_auth.uid, totalXp.value);
    totalXp.value = 0;
  }

  // ── End session ───────────────────────────────────────────────────────────
  Future<void> endSession() async {
    await _flushXp();
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds : 0;
    await _repo.saveSession(_auth.uid, SessionLog(
      sessionId:       _sessionId,
      type:            'nova_chat',
      topic:           skillName,
      durationSeconds: duration,
      xpEarned:        totalXp.value,
      score:           _calcScore(),
      startedAt:       _startTime ?? DateTime.now(),
    ));
    final updated = await _repo.getUser(_auth.uid);
    if (updated != null) _auth.user.value = updated;
    Get.back();
  }

  int _calcScore() {
    final turns = _history.where((h) => h['role'] == 'user').length;
    return (turns * 10).clamp(0, 100);
  }

  @override
  void onClose() {
    _tts.stop();
    super.onClose();
  }
}

// Needed import
