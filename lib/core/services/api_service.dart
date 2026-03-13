// lib/core/services/api_service.dart
// Gemini 2.0 Flash — replaces Railway/Mistral. Same signatures.
// Run: flutter run --dart-define=GEMINI_API_KEY=AIza...

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../shared/models/lesson_model.dart';

const _kKey   = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyD2EbayzS-HzEj5wrY3iyn0uShj0t4aya8');
const _kBase  = 'https://generativelanguage.googleapis.com/v1beta/models';
const _kModel = 'gemini-2.5-flash-lite';

const _maxRetries = 2;

String _lang(String v) =>
    const {
      'hi': 'hindi', 'hin': 'hindi', 'hindi': 'hindi',
      'gu': 'gujarati', 'guj': 'gujarati', 'gujarati': 'gujarati',
      'ta': 'tamil',    'tam': 'tamil',    'tamil': 'tamil',
      'te': 'telugu',   'tel': 'telugu',   'telugu': 'telugu',
      'mr': 'marathi',  'mar': 'marathi',  'marathi': 'marathi',
      'bn': 'bengali',  'ben': 'bengali',  'bengali': 'bengali',
    }[v.toLowerCase()] ??
        'hindi';

String _cefr(String v) =>
    const {
      'a1': 'A1', 'A1': 'A1', 'beginner': 'A1',
      'a2': 'A2', 'A2': 'A2', 'elementary': 'A2',
      'b1': 'B1', 'B1': 'B1', 'intermediate': 'B1',
      'b2': 'B2', 'B2': 'B2',
      'c1': 'C1', 'C1': 'C1', 'advanced': 'C1',
    }[v] ??
        'A1';

