
// ── Question Types
enum QuestionType { translateToEnglish, translateToNative, fixMistake, fillBlank, matchSituation, speak, arrangeWords, listenSelect }

class VocabItem {
  final String english, native, pronunciation, pronunciationRoman, wordType;
  final String indiansSayWrong, correctEnglish, whyWrong, hinglishBridge, fullEnglish;
  final Map<String, String> desiExample;
  final String memoryTrick, audioScript;
  const VocabItem({required this.english, required this.native, required this.pronunciation,
    required this.pronunciationRoman, required this.wordType, required this.indiansSayWrong,
    required this.correctEnglish, required this.whyWrong, required this.hinglishBridge,
    required this.fullEnglish, required this.desiExample, required this.memoryTrick, required this.audioScript});
  factory VocabItem.fromJson(Map<String, dynamic> j) => VocabItem(
    english: j['english']??'', native: j['native']??'', pronunciation: j['pronunciation']??'',
    pronunciationRoman: j['pronunciationRoman']??'', wordType: j['wordType']??'word',
    indiansSayWrong: j['indiansSayWrong']??'', correctEnglish: j['correctEnglish']??'',
    whyWrong: j['whyWrong']??'', hinglishBridge: j['hinglishBridge']??'',
    fullEnglish: j['fullEnglish']??'', desiExample: Map<String,String>.from(j['desiExample']??{}),
    memoryTrick: j['memoryTrick']??'', audioScript: j['audioScript']??'');
}

class GrammarPoint {
  final String titleNative, explanationNative, nativeLanguageComparison;
  final String commonIndianMistake, whyMistakeNative, correctedForm, simpleRule;
  final List<Map<String,String>> examples;
  const GrammarPoint({required this.titleNative, required this.explanationNative,
    required this.nativeLanguageComparison, required this.commonIndianMistake,
    required this.whyMistakeNative, required this.correctedForm, required this.simpleRule, required this.examples});
  factory GrammarPoint.fromJson(Map<String,dynamic> j) => GrammarPoint(
    titleNative: j['titleNative']??'', explanationNative: j['explanationNative']??'',
    nativeLanguageComparison: j['nativeLanguageComparison']??'',
    commonIndianMistake: j['commonIndianMistake']??'', whyMistakeNative: j['whyMistakeNative']??'',
    correctedForm: j['correctedForm']??'', simpleRule: j['simpleRule']??'',
    examples: (j['examples'] as List? ?? []).map((e) => Map<String,String>.from(e)).toList());
}

class DialogueLine {
  final String speaker, english, native, pronunciation, audioScript;
  final String? tipNative;
  const DialogueLine({required this.speaker, required this.english, required this.native,
    required this.pronunciation, required this.audioScript, this.tipNative});
  factory DialogueLine.fromJson(Map<String,dynamic> j) => DialogueLine(
    speaker: j['speaker']??'', english: j['english']??'', native: j['native']??'',
    pronunciation: j['pronunciation']??'', audioScript: j['audioScript']??'', tipNative: j['tipNative']);
}

class QuestionModel {
  final String questionId, difficulty, correctAnswer;
  final QuestionType type;
  final int points;
  final String? promptNative, promptEnglish, hintNative, explanationNative, indianMistakeWarning, audioScript, pronunciationGuide;
  final List<String> options;
  final List<String>? jumbledWords;
  final Map<String,String> wrongAnswerExplanations;
  final double acceptanceThreshold;
  const QuestionModel({required this.questionId, required this.type, required this.difficulty,
    required this.points, this.promptNative, this.promptEnglish, required this.options,
    this.jumbledWords, required this.correctAnswer, required this.wrongAnswerExplanations,
    this.hintNative, this.explanationNative, this.indianMistakeWarning, this.audioScript,
    this.pronunciationGuide, this.acceptanceThreshold = 0.70});
  factory QuestionModel.fromJson(Map<String,dynamic> j) {
    const typeMap = {
      'translate_to_english': QuestionType.translateToEnglish,
      'translate_to_native': QuestionType.translateToNative,
      'fix_mistake': QuestionType.fixMistake,
      'fill_blank': QuestionType.fillBlank,
      'match_situation': QuestionType.matchSituation,
      'speak': QuestionType.speak,
      'arrange_words': QuestionType.arrangeWords,
      'listen_select': QuestionType.listenSelect,
    };
    return QuestionModel(
      questionId: j['questionId']??'', type: typeMap[j['type']]??QuestionType.translateToEnglish,
      difficulty: j['difficulty']??'easy', points: j['points']??1,
      promptNative: j['promptNative'], promptEnglish: j['promptEnglish'],
      options: (j['options'] as List? ?? []).map((e) => e.toString()).toList(),
      jumbledWords: (j['jumbledWords'] as List?)?.map((e) => e.toString()).toList(),
      correctAnswer: j['correctAnswer']??'',
      wrongAnswerExplanations: Map<String,String>.from(j['wrongAnswerExplanations']??{}),
      hintNative: j['hintNative'], explanationNative: j['explanationNative'],
      indianMistakeWarning: j['indianMistakeWarning'], audioScript: j['audioScript'],
      pronunciationGuide: j['pronunciationGuide'],
      acceptanceThreshold: (j['acceptanceThreshold'] as num?)?.toDouble()??0.70);
  }
  String get displayPrompt => promptNative ?? promptEnglish ?? '';
}

