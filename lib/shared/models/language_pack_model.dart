class LanguagePackManifest {
  final String language;
  final String languageCode;
  final String version;
  final String difficulty;
  final List<String> skills;
  final int packSizeBytes;
  final String checksum;
  final String cdnUrl;

  const LanguagePackManifest({
    required this.language,
    required this.languageCode,
    required this.version,
    required this.difficulty,
    required this.skills,
    required this.packSizeBytes,
    required this.checksum,
    required this.cdnUrl,
  });

  factory LanguagePackManifest.fromJson(Map<String, dynamic> json) =>
      LanguagePackManifest(
        language: json['language'] as String,
        languageCode: json['languageCode'] as String,
        version: json['version'] as String,
        difficulty: json['difficulty'] as String,
        skills: (json['skills'] as List).map((e) => e as String).toList(),
        packSizeBytes: json['packSizeBytes'] as int? ?? 0,
        checksum: json['checksum'] as String? ?? '',
        cdnUrl: json['cdnUrl'] as String,
      );

  String get displaySize {
    final mb = packSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class SkillNode {
  final String skillId;
  final String name;
  final String iconEmoji;
  final int xpRequired;
  final List<String> lessonIds;
  final List<String> prerequisites;
  final double positionX;
  final double positionY;
  final String color;

  const SkillNode({
    required this.skillId,
    required this.name,
    required this.iconEmoji,
    required this.xpRequired,
    required this.lessonIds,
    this.prerequisites = const [],
    required this.positionX,
    required this.positionY,
    this.color = '#FF6B2B',
  });

  factory SkillNode.fromJson(Map<String, dynamic> json) => SkillNode(
    skillId: json['skillId'] as String,
    name: json['name'] as String,
    iconEmoji: json['iconEmoji'] as String,
    xpRequired: json['xpRequired'] as int? ?? 0,
    lessonIds: (json['lessonIds'] as List).map((e) => e as String).toList(),
    prerequisites: (json['prerequisites'] as List?)?.map((e) => e as String).toList() ?? [],
    positionX: (json['positionX'] as num).toDouble(),
    positionY: (json['positionY'] as num).toDouble(),
    color: json['color'] as String? ?? '#FF6B2B',
  );
}