class ApiService extends GetxService {
  late final Dio _dio;
  final isLoading = false.obs;
  final error     = RxnString();

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl:        _kBase,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
      headers:        {'Content-Type': 'application/json'},
    ));
  }

  // ── Core generate (max 2 retries on 429, respects retry-after) ────────────
  Future<Map<String, dynamic>?> _generate(String prompt,
      {double temp = 0.7}) async {
    int attempt = 0;

    while (attempt <= _maxRetries) {
      try {
        final resp = await _dio.post(
          '/$_kModel:generateContent?key=$_kKey',
          data: {
            'contents': [
              {
                'parts': [{'text': prompt}],
                'role': 'user'
              }
            ],
            'generationConfig': {
              'temperature':      temp,
              'topP':             0.95,
              'maxOutputTokens':  8192,
              'responseMimeType': 'application/json',
            },
            'safetySettings': [
              {'category': 'HARM_CATEGORY_HARASSMENT',        'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_HATE_SPEECH',       'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
              {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
            ],
          },
        );
        final text = resp.data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text == null) return null;
        var t = text.trim();
        if (t.startsWith('```')) {
          t = t.replaceAll(RegExp(r'^```[a-z]*\n?'), '').replaceAll('```', '').trim();
        }
        return jsonDecode(t) as Map<String, dynamic>;

      } on DioException catch (e) {
        final isRateLimit = e.response?.statusCode == 429;

        if (isRateLimit && attempt < _maxRetries) {
          final retryAfter = _parseRetryAfter(e) ?? Duration(seconds: 30 * (attempt + 1));
          Get.log('[ApiService] 429 — retry ${attempt + 1}/$_maxRetries after ${retryAfter.inSeconds}s');
          await Future.delayed(retryAfter);
          attempt++;
          continue;
        }

        final msg = _extractError(e);
        error.value = msg;
        Get.log('[ApiService] Error (attempt ${attempt + 1}): $msg');
        return null;
      }
    }

    return null;
  }

  /// Extracts the human-readable error message from a DioException.
  String _extractError(DioException e) {
    if (e.response != null) {
      final d = e.response!.data;
      if (d is Map) {
        final geminiMsg = (d['error'] as Map?)?['message']?.toString();
        if (geminiMsg != null) return geminiMsg;
        return 'HTTP ${e.response!.statusCode}';
      }
      return 'HTTP ${e.response!.statusCode}';
    }
    return e.message ?? 'Network error';
  }

  /// Parses "Please retry in 35.28s" from the Gemini 429 error body.
  Duration? _parseRetryAfter(DioException e) {
    try {
      final d = e.response?.data;
      final message = d is Map
          ? (d['error'] as Map?) != null?['message']?.toString() ?? ''
          : '';
      final match = RegExp(r'retry in ([\d.]+)s').firstMatch(message);
      if (match != null) {
        final seconds = double.tryParse(match.group(1) ?? '');
        if (seconds != null && seconds > 0 && seconds <= 120) {
          return Duration(seconds: seconds.ceil());
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Roadmap ───────────────────────────────────────────────────────────────
  Future<RoadmapModel?> getRoadmap({
    required String nativeLanguage,
    String goal        = 'daily',
    String currentLevel = 'A1',
    String ageGroup    = '18-25',
    String occupation  = 'student',
  }) async {
    isLoading.value = true;
    error.value     = null;
    try {
      final lang  = _lang(nativeLanguage);
      final level = _cefr(currentLevel);
      final data  = await _generate('''
Generate a personalized English learning roadmap for an Indian learner.
native_language=$lang, goal=$goal, current_level=$level, occupation=$occupation, age=$ageGroup.

Return ONLY valid JSON:
{
  "language": "$lang", "baseLanguage": "english",
  "tagline": "short tagline in $lang", "taglineEnglish": "Learn English Step by Step",
  "totalSkills": 12, "estimatedWeeks": 8, "milestones": [],
  "stages": [
    {
      "stageId": "stage_1", "stageName": "naam in $lang", "stageNameEnglish": "Foundations",
      "stageSlogan": "slogan in $lang", "cefrEquivalent": "$level", "colorHex": "#FF6B2B",
      "iconEmoji": "🌱", "estimatedDays": 14, "requiresPro": false,
      "whatYouLearn": ["item in $lang 1", "item 2", "item 3"],
      "skills": [
        {
          "skillId": "unique_snake_id", "skillName": "naam in $lang (max 10 chars)",
          "skillNameEnglish": "English Name", "skillTagline": "tagline in $lang",
          "iconEmoji": "👋", "colorHex": "#4CAF50",
          "xpRequired": 0, "totalLessons": 3, "vocabularyCount": 8,
          "prerequisites": [], "lessonIds": [],
          "positionX": 0.5, "positionY": 0.12,
          "requiresPro": false,
          "realLifeScenario": "When you use this in $lang",
          "embarrassingWithout": "What goes wrong without this in $lang",
          "confidentWith": "What you can do after in $lang",
          "keyPhrases": [
            {"english": "phrase", "native": "$lang translation", "pronunciation": "phonetic", "when": "context", "neverSay": "wrong version"}
          ]
        }
      ]
    }
  ]
}

RULES:
- Exactly 3 stages. Stage 1: 5 skills (requiresPro:false). Stage 2: 4 skills (requiresPro:false). Stage 3: 3 skills (requiresPro:true).
- skill positionX: zigzag 0.25/0.75/0.25..., positionY: evenly spaced from 0.1 to 0.9 within each stage
- xpRequired: 0 for first, +100 per skill sequentially across all stages
- colorHex per skill, vary: ["#FF6B2B","#4CAF50","#00BFA5","#5C6BC0","#FF4081","#FFB800","#9C27B0"]
- stage colorHex = its first skill color
- All skillIds unique snake_case, relevant to $occupation with $goal goal
- 2 keyPhrases per skill
''', temp: 0.5);
      if (data == null) return null;
      return RoadmapModel.fromJson(data);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Lesson ────────────────────────────────────────────────────────────────
  Future<LessonModel?> generateLesson({
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
    isLoading.value = true;
    error.value     = null;
    try {
      final lang  = _lang(nativeLanguage);
      final level = _cefr(cefrLevel);
      final data  = await _generate('''
Create English lesson $lessonNumber/$totalLessons for Indian learner.
Skill: "$skillName" (id: $skillId), native=$lang, CEFR=$level, goal=$goal, occupation=$occupation.
${weakAreas.isNotEmpty ? 'Focus on weak areas: ${weakAreas.join(', ')}' : ''}

Return ONLY valid JSON:
{
  "lessonId": "${skillId}_l$lessonNumber",
  "title": "Lesson title in English", "titleNative": "title in $lang",
  "emoji": "📚", "skillId": "$skillId", "cefrLevel": "$level",
  "orderIndex": $lessonNumber, "xpReward": 5, "estimatedMinutes": 12, "requiresPro": false,
  "hookNative": "Why learn this — 1 sentence in $lang",
  "goalNative": "What you'll achieve in $lang",
  "goalEnglish": "What you'll achieve in English",
  "culturalConfidenceNote": {"messageNative": "Indian accent is fine note in $lang", "examplePerson": "Sundar Pichai"},
  "vocabulary": [
    {
      "english": "word", "native": "$lang word", "pronunciation": "phonetic",
      "pronunciationRoman": "say it like: ...", "wordType": "noun",
      "indiansSayWrong": "common Indian mistake", "correctEnglish": "correct",
      "whyWrong": "why in $lang", "hinglishBridge": "Hinglish bridge",
      "fullEnglish": "example sentence", "desiExample": {"Indian context": "example"},
      "memoryTrick": "trick in $lang", "audioScript": "word"
    }
  ],
  "grammarPoint": {
    "titleNative": "grammar rule in $lang",
    "explanationNative": "explain in $lang",
    "nativeLanguageComparison": "$lang structure vs English",
    "commonIndianMistake": "mistake Indians make",
    "whyMistakeNative": "why in $lang",
    "correctedForm": "correct English",
    "simpleRule": "one rule in $lang",
    "examples": [{"wrong": "wrong", "right": "correct", "nativeThinking": "Indian thinking in $lang"}]
  },
  "dialogue": {
    "context": "Indian daily life scenario in $lang",
    "lines": [
      {"speaker": "A", "english": "Hi!", "native": "$lang", "pronunciation": "Hi!", "audioScript": "Hi!", "tipNative": null}
    ]
  },
  "questions": [
    {
      "questionId": "q1", "type": "translate_to_english", "difficulty": "easy", "points": 1,
      "promptNative": "question in $lang", "promptEnglish": null,
      "options": ["correct answer", "wrong 1", "wrong 2", "wrong 3"],
      "correctAnswer": "correct answer",
      "wrongAnswerExplanations": {"wrong 1": "why wrong in $lang"},
      "hintNative": "hint in $lang", "explanationNative": "explanation in $lang",
      "indianMistakeWarning": null, "audioScript": null, "pronunciationGuide": null,
      "acceptanceThreshold": 0.7, "jumbledWords": null
    }
  ],
  "speakingPractice": [
    {
      "id": "sp1", "level": "beginner",
      "english": "sentence to speak", "native": "$lang translation",
      "pronunciation": "phonetic", "audioScript": "sentence",
      "contextNote": "when to use in $lang",
      "accentTip": "tip in $lang", "indianMistake": "common Indian mistake"
    }
  ],
  "indianMistakesSpecial": [
    {"wrong": "Indian English", "right": "Correct", "nativeExplanation": "in $lang", "howToRemember": "in $lang"}
  ],
  "summary": {"wordsLearned": 6, "nextLessonPreviewNative": "next lesson in $lang"},
  "confidenceBooster": {"messageNative": "encouragement in $lang", "todayChallenge": "challenge in $lang"}
}

RULES:
- vocabulary: 6 items, Indian names/places
- questions: EXACTLY $questionCount items mixing:
  3×translate_to_english, 2×translate_to_native, 2×fix_mistake, 2×fill_blank, 1×match_situation, 1×arrange_words (add jumbledWords array), 1×speak (add pronunciationGuide)
- options: 4 items, correctAnswer must be exactly one of them
- dialogue: 4-6 lines alternating A/B speakers
- speakingSentences: 5 items from easy to hard
''', temp: 0.7);
      if (data == null) return null;
      return LessonModel.fromJson(data);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Alias for compatibility ──
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
  }) => generateLesson(
    nativeLanguage: nativeLanguage,
    skillId: skillId,
    skillName: skillName,
    lessonNumber: lessonNumber,
    totalLessons: totalLessons,
    cefrLevel: cefrLevel,
    goal: goal,
    occupation: occupation,
    cityTier: cityTier,
    weakAreas: weakAreas,
    questionCount: questionCount,
  );

  // ── Chat ──────────────────────────────────────────────────────────────────
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
    isLoading.value = true;
    error.value     = null;
    try {
      final lang  = _lang(nativeLanguage);
      final level = _cefr(cefrLevel);
      final hist  = history
          .map((h) => '${h['role']?.toUpperCase()}: ${h['content']}')
          .join('\n');
      return await _generate('''
You are a friendly English AI tutor for Indian learners.
native=$lang, CEFR=$level, occupation=$occupation, topic=$topic, fearScore=$fearScore/10.

History:
$hist

Student: "$userMessage"

Return ONLY valid JSON:
{
  "turn": {
    "tutorSetupNative": "warm context in $lang (1 sentence)",
    "targetEnglish": "your reply in English (2-3 sentences, appropriate for $level)",
    "correction": {
      "original": "student mistake or null",
      "corrected": "correct form",
      "praiseFirst": "praise in $lang first"
    },
    "encouragementNative": "encouragement in $lang",
    "metrics": {"xpEarned": 5}
  }
}
Be warm. If fearScore>7, be extra gentle. Correct max 1 mistake.
''', temp: 0.8);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Pronunciation ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> analyzePronunciation({
    required String nativeLanguage,
    required String targetPhrase,
    required String sttResult,
    String cefrLevel = 'A1',
  }) async {
    isLoading.value = true;
    error.value     = null;
    try {
      final lang = _lang(nativeLanguage);
      return await _generate('''
Analyze pronunciation for Indian learner. native=$lang, CEFR=${_cefr(cefrLevel)}.
Target: "$targetPhrase" | Got: "$sttResult"
Return ONLY valid JSON:
{"overallScore":78,"feedback":"in $lang","wordScores":[{"word":"w","score":80,"tip":"in $lang"}],"accentTip":"in $lang","encouragement":"in $lang"}
''', temp: 0.3);
    } finally {
      isLoading.value = false;
    }
  }
}

// Stub for app.dart binding
class LiveApiService extends GetxService {}
