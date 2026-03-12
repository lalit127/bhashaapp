import 'package:bhashaapp/shared/models/lesson_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class ApiService extends GetxService {
  static const String _baseUrl =
      'https://bhashabackend-production.up.railway.app/api/v1';

  late final Dio _dio;
  final isLoading = false.obs;
  final error     = RxnString();

  // ── Enum sanitizers ────────────────────────────────────────────
  static String _lang(String v) =>
      const {
        'hi': 'hindi',    'hin': 'hindi',    'hindi': 'hindi',
        'gu': 'gujarati', 'guj': 'gujarati', 'gujarati': 'gujarati',
        'ta': 'tamil',    'tam': 'tamil',    'tamil': 'tamil',
        'te': 'telugu',   'tel': 'telugu',   'telugu': 'telugu',
        'mr': 'marathi',  'mar': 'marathi',  'marathi': 'marathi',
        'bn': 'bengali',  'ben': 'bengali',  'bengali': 'bengali',
      }[v.toLowerCase()] ?? 'hindi';

  static String _cefr(String v) =>
      const {
        'a1': 'A1', 'A1': 'A1', 'beginner': 'A1',
        'a2': 'A2', 'A2': 'A2', 'elementary': 'A2',
        'b1': 'B1', 'B1': 'B1', 'intermediate': 'B1',
        'b2': 'B2', 'B2': 'B2', 'upperinter': 'B2',
        'c1': 'C1', 'C1': 'C1', 'advanced': 'C1',
      }[v] ?? 'A1';

  static String _goal(String v) =>
      const {
        'job': 'job', 'work': 'job', 'career': 'job',
        'daily': 'daily', 'everyday': 'daily',
        'social': 'social', 'friends': 'social',
        'travel': 'travel',
        'exam': 'exam', 'test': 'exam',
        'business': 'business',
      }[v.toLowerCase()] ?? 'daily';

  static String _occ(String v) =>
      const {
        'student': 'student',
        'software': 'software_engineer',
        'software_engineer': 'software_engineer',
        'it': 'software_engineer',
        'sales': 'sales',
        'teacher': 'teacher',
        'doctor': 'doctor',
        'shopkeeper': 'shopkeeper',
        'driver': 'driver',
        'housewife': 'housewife',
        'office_worker': 'office_worker',
        'office': 'office_worker',
        'fresher': 'fresher',
      }[v.toLowerCase()] ?? 'student';

  // ── Init ───────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl:        _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
      headers:        {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          try {
            final resp = await _dio.fetch(e.requestOptions);
            handler.resolve(resp);
            return;
          } catch (_) {}
        }
        handler.next(e);
      },
    ));
  }

  // ── Roadmap ────────────────────────────────────────────────────
  Future<RoadmapModel?> getRoadmap({
    required String nativeLanguage,
    String goal       = 'daily',
    String currentLevel = 'A1',
    String ageGroup   = '18-25',
    String occupation = 'student',
  }) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.post('/roadmap', data: {
        'native_language': _lang(nativeLanguage),
        'goal':            _goal(goal),
        'current_level':   _cefr(currentLevel),
        'age_group':       ageGroup,
        'occupation':      _occ(occupation),
      });
      return RoadmapModel.fromJson(resp.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // ── Standard Lesson (legacy — use getLesson(skillId) for v4) ───
  Future<LessonModel?> getLegacyLesson({
    required String nativeLanguage,
    required String skillId,
    required String skillName,
    int    lessonNumber  = 1,
    int    totalLessons  = 3,
    String cefrLevel     = 'A1',
    String goal          = 'daily',
    String occupation    = 'student',
    String cityTier      = 'metro',
    List<String> weakAreas    = const [],
    int    questionCount = 12,
  }) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.post('/lesson', data: {
        'native_language': _lang(nativeLanguage),
        'skill_id':        skillId,
        'skill_name':      skillName,
        'lesson_number':   lessonNumber,
        'total_lessons':   totalLessons,
        'cefr_level':      _cefr(cefrLevel),
        'goal':            _goal(goal),
        'occupation':      _occ(occupation),
        'city_tier':       cityTier,
        'weak_areas':      weakAreas,
        'question_count':  questionCount,
      });
      return LessonModel.fromJson(resp.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // ── Chat sync ──────────────────────────────────────────────────
  Future<Map<String, dynamic>?> sendChatMessage({
    required String nativeLanguage,
    required String cefrLevel,
    required String occupation,
    required String topic,
    required String sessionGoal,
    required String userMessage,
    List<Map<String, String>> history = const [],
    int fearScore = 5,
  }) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.post('/chat/sync', data: {
        'native_language': _lang(nativeLanguage),
        'cefr_level':      _cefr(cefrLevel),
        'occupation':      _occ(occupation),
        'topic':           topic,
        'session_goal':    sessionGoal,
        'user_message':    userMessage,
        'history':         history,
        'fear_score':      fearScore,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // ── Pronunciation ──────────────────────────────────────────────
  Future<Map<String, dynamic>?> analyzePronunciation({
    required String nativeLanguage,
    required String targetPhrase,
    required String sttResult,
    String cefrLevel = 'A1',
  }) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.post('/pronunciation', data: {
        'native_language': _lang(nativeLanguage),
        'target_phrase':   targetPhrase,
        'stt_result':      sttResult,
        'cefr_level':      _cefr(cefrLevel),
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // ── Grammar ────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> explainGrammar({
    required String nativeLanguage,
    required String wrongSentence,
    required String correctSentence,
    String cefrLevel   = 'A1',
    String mistakeType = 'general',
  }) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.post('/grammar', data: {
        'native_language':  _lang(nativeLanguage),
        'wrong_sentence':   wrongSentence,
        'correct_sentence': correctSentence,
        'cefr_level':       _cefr(cefrLevel),
        'mistake_type':     mistakeType,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // ── Story ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getDailyStory({
    required String nativeLanguage,
    required String cefrLevel,
    required String topic,
    String occupation        = 'student',
    List<String> newWords    = const [],
    String length            = 'medium',
  }) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.post('/story', data: {
        'native_language': _lang(nativeLanguage),
        'cefr_level':      _cefr(cefrLevel),
        'topic':           topic,
        'occupation':      _occ(occupation),
        'new_words':       newWords,
        'length':          length,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // ── WhatsApp Coach ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> fixMessage({
    required String nativeLanguage,
    required String originalMessage,
    required String context,
    String formality = 'professional',
  }) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.post('/whatsapp-coach', data: {
        'native_language':  _lang(nativeLanguage),
        'original_message': originalMessage,
        'context':          context,
        'formality':        formality,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // =================================================================
  // =================================================================
  // SPEAKING PRACTICE  (v4 — reads static JSON + 3 AI eval endpoints)
  // =================================================================

  // ── Load content index (call once on app start) ────────────────
  // Returns index.json from static files — lists all 59 skills,
  // which ones are free, and their lesson file paths.
  Future<Map<String, dynamic>?> getContentIndex() async {
    try {
      final resp = await _dio.get('/content/index.json');
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    }
  }

  // ── Load 7-day roadmap ─────────────────────────────────────────
  Future<Map<String, dynamic>?> getRoadmapContent() async {
    try {
      final resp = await _dio.get('/content/roadmap/roadmap.json');
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    }
  }

  // ── Load a single lesson (static JSON, instant) ────────────────
  // skillId examples: "s1_greet", "s2_past_tense", "s3_interview"
  //
  // Returned JSON has these top-level keys:
  //   title, hook, grammar_card, activities[], lesson_xp, completion_hindi
  //
  // activities[] items each have a "type" field:
  //   word_card, pick_correct, fill_blank, translate_drill,
  //   dialogue, spot_mistake, sentence_builder, speak_aloud,
  //   nova_chat, real_world
  Future<Map<String, dynamic>?> getLesson(String skillId) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.get('/content/lessons/$skillId.json');
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // ── Evaluate translate_drill answer ───────────────────────────
  // Called after user types their Hindi→English translation.
  //
  // Returns:
  //   is_correct bool, score 0-100, mistake_type string,
  //   mistake_hindi string, correction string,
  //   feedback_hindi string, partial_credit bool
  Future<Map<String, dynamic>?> evaluateTranslation({
    required String skillId,
    required String hindiSentence,
    required String expectedEnglish,
    required String userAnswer,
  }) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.post('/speaking/evaluate/translation', data: {
        'skill_id':        skillId,
        'hindi_sentence':   hindiSentence,
        'expected_english': expectedEnglish,
        'user_answer':      userAnswer,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // ── Evaluate speak_aloud recording (STT transcript) ───────────
  // Pass the Flutter STT transcript string here.
  //
  // Returns:
  //   score 0-100, is_acceptable bool, missing_words [],
  //   grammar_error_hindi, pronunciation_tip_hindi,
  //   feedback_hindi, try_again bool
  Future<Map<String, dynamic>?> evaluateSpeech({
    required String skillId,
    required String targetSentence,
    required String transcript,
  }) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.post('/speaking/evaluate/speech', data: {
        'skill_id':       skillId,
        'target_sentence': targetSentence,
        'transcript':      transcript,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // ── One turn of Nova AI chat (nova_chat activity) ─────────────
  // Pass grammar_rule + sentence_pattern from the lesson JSON.
  // history is a list of {role: "user"|"nova", content: "..."} maps.
  //
  // Returns:
  //   nova_reply string, used_target_grammar bool,
  //   correction_needed bool, correction_hindi string,
  //   corrected_sentence string, encouragement_hindi string
  Future<Map<String, dynamic>?> sendToNova({
    required String skillId,
    required String skillName,
    required String grammarRule,
    required String sentencePattern,
    required String userMessage,
    List<Map<String, String>> history = const [],
    String nativeLanguage = 'hindi',
  }) async {
    try {
      isLoading.value = true; error.value = null;
      final resp = await _dio.post('/speaking/nova/chat', data: {
        'skill_id':         skillId,
        'skill_name':       skillName,
        'grammar_rule':     grammarRule,
        'sentence_pattern': sentencePattern,
        'user_message':     userMessage,
        'history':          history,
        'native_language':  _lang(nativeLanguage),
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    } finally { isLoading.value = false; }
  }

  // ── TTS: English audio (word_card, speak_aloud, dialogue) ──────
  // Returns raw MP3 bytes. Play with just_audio:
  //   await player.setAudioSource(
  //     AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg')));
  //   await player.play();
  Future<List<int>?> getEnglishAudio(String text, {bool slow = false}) async {
    try {
      final resp = await _dio.post(
        '/tts/english',
        data: {'text': text, 'slow': slow},
        options: Options(responseType: ResponseType.bytes),
      );
      return resp.data as List<int>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    }
  }

  // ── TTS: Hindi audio (instruction_hindi, feedback_hindi) ───────
  Future<List<int>?> getHindiAudio(String text) async {
    try {
      final resp = await _dio.post(
        '/tts/native',
        data: {'text': text, 'native_language': 'hindi'},
        options: Options(responseType: ResponseType.bytes),
      );
      return resp.data as List<int>;
    } on DioException catch (e) {
      error.value = _parseError(e); return null;
    }
  }

  // ── Error parser ───────────────────────────────────────────────
  String _parseError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is List && detail.isNotEmpty) {
          return detail
              .map((d) => '${(d['loc'] as List?)?.last ?? 'field'}: ${d['msg']}')
              .join(', ');
        }
        return detail.toString();
      }
      return 'Server error ${e.response!.statusCode}';
    }
    if (e.type == DioExceptionType.connectionTimeout) return 'Connection timeout';
    if (e.type == DioExceptionType.receiveTimeout)    return 'AI is thinking... retry';
    return e.message ?? 'Unknown error';
  }
}