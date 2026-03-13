// lib/services/gemini_service.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService extends GetxService {
  static const _apiKey = 'AIzaSyD2EbayzS-HzEj5wrY3iyn0uShj0t4aya8';

  late final GenerativeModel _flash;
  late final GenerativeModel _pro;

  @override
  void onInit() {
    super.onInit();
    _flash = GenerativeModel(
      model:  'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
    _pro = GenerativeModel(
      model:  'gemini-2.5-pro',
      apiKey: _apiKey,
    );
  }

  // ── Instant grammar correction ─────────────────────────────────
  // Called from nova_chat activity when user sends a message
  Future<Map<String, dynamic>> correctGrammar({
    required String userMessage,
    required String cefrLevel,
    required String nativeLanguage,
  }) async {
    final prompt = '''
You are Miss Mira, a friendly English tutor for Indian learners.
Student level: $cefrLevel
Student native language: $nativeLanguage
Student said: "$userMessage"

Respond in JSON only:
{
  "has_error": bool,
  "corrected": "corrected sentence if error, else same",
  "error_type": "grammar|spelling|word_choice|none",
  "explanation_hindi": "brief explanation in Hindi if error",
  "nova_reply": "your encouraging reply continuing the conversation",
  "encouragement": "short Hindi encouragement"
}
''';
    final resp = await _flash.generateContent([Content.text(prompt)]);
    final text = resp.text ?? '{}';
    final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    return jsonDecode(clean) as Map<String, dynamic>;
  }

  // ── Generate personalized tip ──────────────────────────────────
  Future<String> getDailyTip({
    required String cefrLevel,
    required String weakArea,
    required String nativeLanguage,
  }) async {
    final resp = await _flash.generateContent([Content.text(
        'Give a 1-sentence English learning tip for a $nativeLanguage speaker '
            'at $cefrLevel level struggling with $weakArea. '
            'Reply in Hindi + English. Keep it under 20 words each language.'
    )]);
    return resp.text ?? '';
  }

  // ── Nova chat (multi-turn, skill-focused) ─────────────────────
  Future<Map<String, dynamic>?> miraChat({
    required String skillId,
    required String skillName,
    required String grammarRule,
    required String sentencePattern,
    required String userMessage,
    required String nativeLang,
    required String cefrLevel,
    List<Map<String, String>> history = const [],
  }) async {
    final hist = history
        .map((h) => '${h['role']?.toUpperCase()}: ${h['content']}')
        .join('\n');
    final prompt = '''
You are Mira, a warm English tutor for Indian learners.
Skill: "$skillName", Grammar rule: "$grammarRule"
Sentence pattern to practise: "$sentencePattern"
Student level: $cefrLevel, Native language: $nativeLang

Conversation so far:
$hist

Student just said: "$userMessage"

Respond in JSON only:
{
  "reply": "your English reply (2-3 sentences, $cefrLevel appropriate)",
  "reply_translation": "translation of your reply in $nativeLang",
  "grammar_note": {
    "has_error": false,
    "error_text": "exact wrong phrase from student, or empty string",
    "correction": "corrected form",
    "explanation": "why it is wrong in $nativeLang"
  },
  "encouragement": "short warm encouragement in $nativeLang",
  "xp_this_turn": 5
}
Rules: correct max 1 mistake; be warm; if no error set has_error: false and leave error_text as empty string.
''';
    try {
      final resp  = await _flash.generateContent([Content.text(prompt)]);
      final text  = resp.text ?? '{}';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }


  // ── Generate full lesson ───────────────────────────────────────
  Future<Map<String, dynamic>?> generateLesson({
    required String skillId,
    required String skillName,
    required String nativeLanguage,
    required String cefrLevel,
    int lessonNumber = 1,
    int totalLessons = 3,
    String goal         = 'daily',
    String occupation   = 'student',
  }) async {
    final prompt = '''
Create an English lesson for an Indian learner.
Skill: "$skillName" (id: $skillId), Lesson $lessonNumber of $totalLessons
native=$nativeLanguage, CEFR=$cefrLevel, goal=$goal, occupation=$occupation

Respond in JSON only:
{
  "lessonId": "${skillId}_l$lessonNumber",
  "title": "lesson title in English",
  "titleNative": "title in $nativeLanguage",
  "emoji": "📚",
  "skillId": "$skillId",
  "cefrLevel": "$cefrLevel",
  "orderIndex": $lessonNumber,
  "xpReward": 5,
  "estimatedMinutes": 12,
  "requiresPro": false,
  "hookNative": "why this matters — 1 sentence in $nativeLanguage",
  "goalNative": "what you will achieve — 1 sentence in $nativeLanguage",
  "goalEnglish": "what you will achieve in English",
  "culturalConfidenceNote": {
    "messageNative": "Indian accent is perfectly fine — note in $nativeLanguage",
    "examplePerson": "Sundar Pichai"
  },
  "vocabulary": [
    {
      "english": "word",
      "native": "word in $nativeLanguage",
      "pronunciation": "phonetic in Roman script",
      "pronunciationRoman": "say it like: ...",
      "wordType": "noun",
      "indiansSayWrong": "common Indian mistake",
      "correctEnglish": "correct version",
      "whyWrong": "why in $nativeLanguage",
      "hinglishBridge": "Hinglish bridge phrase",
      "fullEnglish": "example sentence",
      "desiExample": {"context": "Indian daily life example"},
      "memoryTrick": "trick in $nativeLanguage",
      "audioScript": "word"
    }
  ],
  "grammarPoint": {
    "titleNative": "rule name in $nativeLanguage",
    "explanationNative": "explanation in $nativeLanguage",
    "nativeLanguageComparison": "$nativeLanguage structure vs English",
    "commonIndianMistake": "typical mistake",
    "whyMistakeNative": "why in $nativeLanguage",
    "correctedForm": "correct English",
    "simpleRule": "one rule in $nativeLanguage",
    "examples": [
      {
        "wrong": "wrong sentence",
        "right": "correct sentence",
        "nativeThinking": "what Indian speaker thought in $nativeLanguage"
      }
    ]
  },
  "dialogue": {
    "context": "Indian daily life scenario in $nativeLanguage",
    "lines": [
      {
        "speaker": "A",
        "english": "line",
        "native": "$nativeLanguage translation",
        "pronunciation": "phonetic",
        "audioScript": "line",
        "tipNative": null
      }
    ]
  },
  "questions": [
    {
      "questionId": "q1",
      "type": "translate_to_english",
      "difficulty": "easy",
      "points": 1,
      "promptNative": "prompt in $nativeLanguage",
      "promptEnglish": null,
      "options": ["correct answer", "wrong 1", "wrong 2", "wrong 3"],
      "correctAnswer": "correct answer",
      "wrongAnswerExplanations": {"wrong 1": "why wrong in $nativeLanguage"},
      "hintNative": "hint in $nativeLanguage",
      "explanationNative": "explanation in $nativeLanguage",
      "indianMistakeWarning": null,
      "audioScript": null,
      "pronunciationGuide": null,
      "acceptanceThreshold": 0.7,
      "jumbledWords": null
    }
  ],
  "speakingPractice": [
    {
      "id": "sp1",
      "level": "beginner",
      "english": "sentence to speak",
      "native": "$nativeLanguage translation",
      "pronunciation": "phonetic",
      "audioScript": "sentence",
      "contextNote": "when to use in $nativeLanguage",
      "accentTip": "tip in $nativeLanguage",
      "indianMistake": "common Indian pronunciation mistake"
    }
  ],
  "indianMistakesSpecial": [
    {
      "wrong": "Indian English phrase",
      "right": "correct phrase",
      "nativeExplanation": "in $nativeLanguage",
      "howToRemember": "in $nativeLanguage"
    }
  ],
  "summary": {
    "wordsLearned": 6,
    "nextLessonPreviewNative": "next lesson preview in $nativeLanguage"
  },
  "confidenceBooster": {
    "messageNative": "encouragement in $nativeLanguage",
    "todayChallenge": "real life challenge in $nativeLanguage"
  }
}

RULES:
- vocabulary: exactly 6 items, use Indian names (Rahul, Priya) in examples
- questions: exactly 12 — 3×translate_to_english, 2×translate_to_native, 2×fix_mistake,
  2×fill_blank, 1×match_situation, 1×arrange_words (add jumbledWords array), 1×speak (add pronunciationGuide)
- options: always 4 items, correctAnswer must exactly match one option
- dialogue: 4-6 lines alternating A and B
- speakingPractice: 5 sentences beginner→intermediate→advanced
''';
    try {
      final resp  = await _flash.generateContent([Content.text(prompt)]);
      final text  = resp.text ?? '{}';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Evaluate translation answer ────────────────────────────────
  Future<Map<String, dynamic>?> evaluateTranslation({
    required String nativeLanguage,
    required String nativeSentence,
    required String expectedEnglish,
    required String userAnswer,
    String cefrLevel = 'A1',
  }) async {
    final prompt = '''
You are evaluating an English translation answer from an Indian learner.
Native language: $nativeLanguage, CEFR: $cefrLevel

Original ($nativeLanguage): "$nativeSentence"
Expected English: "$expectedEnglish"
Student answered: "$userAnswer"

Respond in JSON only:
{
  "is_correct": true,
  "accepted": true,
  "score": 85,
  "feedback": "feedback in $nativeLanguage",
  "correction": "corrected English if wrong, else same as expected",
  "partial_credit": false
}

RULES:
- is_correct: true only if answer is exactly or near-exactly right
- accepted: true if score >= 70 (allow minor spelling/word order variations)
- score: 0-100
- Be lenient with Indian English variations that convey the correct meaning
- feedback: always in $nativeLanguage, warm and encouraging
''';
    try {
      final resp  = await _flash.generateContent([Content.text(prompt)]);
      final text  = resp.text ?? '{}';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Generate roadmap ───────────────────────────────────────────
  Future<Map<String, dynamic>?> generateRoadmap({
    required String nativeLanguage,
    required String cefrLevel,
    String goal       = 'daily',
    String occupation = 'student',
    String ageGroup   = '18-25',
  }) async {
    final prompt = '''
Generate a personalized English learning roadmap for an Indian learner.
native_language=$nativeLanguage, goal=$goal, current_level=$cefrLevel, occupation=$occupation, age=$ageGroup

Respond in JSON only:
{
  "language": "$nativeLanguage",
  "baseLanguage": "english",
  "tagline": "short motivational tagline in $nativeLanguage",
  "taglineEnglish": "English Learning Journey",
  "totalSkills": 12,
  "estimatedWeeks": 8,
  "milestones": [],
  "stages": [
    {
      "stageId": "stage_1",
      "stageName": "stage name in $nativeLanguage",
      "stageNameEnglish": "Foundations",
      "stageSlogan": "slogan in $nativeLanguage",
      "cefrEquivalent": "A1",
      "colorHex": "#FF6B2B",
      "iconEmoji": "🌱",
      "estimatedDays": 21,
      "requiresPro": false,
      "whatYouLearn": ["outcome 1 in $nativeLanguage", "outcome 2", "outcome 3"],
      "skills": [
        {
          "skillId": "greetings_basics",
          "skillName": "short name in $nativeLanguage (max 10 chars)",
          "skillNameEnglish": "Greetings",
          "skillTagline": "tagline in $nativeLanguage",
          "iconEmoji": "👋",
          "colorHex": "#4CAF50",
          "xpRequired": 0,
          "totalLessons": 3,
          "vocabularyCount": 8,
          "prerequisites": [],
          "lessonIds": [],
          "positionX": 0.5,
          "positionY": 0.12,
          "requiresPro": false,
          "realLifeScenario": "when you use this in $nativeLanguage",
          "confidentWith": "what you can do after in $nativeLanguage",
          "keyPhrases": [
            {
              "english": "Good morning!",
              "native": "$nativeLanguage translation",
              "pronunciation": "Good MOR-ning",
              "when": "morning greeting context",
              "neverSay": "common wrong version Indians use"
            }
          ]
        }
      ]
    }
  ]
}

RULES:
- Exactly 3 stages
- Stage 1: 5 skills, requiresPro: false. Stage 2: 4 skills, requiresPro: false. Stage 3: 3 skills, requiresPro: true
- positionX: zigzag alternating 0.3 / 0.7 across skills within each stage
- positionY: evenly spaced 0.12 to 0.88 within each stage
- xpRequired: 0 for first skill, then +100 per skill cumulative across all stages
- All skillIds: unique snake_case relevant to $occupation with $goal goal
- colorHex per skill, vary among: ["#FF6B2B","#4CAF50","#00BFA5","#5C6BC0","#FF4081","#FFB800","#9C27B0","#E91E63"]
- Stage colorHex = its first skill colorHex
- 2 keyPhrases per skill
''';
    try {
      final resp  = await _flash.generateContent([Content.text(prompt)]);
      final text  = resp.text ?? '{}';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}