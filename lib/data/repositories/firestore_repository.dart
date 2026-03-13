// lib/data/repositories/firestore_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class FirestoreRepository {
  final _db = FirebaseFirestore.instance;

  // ── Helpers ───────────────────────────────────────────────────────────────
  DocumentReference _userDoc(String uid) =>
      _db.collection(AppK.colUsers).doc(uid);

  CollectionReference _progressCol(String uid) =>
      _userDoc(uid).collection(AppK.colProgress);

  CollectionReference _sessionsCol(String uid) =>
      _userDoc(uid).collection(AppK.colSessions);

  // ── User CRUD ─────────────────────────────────────────────────────────────
  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(uid, doc.data() as Map<String, dynamic>);
  }

  Future<void> createUser(UserModel user) =>
      _userDoc(user.uid).set(user.toFirestore());

  Future<void> updateUser(String uid, Map<String, dynamic> fields) =>
      _userDoc(uid).update(fields);

  /// Saves or updates user; creates if first time.
  Future<UserModel> upsertUser(UserModel user) async {
    final doc = await _userDoc(user.uid).get();
    if (doc.exists) {
      await _userDoc(user.uid).update({
        AppK.fName:  user.name,
        AppK.fEmail: user.email,
        AppK.fPhoto: user.photoUrl,
      });
    } else {
      await createUser(user);
    }
    return user;
  }

  // ── XP & Streak ───────────────────────────────────────────────────────────
  Future<void> addXp(String uid, int xp) =>
      _userDoc(uid).update({AppK.fXp: FieldValue.increment(xp)});

  /// Call after each lesson/session to update streak.
  Future<void> updateStreak(String uid) async {
    final today = _todayStr();
    final doc   = await _userDoc(uid).get();
    final data  = doc.data() as Map<String, dynamic>? ?? {};
    final last  = data[AppK.fLastSeen] as String?;
    final streak = data[AppK.fStreak]  as int? ?? 0;

    int newStreak = streak;
    if (last == null) {
      newStreak = 1;
    } else if (last == _yesterdayStr()) {
      newStreak = streak + 1;
    } else if (last != today) {
      newStreak = 1; // streak broken
    }

    await _userDoc(uid).update({
      AppK.fLastSeen: today,
      AppK.fStreak:   newStreak,
    });
  }

  // ── Lesson progress ───────────────────────────────────────────────────────
  Future<List<LessonProgress>> getAllProgress(String uid) async {
    final snap = await _progressCol(uid).get();
    return snap.docs.map((d) =>
        LessonProgress.fromFirestore(d.data() as Map<String, dynamic>)).toList();
  }

  Future<LessonProgress?> getLessonProgress(String uid, String skillId) async {
    final doc = await _progressCol(uid).doc(skillId).get();
    if (!doc.exists) return null;
    return LessonProgress.fromFirestore(doc.data() as Map<String, dynamic>);
  }

  Future<void> saveLessonProgress(String uid, LessonProgress p) =>
      _progressCol(uid).doc(p.skillId).set(p.toFirestore());

  Future<void> incrementLesson(
      String uid, String skillId, String skillName, int xp, double score) async {
    final ref = _progressCol(uid).doc(skillId);
    final doc = await ref.get();
    if (doc.exists) {
      final data     = doc.data() as Map<String, dynamic>;
      final done     = (data['lessonsCompleted'] as int? ?? 0) + 1;
      final total    = data['totalLessons']     as int? ?? 3;
      final prevAvg  = (data['avgScore']        as num?)?.toDouble() ?? 0;
      final newAvg   = ((prevAvg * (done - 1)) + score) / done;
      await ref.update({
        'lessonsCompleted': done,
        'xpEarned':         FieldValue.increment(xp),
        'avgScore':         newAvg,
        'isCompleted':      done >= total,
        'lastAttempt':      Timestamp.now(),
      });
    } else {
      await ref.set(LessonProgress(
        skillId:          skillId,
        skillName:        skillName,
        lessonsCompleted: 1,
        xpEarned:         xp,
        avgScore:         score,
        lastAttempt:      DateTime.now(),
      ).toFirestore());
    }
  }

  // ── Session logs ──────────────────────────────────────────────────────────
  Future<void> saveSession(String uid, SessionLog session) =>
      _sessionsCol(uid).doc(session.sessionId).set(session.toFirestore());

  Future<List<SessionLog>> getRecentSessions(String uid, {int limit = 10}) async {
    final snap = await _sessionsCol(uid)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return SessionLog(
        sessionId:       data['sessionId'] as String? ?? d.id,
        type:            data['type']      as String? ?? 'voice',
        topic:           data['topic']     as String? ?? '',
        durationSeconds: data['durationSeconds'] as int? ?? 0,
        xpEarned:        data['xpEarned']  as int?   ?? 0,
        score:           data['score']     as int?   ?? 0,
        startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  // ── Lesson JSON cache ─────────────────────────────────────────────────────
  /// Caches AI-generated lesson JSON to avoid regenerating on every open.
  Future<Map<String, dynamic>?> getCachedLesson(String cacheKey) async {
    final doc = await _db.collection(AppK.colLessons).doc(cacheKey).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    // Expire after 7 days
    final ts = (data['cachedAt'] as Timestamp?)?.toDate();
    if (ts != null && DateTime.now().difference(ts).inDays > 7) return null;
    return data['lesson'] as Map<String, dynamic>?;
  }

  Future<void> cacheLesson(String cacheKey, Map<String, dynamic> lesson) =>
      _db.collection(AppK.colLessons).doc(cacheKey).set({
        'lesson':   lesson,
        'cachedAt': Timestamp.now(),
      });

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  String _yesterdayStr() {
    final n = DateTime.now().subtract(const Duration(days: 1));
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }
}
