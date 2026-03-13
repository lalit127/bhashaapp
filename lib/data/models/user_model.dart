// lib/data/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

// ── User profile (stored in users/{uid}) ─────────────────────────────────────
class UserModel {
  final String  uid;
  final String  name;
  final String  email;
  final String? photoUrl;
  final String  nativeLanguage;   // 'hindi', 'gujarati', etc.
  final String  cefrLevel;        // 'A1','A2','B1','B2','C1'
  final String  goal;             // 'daily','job','exam', etc.
  final String  occupation;       // 'student', 'software_engineer', etc.
  final int     totalXp;
  final int     currentStreak;
  final String? lastSeenDate;     // 'yyyy-MM-dd'
  final bool    onboardingComplete;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.nativeLanguage    = 'hindi',
    this.cefrLevel         = 'A1',
    this.goal              = 'daily',
    this.occupation        = 'student',
    this.totalXp           = 0,
    this.currentStreak     = 0,
    this.lastSeenDate,
    this.onboardingComplete = false,
    required this.createdAt,
  });

  UserModel copyWith({
    String?  name,     String? email,    String? photoUrl,
    String?  nativeLang, String? level,  String? goal,
    String?  occ,      int?    xp,       int?    streak,
    String?  lastSeen, bool?   onboarded,
  }) => UserModel(
    uid:                 uid,
    name:                name        ?? this.name,
    email:               email       ?? this.email,
    photoUrl:            photoUrl    ?? this.photoUrl,
    nativeLanguage:      nativeLang  ?? nativeLanguage,
    cefrLevel:           level       ?? cefrLevel,
    goal:                goal        ?? this.goal,
    occupation:          occ         ?? occupation,
    totalXp:             xp          ?? totalXp,
    currentStreak:       streak      ?? currentStreak,
    lastSeenDate:        lastSeen    ?? lastSeenDate,
    onboardingComplete:  onboarded   ?? onboardingComplete,
    createdAt:           createdAt,
  );

  Map<String, dynamic> toFirestore() => {
    AppK.fName:       name,
    AppK.fEmail:      email,
    AppK.fPhoto:      photoUrl,
    AppK.fLang:       nativeLanguage,
    AppK.fLevel:      cefrLevel,
    AppK.fGoal:       goal,
    AppK.fOccupation: occupation,
    AppK.fXp:         totalXp,
    AppK.fStreak:     currentStreak,
    AppK.fLastSeen:   lastSeenDate,
    AppK.fOnboarded:  onboardingComplete,
    AppK.fCreatedAt:  Timestamp.fromDate(createdAt),
  };

  factory UserModel.fromFirestore(String uid, Map<String, dynamic> d) => UserModel(
    uid:                uid,
    name:               d[AppK.fName]       as String?  ?? '',
    email:              d[AppK.fEmail]      as String?  ?? '',
    photoUrl:           d[AppK.fPhoto]      as String?,
    nativeLanguage:     d[AppK.fLang]       as String?  ?? 'hindi',
    cefrLevel:          d[AppK.fLevel]      as String?  ?? 'A1',
    goal:               d[AppK.fGoal]       as String?  ?? 'daily',
    occupation:         d[AppK.fOccupation] as String?  ?? 'student',
    totalXp:            d[AppK.fXp]         as int?     ?? 0,
    currentStreak:      d[AppK.fStreak]     as int?     ?? 0,
    lastSeenDate:       d[AppK.fLastSeen]   as String?,
    onboardingComplete: d[AppK.fOnboarded]  as bool?    ?? false,
    createdAt: (d[AppK.fCreatedAt] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

// ── Lesson progress (stored in users/{uid}/progress/{skillId}) ──────────────
class LessonProgress {
  final String skillId;
  final String skillName;
  final int    lessonsCompleted;
  final int    totalLessons;
  final int    xpEarned;
  final double avgScore;         // 0-100
  final bool   isCompleted;
  final DateTime lastAttempt;

  const LessonProgress({
    required this.skillId,
    required this.skillName,
    this.lessonsCompleted = 0,
    this.totalLessons     = 3,
    this.xpEarned         = 0,
    this.avgScore         = 0,
    this.isCompleted      = false,
    required this.lastAttempt,
  });

  Map<String, dynamic> toFirestore() => {
    'skillId':          skillId,
    'skillName':        skillName,
    'lessonsCompleted': lessonsCompleted,
    'totalLessons':     totalLessons,
    'xpEarned':         xpEarned,
    'avgScore':         avgScore,
    'isCompleted':      isCompleted,
    'lastAttempt':      Timestamp.fromDate(lastAttempt),
  };

  factory LessonProgress.fromFirestore(Map<String, dynamic> d) => LessonProgress(
    skillId:          d['skillId']          as String? ?? '',
    skillName:        d['skillName']        as String? ?? '',
    lessonsCompleted: d['lessonsCompleted'] as int?    ?? 0,
    totalLessons:     d['totalLessons']     as int?    ?? 3,
    xpEarned:         d['xpEarned']         as int?    ?? 0,
    avgScore:         (d['avgScore']        as num?)?.toDouble() ?? 0,
    isCompleted:      d['isCompleted']      as bool?   ?? false,
    lastAttempt: (d['lastAttempt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  double get progressRatio =>
      totalLessons == 0 ? 0 : lessonsCompleted / totalLessons;
}

// ── Voice/Chat session log (users/{uid}/sessions/{sessionId}) ────────────────
class SessionLog {
  final String   sessionId;
  final String   type;          // 'voice' | 'nova_chat'
  final String   topic;
  final int      durationSeconds;
  final int      xpEarned;
  final int      score;
  final DateTime startedAt;

  const SessionLog({
    required this.sessionId,
    required this.type,
    required this.topic,
    this.durationSeconds = 0,
    this.xpEarned        = 0,
    this.score           = 0,
    required this.startedAt,
  });

  Map<String, dynamic> toFirestore() => {
    'sessionId':       sessionId,
    'type':            type,
    'topic':           topic,
    'durationSeconds': durationSeconds,
    'xpEarned':        xpEarned,
    'score':           score,
    'startedAt':       Timestamp.fromDate(startedAt),
  };
}
