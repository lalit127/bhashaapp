// lib/core/constants/app_constants.dart
// All keys, routes, and config in one place.
// Run: flutter run --dart-define=GEMINI_API_KEY=AIza... --dart-define=GCLOUD_TTS_KEY=AIza...

class AppK {
  AppK._();

  // ── API Keys (injected via --dart-define) ─────────────────────────────────
  static const geminiKey  = 'AIzaSyD2EbayzS-HzEj5wrY3iyn0uShj0t4aya8';
  static const ttsKey     = 'AIzaSyD2EbayzS-HzEj5wrY3iyn0uShj0t4aya8';

  // ── Gemini endpoints ──────────────────────────────────────────────────────
  static const geminiBase    = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const geminiModel   = 'gemini-2.5-flash-lite';
  static const geminiLiveWs  =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage'
      '.v1beta.GenerativeService.BidiGenerateContent';
  static const geminiLiveModel = 'models/gemini-2.0-flash-live-001';

  // ── Google Cloud TTS ──────────────────────────────────────────────────────
  static const ttsBase = 'https://texttospeech.googleapis.com/v1/text:synthesize';

  // ── GetX Routes ───────────────────────────────────────────────────────────
  static const routeAuth     = '/auth';
  static const routeHome     = '/home';
  static const routeLesson   = '/lesson';
  static const routeVoice    = '/voice';
  static const routeMira     = '/nova';
  static const routeProgress = '/progress';

  // ── Firestore collections ─────────────────────────────────────────────────
  static const colUsers    = 'users';
  static const colProgress = 'progress';
  static const colSessions = 'sessions';
  static const colLessons  = 'lessons_cache';

  // ── Firestore user doc fields ─────────────────────────────────────────────
  static const fName        = 'name';
  static const fEmail       = 'email';
  static const fPhoto       = 'photoUrl';
  static const fLang        = 'nativeLanguage';
  static const fLevel       = 'cefrLevel';
  static const fGoal        = 'goal';
  static const fOccupation  = 'occupation';
  static const fXp          = 'totalXp';
  static const fStreak      = 'currentStreak';
  static const fLastSeen    = 'lastSeenDate';
  static const fOnboarded   = 'onboardingComplete';
  static const fCreatedAt   = 'createdAt';

  // ── XP thresholds ─────────────────────────────────────────────────────────
  static const xpPerLesson   = 50;
  static const xpPerActivity = 10;
  static const xpPerVoice    = 30;
  static const xpPerChat     = 5;
}
