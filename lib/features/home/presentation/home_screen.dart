import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../subscription/revenuecat_service.dart';
import '../../progress/progress_controller.dart';
import '../../../shared/widgets/xp_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    final progress = storage.getProgress();
    final isPro = Get.find<RevenueCatService>().isPro;
    final langCode = storage.getSelectedLanguage() ?? 'hi';

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          _buildHeader(progress, isPro, langCode),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildStreak(progress)),
                SliverToBoxAdapter(child: _buildMissionCard()),
                SliverToBoxAdapter(child: _buildQuickStats(progress)),
                SliverToBoxAdapter(child: _buildContinueCard()),
                SliverToBoxAdapter(child: _buildAiTutorBanner(isPro)),
                SliverToBoxAdapter(child: _buildDailyGoal(progress)),
                SliverToBoxAdapter(child: _buildLeagueCard(progress)),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header (white bar with streak + hearts + gems) ──────────
  Widget _buildHeader(progress, bool isPro, String langCode) {
    final langNames = {
      'hi':'Hindi','gu':'Gujarati','ta':'Tamil',
      'te':'Telugu','mr':'Marathi','bn':'Bengali'
    };
    return Container(
      color: AppColors.bgWhite,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.bgWhite,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
          ),
          child: Row(
            children: [
              // Flag + Language
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      langNames[langCode] ?? 'Hindi',
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark, fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Streak
              _HeaderStat(emoji: '🔥', value: '${progress.streak}',
                  color: AppColors.streakFire),
              const SizedBox(width: 20),

              // Hearts
              _HeaderStat(emoji: '❤️', value: '${progress.hearts}',
                  color: AppColors.heart),
              const SizedBox(width: 20),

              // Gems
              _HeaderStat(emoji: '💎', value: '${progress.xp ~/ 10}',
                  color: AppColors.xpBlue),

              const SizedBox(width: 12),

              // Avatar
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.progress),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isPro ? AppColors.gold : AppColors.border,
                        width: 2.5),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: AppColors.bgSection,
                    child: Text('🦜', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Streak bar with daily goals ────────────────────────────
  Widget _buildStreak(progress) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '${progress.streak}-Day Streak!',
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary, fontFamily: 'Nunito',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Keep it up!',
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.gold, fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Week days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final days = ['M','T','W','T','F','S','S'];
              final done = i < (progress.streak % 7);
              return Column(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.streakFire : AppColors.bgSection,
                      border: Border.all(
                        color: done ? AppColors.streakFire : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.local_fire_department,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(days[i], style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: done ? AppColors.streakFire : AppColors.textMuted,
                    fontFamily: 'Nunito',
                  )),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── TODAY'S MISSION ────────────────────────────────────────
  Widget _buildMissionCard() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.lesson),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF00BFA5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20, top: -20,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              right: 20, bottom: -30,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('📚', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Mission",
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: Colors.white70, fontFamily: 'Nunito',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Office Email English',
                          style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: Colors.white, fontFamily: 'Nunito',
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Lesson 3 • 8 min • +10 XP',
                          style: TextStyle(
                            fontSize: 13, color: Colors.white70,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8, offset: const Offset(0, 3),
                      )],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.primary, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick stats row ────────────────────────────────────────
  Widget _buildQuickStats(progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(child: _QuickStat(
            emoji: '⚡',
            value: '${progress.xp}',
            label: 'Total XP',
            color: AppColors.xpBlue,
            bgColor: const Color(0xFFE3F5FD),
          )),
          const SizedBox(width: 10),
          Expanded(child: _QuickStat(
            emoji: '📚',
            value: '${progress.completedLessons.length}',
            label: 'Lessons',
            color: AppColors.indigo,
            bgColor: AppColors.indigoLight,
          )),
          const SizedBox(width: 10),
          Expanded(child: _QuickStat(
            emoji: '🏆',
            value: '${progress.league.toUpperCase()[0]}',
            label: 'League',
            color: AppColors.gold,
            bgColor: AppColors.goldLight,
          )),
        ],
      ),
    );
  }

  // ── Continue card ──────────────────────────────────────────
  Widget _buildContinueCard() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.skillTree),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.saffronLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Text('🌳', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Continue Learning',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary, fontFamily: 'Nunito',
                      )),
                  SizedBox(height: 4),
                  Text('Greetings → Numbers → Colors',
                      style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted,
                        fontFamily: 'Nunito',
                      )),
                  SizedBox(height: 8),
                  // Mini XP bar
                  _MiniXpBar(value: 0.4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.saffron,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI Tutor banner ────────────────────────────────────────
  Widget _buildAiTutorBanner(bool isPro) {
    return GestureDetector(
      onTap: () => isPro
          ? Get.toNamed(AppRoutes.aiChat)
          : Get.toNamed(AppRoutes.paywall, arguments: 'ai_tutor_home'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isPro ? AppColors.indigoLight : AppColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPro ? AppColors.indigo.withOpacity(0.4) : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isPro ? AppColors.indigo : AppColors.bgSection,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(isPro ? '🤖' : '🔒',
                    style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      'AI Tutor',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: isPro ? AppColors.indigo : AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isPro) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PRO', style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w900,
                        color: Colors.white, fontFamily: 'Nunito',
                      )),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    isPro
                        ? 'Voice chat • Grammar fix • Roleplay'
                        : 'Unlock voice conversations & more',
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isPro ? Icons.chevron_right : Icons.lock_outline,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ── Daily XP goal ──────────────────────────────────────────
  Widget _buildDailyGoal(progress) {
    const target = 50;
    final pct = (progress.weeklyXp / (target * 7)).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Weekly Goal',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary, fontFamily: 'Nunito',
                ),
              ),
              const Spacer(),
              Text(
                '${progress.weeklyXp}/${target * 7} XP',
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textMuted, fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          XpBar(value: pct, color: AppColors.xpBlue),
          const SizedBox(height: 8),
          Text(
            pct >= 1.0
                ? '🎉 Weekly goal complete! +50 bonus XP'
                : '${((1 - pct) * target * 7).toInt()} XP left to reach your goal',
            style: const TextStyle(
              fontSize: 12, color: AppColors.textMuted, fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  // ── League card ────────────────────────────────────────────
  Widget _buildLeagueCard(progress) {
    final colors = {
      'bronze': AppColors.bronze, 'silver': AppColors.silver,
      'gold': AppColors.goldLeague, 'diamond': AppColors.diamond,
    };
    final emojis = {
      'bronze': '🥉', 'silver': '🥈', 'gold': '🥇', 'diamond': '💎',
    };
    final color = colors[progress.league] ?? AppColors.bronze;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.league),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
        ),
        child: Row(
          children: [
            Text(emojis[progress.league] ?? '🥉',
                style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${progress.league[0].toUpperCase()}${progress.league.substring(1)} League',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900,
                      color: color, fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Compete for top 10 this week',
                    style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                'View →',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: color, fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav (Duolingo style) ────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgWhite,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home',
                  isActive: true, color: AppColors.primary, onTap: () {}),
              _NavItem(icon: Icons.account_tree_rounded, label: 'Learn',
                  color: AppColors.saffron,
                  onTap: () => Get.toNamed(AppRoutes.skillTree)),
              _NavItem(icon: Icons.smart_toy_rounded, label: 'AI Tutor',
                  color: AppColors.indigo,
                  onTap: () => Get.find<RevenueCatService>().isPro
                      ? Get.toNamed(AppRoutes.aiChat)
                      : Get.toNamed(AppRoutes.paywall, arguments: 'nav_ai')),
              _NavItem(icon: Icons.leaderboard_rounded, label: 'League',
                  color: AppColors.gold,
                  onTap: () => Get.toNamed(AppRoutes.league)),
              _NavItem(icon: Icons.person_rounded, label: 'Profile',
                  color: AppColors.teal,
                  onTap: () => Get.toNamed(AppRoutes.progress)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String emoji, value;
  final Color color;
  const _HeaderStat({required this.emoji, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w900,
        color: color, fontFamily: 'Nunito',
      )),
    ],
  );
}

class _QuickStat extends StatelessWidget {
  final String emoji, value, label;
  final Color color, bgColor;
  const _QuickStat({required this.emoji, required this.value,
      required this.label, required this.color, required this.bgColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900,
          color: color, fontFamily: 'Nunito',
        )),
        Text(label, style: const TextStyle(
          fontSize: 11, color: AppColors.textMuted, fontFamily: 'Nunito',
        )),
      ],
    ),
  );
}

class _MiniXpBar extends StatelessWidget {
  final double value;
  const _MiniXpBar({required this.value});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: LinearProgressIndicator(
      value: value,
      minHeight: 6,
      backgroundColor: AppColors.bgSection,
      valueColor: const AlwaysStoppedAnimation(AppColors.saffron),
    ),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label,
      this.isActive = false, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? color : AppColors.textMuted,
              size: isActive ? 28 : 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: isActive ? color : AppColors.textMuted,
            fontFamily: 'Nunito',
          )),
        ],
      ),
    ),
  );
}