class SpeakingSentence {
  final String id, level, english, native, pronunciation, audioScript, contextNote;
  final String? accentTip, indianMistake;
  const SpeakingSentence({required this.id, required this.level, required this.english,
    required this.native, required this.pronunciation, required this.audioScript,
    required this.contextNote, this.accentTip, this.indianMistake});
  factory SpeakingSentence.fromJson(Map<String,dynamic> j) => SpeakingSentence(
    id: j['id']??'', level: j['level']??'beginner', english: j['english']??'',
    native: j['native']??'', pronunciation: j['pronunciation']??'',
    audioScript: j['audioScript']??'', contextNote: j['contextNote']??'',
    accentTip: j['accentTip'], indianMistake: j['indianMistake']);
}

class IndianMistake {
  final String wrong, right, nativeExplanation, howToRemember;
  const IndianMistake({required this.wrong, required this.right, required this.nativeExplanation, required this.howToRemember});
  factory IndianMistake.fromJson(Map<String,dynamic> j) => IndianMistake(
    wrong: j['wrong']??'', right: j['right']??'', nativeExplanation: j['nativeExplanation']??'', howToRemember: j['howToRemember']??'');
}

class LessonModel {
  final String lessonId, title, titleNative, emoji, skillId, cefrLevel;
  final int orderIndex, xpReward, estimatedMinutes;
  final bool requiresPro;
  final String hookNative, goalNative, goalEnglish;
  final Map<String,String> culturalConfidenceNote;
  final List<VocabItem> vocabulary;
  final GrammarPoint grammarPoint;
  final Map<String,dynamic> dialogue;
  final List<QuestionModel> questions;
  final List<SpeakingSentence> speakingPractice;
  final List<IndianMistake> indianMistakesSpecial;
  final Map<String,String> confidenceBooster;
  final Map<String,dynamic> summary;

  const LessonModel({required this.lessonId, required this.title, required this.titleNative,
    required this.emoji, required this.skillId, required this.cefrLevel,
    required this.orderIndex, required this.xpReward, required this.estimatedMinutes,
    required this.requiresPro, required this.hookNative, required this.goalNative,
    required this.goalEnglish, required this.culturalConfidenceNote, required this.vocabulary,
    required this.grammarPoint, required this.dialogue, required this.questions,
    required this.speakingPractice, required this.indianMistakesSpecial,
    required this.confidenceBooster, required this.summary});

  factory LessonModel.fromJson(Map<String,dynamic> j) {
    final d = (j['lesson'] ?? j) as Map<String,dynamic>;
    return LessonModel(
      lessonId: d['lessonId']??'', title: d['title']??'', titleNative: d['titleNative']??'',
      emoji: d['emoji']??'📚', skillId: d['skillId']??'', cefrLevel: d['cefrLevel']??'A1',
      orderIndex: d['orderIndex']??1, xpReward: d['xpReward']??10,
      estimatedMinutes: d['estimatedMinutes']??8, requiresPro: d['requiresPro']??false,
      hookNative: d['hookNative']??'', goalNative: d['goalNative']??'', goalEnglish: d['goalEnglish']??'',
      culturalConfidenceNote: Map<String,String>.from(d['culturalConfidenceNote']??{}),
      vocabulary: (d['vocabulary'] as List? ?? []).map((e) => VocabItem.fromJson(e)).toList(),
      grammarPoint: GrammarPoint.fromJson(d['grammarPoint'] as Map<String,dynamic>? ?? {}),
      dialogue: d['dialogue'] as Map<String,dynamic>? ?? {},
      questions: (d['questions'] as List? ?? []).map((e) => QuestionModel.fromJson(e)).toList(),
      speakingPractice: (d['speakingPractice'] as List? ?? []).map((e) => SpeakingSentence.fromJson(e)).toList(),
      indianMistakesSpecial: (d['indianMistakesSpecial'] as List? ?? []).map((e) => IndianMistake.fromJson(e)).toList(),
      confidenceBooster: Map<String,String>.from(d['confidenceBooster']??{}),
      summary: d['summary'] as Map<String,dynamic>? ?? {});
  }
}

