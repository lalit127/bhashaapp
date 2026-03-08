import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

class AnalyticsService extends GetxService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ── Onboarding ────────────────────────────────────────────────────────────
  Future<void> logOnboardingComplete(String language) async {
    await _analytics.logEvent(name: 'onboarding_complete',
        parameters: {'language': language});
  }

  Future<void> logPackDownloaded(String language) async {
    await _analytics.logEvent(name: 'language_pack_downloaded',
        parameters: {'language': language});
  }

  // ── Lessons ───────────────────────────────────────────────────────────────
  Future<void> logLessonStart(String lessonId, String skillId) async {
    await _analytics.logEvent(name: 'lesson_start',
        parameters: {'lesson_id': lessonId, 'skill_id': skillId});
  }

  Future<void> logLessonComplete(String lessonId, int xpEarned, int mistakes) async {
    await _analytics.logEvent(name: 'lesson_complete', parameters: {
      'lesson_id': lessonId,
      'xp_earned': xpEarned,
      'mistakes': mistakes,
    });
  }

  // ── Paywall ───────────────────────────────────────────────────────────────
  Future<void> logPaywallView(String trigger) async {
    await _analytics.logEvent(name: 'paywall_view',
        parameters: {'trigger': trigger});
  }

  Future<void> logSubscriptionStart(String plan) async {
    await _analytics.logEvent(name: 'subscription_started',
        parameters: {'plan': plan});
  }

  // ── AI Tutor ──────────────────────────────────────────────────────────────
  Future<void> logAiTutorSession(String sessionType) async {
    await _analytics.logEvent(name: 'ai_tutor_session',
        parameters: {'type': sessionType});
  }

  // ── Streak ────────────────────────────────────────────────────────────────
  Future<void> logStreakMilestone(int days) async {
    await _analytics.logEvent(name: 'streak_milestone',
        parameters: {'days': days});
  }
}
