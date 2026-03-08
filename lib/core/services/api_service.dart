import 'dart:convert';
import 'package:bhashaapp/shared/models/lesson_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class ApiService extends GetxService {
  static const String _baseUrl = 'http://YOUR_SERVER_IP:8000/api/v1';
  // For local dev: 'http://10.0.2.2:8000/api/v1' (Android emulator)
  // For prod: 'https://api.bhashaapp.com/api/v1'

  late final Dio _dio;

  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60), // AI generation can be slow
      headers: {'Content-Type': 'application/json'},
    ));

    // Logging interceptor (debug only)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true, responseBody: false, // don't log full AI responses
    ));

    // Retry interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          // Retry once on timeout
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

  // ── Roadmap ────────────────────────────────────────────────────────────────

  Future<RoadmapModel?> getRoadmap({
    required String nativeLanguage,
    String goal = 'daily',
    String currentLevel = 'A1',
    String ageGroup = '18-25',
    String occupation = 'student',
  }) async {
    try {
      isLoading.value = true;
      error.value = null;
      final resp = await _dio.post('/roadmap', data: {
        'native_language': nativeLanguage,
        'goal': goal,
        'current_level': currentLevel,
        'age_group': ageGroup,
        'occupation': occupation,
      });
      return RoadmapModel.fromJson(resp.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      error.value = _parseError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Standard Lesson ────────────────────────────────────────────────────────

  Future<LessonModel?> getLesson({
    required String nativeLanguage,
    required String skillId,
    required String skillName,
    int lessonNumber = 1,
    int totalLessons = 3,
    String cefrLevel = 'A1',
    String goal = 'daily',
    String occupation = 'student',
    String cityTier = 'metro',
    List<String> weakAreas = const [],
    int questionCount = 12,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;
      final resp = await _dio.post('/lesson', data: {
        'native_language': nativeLanguage,
        'skill_id': skillId,
        'skill_name': skillName,
        'lesson_number': lessonNumber,
        'total_lessons': totalLessons,
        'cefr_level': cefrLevel,
        'goal': goal,
        'occupation': occupation,
        'city_tier': cityTier,
        'weak_areas': weakAreas,
        'question_count': questionCount,
      });
      return LessonModel.fromJson(resp.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      error.value = _parseError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Adaptive Lesson ────────────────────────────────────────────────────────

  Future<LessonModel?> getAdaptiveLesson({
    required String nativeLanguage,
    required String skillId,
    required String skillName,
    required int totalXp,
    required int streak,
    required int lessonsDone,
    required double accuracy,
    required double hoursInactive,
    List<String> weakTopics = const [],
    List<String> strongTopics = const [],
    String mistakeType = '',
    List<String> confusedPairs = const [],
    String cefrLevel = 'A1',
    String goal = 'daily',
    String occupation = 'student',
  }) async {
    try {
      isLoading.value = true;
      error.value = null;
      final resp = await _dio.post('/lesson/adaptive', data: {
        'native_language': nativeLanguage,
        'skill_id': skillId,
        'skill_name': skillName,
        'lesson_number': 1,
        'total_lessons': 3,
        'cefr_level': cefrLevel,
        'goal': goal,
        'occupation': occupation,
        'city_tier': 'metro',
        'weak_areas': weakTopics,
        'question_count': 12,
        'total_xp': totalXp,
        'streak': streak,
        'lessons_done': lessonsDone,
        'accuracy': accuracy,
        'hours_inactive': hoursInactive,
        'strong_topics': strongTopics,
        'weak_topics': weakTopics,
        'mistake_type': mistakeType,
        'confused_pairs': confusedPairs,
        'recent_skills': [],
      });
      return LessonModel.fromJson(resp.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      error.value = _parseError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Chat (sync) ────────────────────────────────────────────────────────────

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
      isLoading.value = true;
      error.value = null;
      final resp = await _dio.post('/chat/sync', data: {
        'native_language': nativeLanguage,
        'cefr_level': cefrLevel,
        'occupation': occupation,
        'topic': topic,
        'session_goal': sessionGoal,
        'user_message': userMessage,
        'history': history,
        'fear_score': fearScore,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Pronunciation Analysis ─────────────────────────────────────────────────

  Future<Map<String, dynamic>?> analyzePronunciation({
    required String nativeLanguage,
    required String targetPhrase,
    required String sttResult,
    String cefrLevel = 'A1',
  }) async {
    try {
      isLoading.value = true;
      error.value = null;
      final resp = await _dio.post('/pronunciation', data: {
        'native_language': nativeLanguage,
        'target_phrase': targetPhrase,
        'stt_result': sttResult,
        'cefr_level': cefrLevel,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Grammar Explanation ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> explainGrammar({
    required String nativeLanguage,
    required String wrongSentence,
    required String correctSentence,
    String cefrLevel = 'A1',
    String mistakeType = 'general',
  }) async {
    try {
      isLoading.value = true;
      error.value = null;
      final resp = await _dio.post('/grammar', data: {
        'native_language': nativeLanguage,
        'wrong_sentence': wrongSentence,
        'correct_sentence': correctSentence,
        'cefr_level': cefrLevel,
        'mistake_type': mistakeType,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Daily Story ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getDailyStory({
    required String nativeLanguage,
    required String cefrLevel,
    required String topic,
    String occupation = 'student',
    List<String> newWords = const [],
    String length = 'medium',
  }) async {
    try {
      isLoading.value = true;
      error.value = null;
      final resp = await _dio.post('/story', data: {
        'native_language': nativeLanguage,
        'cefr_level': cefrLevel,
        'topic': topic,
        'occupation': occupation,
        'new_words': newWords,
        'length': length,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── WhatsApp Coach ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fixMessage({
    required String nativeLanguage,
    required String originalMessage,
    required String context,
    String formality = 'professional',
  }) async {
    try {
      isLoading.value = true;
      error.value = null;
      final resp = await _dio.post('/whatsapp-coach', data: {
        'native_language': nativeLanguage,
        'original_message': originalMessage,
        'context': context,
        'formality': formality,
      });
      return resp.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      error.value = _parseError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _parseError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['detail'] != null) return data['detail'].toString();
      return 'Server error ${e.response!.statusCode}';
    }
    if (e.type == DioExceptionType.connectionTimeout) return 'Connection timeout — check your internet';
    if (e.type == DioExceptionType.receiveTimeout) return 'AI is thinking... please retry';
    return e.message ?? 'Unknown error';
  }
}
