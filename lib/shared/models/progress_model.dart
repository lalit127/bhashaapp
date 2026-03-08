import 'package:hive/hive.dart';

part 'progress_model.g.dart';

@HiveType(typeId: 0)
class UserProgress extends HiveObject {
  @HiveField(0) int xp;
  @HiveField(1) int streak;
  @HiveField(2) DateTime lastActivityDate;
  @HiveField(3) String league; // bronze | silver | gold | diamond
  @HiveField(4) List<String> completedLessons;
  @HiveField(5) List<String> completedSkills;
  @HiveField(6) Map<String, int> skillXp;
  @HiveField(7) List<String> earnedBadges;
  @HiveField(8) int weeklyXp;
  @HiveField(9) int totalLessons;
  @HiveField(10) int hearts; // lives system (max 5)

  UserProgress({
    this.xp = 0,
    this.streak = 0,
    DateTime? lastActivityDate,
    this.league = 'bronze',
    List<String>? completedLessons,
    List<String>? completedSkills,
    Map<String, int>? skillXp,
    List<String>? earnedBadges,
    this.weeklyXp = 0,
    this.totalLessons = 0,
    this.hearts = 5,
  })  : lastActivityDate = lastActivityDate ?? DateTime.now(),
        completedLessons = completedLessons ?? [],
        completedSkills = completedSkills ?? [],
        skillXp = skillXp ?? {},
        earnedBadges = earnedBadges ?? [];

  bool get hasMaxHearts => hearts >= 5;

  void addXp(int amount) {
    xp += amount;
    weeklyXp += amount;
  }

  void updateStreak() {
    final today = DateTime.now();
    final diff = today.difference(lastActivityDate).inDays;
    if (diff == 1) {
      streak++;
    } else if (diff > 1) {
      streak = 1;
    }
    lastActivityDate = today;
  }

  void loseHeart() {
    if (hearts > 0) hearts--;
  }

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'streak': streak,
    'league': league,
    'completedLessons': completedLessons,
    'weeklyXp': weeklyXp,
    'hearts': hearts,
  };
}
