// lib/features/voice/controllers/voice_controller.dart

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../services/gemini_live_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/controllers/home_controller.dart';

class VoiceController extends GetxController {
  final _live  = Get.find<GeminiLiveService>();
  final _auth  = Get.find<AuthController>();
  final _home  = Get.find<HomeController>();
  final _repo  = FirestoreRepository();

  // ── Call metadata (passed via Get.arguments) ──────────────────────────────
  late final String topic;
  late final String cefrLevel;
  late final String nativeLang;
  late final String occupation;

  // ── Exposed observables (bind directly in screen) ─────────────────────────
  CallState get callState    => _live.callState.value;
  String    get transcript   => _live.transcript.value;
  String    get aiReply      => _live.aiReply.value;
  int       get sessionScore => _live.sessionScore.value;

  // Local UI state
  final callDurationSec = 0.obs;
  final isEnding        = false.obs;

  // Conversation log for display
  final messages = <_ChatBubble>[].obs;

  late final String _sessionId;
  DateTime?  _startTime;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    topic      = args['topic']      as String? ?? 'Daily conversation';
    cefrLevel  = args['cefrLevel']  as String? ?? _auth.user.value?.cefrLevel  ?? 'A1';
    nativeLang = args['nativeLang'] as String? ?? _auth.user.value?.nativeLanguage ?? 'hindi';
    occupation = args['occupation'] as String? ?? _auth.user.value?.occupation  ?? 'student';
    _sessionId = const Uuid().v4();

    // Bridge service callbacks → local message list
    _live.onTextChunk     = _onAiText;
    _live.onTurnComplete  = _onTurnComplete;
    _live.onError         = (e) => Get.snackbar('Connection Error', e,
        snackPosition: SnackPosition.BOTTOM);

    // Mirror reactive state
    ever(_live.transcript,   (_) => update());
    ever(_live.aiReply,      (_) => update());
    ever(_live.callState,    (_) => update());
    ever(_live.sessionScore, (_) => update());

    _connect();
  }

  Future<void> _connect() async {
    _startTime = DateTime.now();
    _startTimer();
    await _live.connect(
      cefrLevel:   cefrLevel,
      topic:       topic,
      occupation:  occupation, nativeLang: nativeLang,
    );
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!isEnding.value && _live.callState.value != CallState.idle) {
        callDurationSec.value++;
        return true;
      }
      return false;
    });
  }

  String get formattedDuration {
    final m = callDurationSec.value ~/ 60;
    final s = callDurationSec.value  % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  // ── Mic controls ──────────────────────────────────────────────────────────
  void startSpeaking() {
    _live.startRecording();
    messages.add(_ChatBubble(isUser: true, text: '...'));
  }

  void stopSpeaking() {
    _live.stopRecording();
    // Update last user bubble with transcript
    if (messages.isNotEmpty && messages.last.isUser) {
      messages.last = _ChatBubble(
          isUser: true, text: _live.transcript.value.isNotEmpty
              ? _live.transcript.value : '(speaking...)');
    }
  }

  // ── AI text handler ───────────────────────────────────────────────────────
  String _currentAiMsg = '';
  bool   _aiMsgStarted = false;

  void _onAiText(String chunk) {
    _currentAiMsg += chunk;
    if (!_aiMsgStarted) {
      _aiMsgStarted = true;
      messages.add(_ChatBubble(isUser: false, text: _currentAiMsg));
    } else {
      // Update last AI bubble
      if (messages.isNotEmpty && !messages.last.isUser) {
        messages.last = _ChatBubble(isUser: false, text: _currentAiMsg);
      }
    }
    messages.refresh();
  }

  void _onTurnComplete() {
    _currentAiMsg = '';
    _aiMsgStarted = false;
    _live.aiReply.value = '';
  }

  // ── End call ──────────────────────────────────────────────────────────────
  Future<void> endCall() async {
    isEnding.value = true;
    await _live.disconnect();

    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds : 0;
    final xp = (duration ~/ 10).clamp(0, AppK.xpPerVoice);

    // Save session to Firestore
    await _repo.saveSession(_auth.uid, SessionLog(
      sessionId:       _sessionId,
      type:            'voice',
      topic:           topic,
      durationSeconds: duration,
      xpEarned:        xp,
      score:           sessionScore,
      startedAt:       _startTime ?? DateTime.now(),
    ));

    await _repo.addXp(_auth.uid, xp);
    await _home.onVoiceSessionComplete(xp);
    Get.back();
  }

  @override
  void onClose() {
    _live.onTextChunk    = null;
    _live.onTurnComplete = null;
    _live.onError        = null;
    if (_live.callState.value != CallState.idle) {
      _live.disconnect();
    }
    super.onClose();
  }
}

class _ChatBubble {
  final bool   isUser;
  String text;
  _ChatBubble({required this.isUser, required this.text});
}