class KeyPhrase {
  final String english, native, pronunciation, when, neverSay;
  const KeyPhrase({required this.english, required this.native, required this.pronunciation, required this.when, required this.neverSay});
  factory KeyPhrase.fromJson(Map<String,dynamic> j) => KeyPhrase(
    english: j['english']??'', native: j['native']??'', pronunciation: j['pronunciation']??'',
    when: j['when']??'', neverSay: j['neverSay']??'');
}

class SkillNode {
  final String skillId, skillName, skillNameEnglish, skillTagline, iconEmoji, colorHex;
  final int xpRequired, totalLessons, vocabularyCount;
  final List<String> prerequisites, lessonIds;
  final double positionX, positionY;
  final bool requiresPro;
  final String realLifeScenario, embarrassingWithout, confidentWith;
  final List<KeyPhrase> keyPhrases;
  const SkillNode({required this.skillId, required this.skillName, required this.skillNameEnglish,
    required this.skillTagline, required this.iconEmoji, required this.colorHex,
    required this.xpRequired, required this.prerequisites, required this.positionX,
    required this.positionY, required this.totalLessons, required this.lessonIds,
    required this.requiresPro, required this.realLifeScenario, required this.embarrassingWithout,
    required this.confidentWith, required this.keyPhrases, required this.vocabularyCount});
  factory SkillNode.fromJson(Map<String,dynamic> j) => SkillNode(
    skillId: j['skillId']??'', skillName: j['skillName']??'', skillNameEnglish: j['skillNameEnglish']??'',
    skillTagline: j['skillTagline']??'', iconEmoji: j['iconEmoji']??'📚', colorHex: j['colorHex']??'#FF6B2B',
    xpRequired: j['xpRequired']??0, prerequisites: (j['prerequisites'] as List? ?? []).map((e) => e.toString()).toList(),
    positionX: (j['positionX'] as num?)?.toDouble()??0.5, positionY: (j['positionY'] as num?)?.toDouble()??0.5,
    totalLessons: j['totalLessons']??2, lessonIds: (j['lessonIds'] as List? ?? []).map((e) => e.toString()).toList(),
    requiresPro: j['requiresPro']??false, realLifeScenario: j['realLifeScenario']??'',
    embarrassingWithout: j['embarrassingWithout']??'', confidentWith: j['confidentWith']??'',
    keyPhrases: (j['keyPhrases'] as List? ?? []).map((e) => KeyPhrase.fromJson(e)).toList(),
    vocabularyCount: j['vocabularyCount']??10);
}

class RoadmapStage {
  final String stageId, stageName, stageNameEnglish, stageSlogan, cefrEquivalent, colorHex, iconEmoji;
  final int estimatedDays;
  final bool requiresPro;
  final List<String> whatYouLearn;
  final List<SkillNode> skills;
  const RoadmapStage({required this.stageId, required this.stageName, required this.stageNameEnglish,
    required this.stageSlogan, required this.cefrEquivalent, required this.colorHex, required this.iconEmoji,
    required this.estimatedDays, required this.requiresPro, required this.whatYouLearn, required this.skills});
  factory RoadmapStage.fromJson(Map<String,dynamic> j) => RoadmapStage(
    stageId: j['stageId']??'', stageName: j['stageName']??'', stageNameEnglish: j['stageNameEnglish']??'',
    stageSlogan: j['stageSlogan']??'', cefrEquivalent: j['cefrEquivalent']??'A1',
    colorHex: j['colorHex']??'#FF6B2B', iconEmoji: j['iconEmoji']??'📚',
    estimatedDays: j['estimatedDays']??14, requiresPro: j['requiresPro']??false,
    whatYouLearn: (j['whatYouLearn'] as List? ?? []).map((e) => e.toString()).toList(),
    skills: (j['skills'] as List? ?? []).map((e) => SkillNode.fromJson(e)).toList());
}

class RoadmapModel {
  final String language, baseLanguage, tagline, taglineEnglish;
  final int totalSkills, estimatedWeeks;
  final List<RoadmapStage> stages;
  final List<Map<String,dynamic>> milestones;
  const RoadmapModel({required this.language, required this.baseLanguage, required this.tagline,
    required this.taglineEnglish, required this.totalSkills, required this.estimatedWeeks,
    required this.stages, required this.milestones});
  factory RoadmapModel.fromJson(Map<String,dynamic> j) {
    final r = (j['roadmap'] ?? j) as Map<String,dynamic>;
    return RoadmapModel(
      language: r['language']??'English', baseLanguage: r['baseLanguage']??'',
      tagline: r['tagline']??'', taglineEnglish: r['taglineEnglish']??'',
      totalSkills: r['totalSkills']??0, estimatedWeeks: r['estimatedWeeks']??24,
      stages: (r['stages'] as List? ?? []).map((e) => RoadmapStage.fromJson(e)).toList(),
      milestones: (r['milestones'] as List? ?? []).map((e) => Map<String,dynamic>.from(e)).toList());
  }
  List<SkillNode> get allSkills => stages.expand((s) => s.skills).toList();
}
