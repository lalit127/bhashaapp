class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const String cdnBase = String.fromEnvironment(
    'CDN_BASE_URL',
    defaultValue: 'https://cdn.bhashaapp.com',
  );

  // Language packs
  static String packManifest(String langCode) => '/packs/$langCode/manifest.json';
  static String packDownload(String langCode, String version) =>
      '$cdnBase/packs/$langCode/v$version/pack.zip';

  // AI endpoints
  static const String aiConversation = '/ai/conversation';
  static const String aiPronunciationScore = '/ai/pronunciation-score';
  static const String aiGrammarExplain = '/ai/grammar-explain';
  static const String aiLessonGenerate = '/ai/lesson-generate';

  // User
  static const String userProgress = '/user/progress';
  static const String userSync = '/user/sync';
  static const String leaderboard = '/league/leaderboard';
}
