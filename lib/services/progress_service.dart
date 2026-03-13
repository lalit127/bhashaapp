// lib/services/progress_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ProgressService extends GetxService {
  final _db  = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final xp             = 0.obs;
  final streak         = 0.obs;
  final completedSkills = <String>[].obs;

  String get _uid => _auth.currentUser!.uid;

  Future<void> loadProgress() async {
    final doc = await _db.doc('users/$_uid/progress').get();
    if (!doc.exists) return;
    final d      = doc.data()!;
    xp.value     = d['xp'] ?? 0;
    streak.value = d['streak'] ?? 0;
    completedSkills.value =
    List<String>.from(d['completedSkills'] ?? []);
  }

  // Call after lesson complete
  Future<void> completeLesson(String skillId, int score) async {
    final earnedXp = (score * 0.5).round(); // 0–50 XP per lesson
    await _db.doc('users/$_uid/progress').set({
      'xp':              FieldValue.increment(earnedXp),
      'completedSkills': FieldValue.arrayUnion([skillId]),
      'lastActivity':    FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.doc('users/$_uid/lessonProgress/$skillId').set({
      'completed': true,
      'score':     score,
      'completedAt': FieldValue.serverTimestamp(),
    });

    xp.value += earnedXp;
    if (!completedSkills.contains(skillId)) {
      completedSkills.add(skillId);
    }
  }

  // Call daily — updates streak
  Future<void> updateStreak() async {
    final doc  = await _db.doc('users/$_uid/progress').get();
    final last = (doc.data()?['lastActivity'] as Timestamp?)?.toDate();
    final now  = DateTime.now();
    final isConsecutive = last != null &&
        now.difference(last).inHours < 48;

    await _db.doc('users/$_uid/progress').set({
      'streak':       isConsecutive ? FieldValue.increment(1) : 1,
      'lastActivity': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}