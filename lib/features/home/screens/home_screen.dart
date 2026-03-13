// lib/features/home/screens/home_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/home_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/user_model.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: RefreshIndicator(
        onRefresh: ctrl.refreshAll,
        color: const Color(0xFF7B5EA7),
        backgroundColor: const Color(0xFF12121E),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── App bar ───────────────────────────────────────────────
            SliverAppBar(
              backgroundColor:    Colors.transparent,
              expandedHeight:     200,
              floating:           false,
              pinned:             true,
              flexibleSpace: FlexibleSpaceBar(
                background: _HomeHero(ctrl: ctrl, auth: auth),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                  onPressed: () => _showSettings(context, auth),
                ),
              ],
            ),

            // ── XP + streak strip ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Obx(() => _XpStrip(
                xp:     ctrl.totalXp,
                streak: ctrl.streak,
                level:  ctrl.level,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0)),
            ),

            // ── Quick actions ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: _QuickActions().animate(delay: 100.ms).fadeIn(duration: 400.ms),
            ),

            // ── Roadmap phases ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Obx(() {
                if (ctrl.isLoadingRoadmap.value) {
                  return const _RoadmapSkeleton();
                }
                if (ctrl.roadmap.value == null) {
                  return _ErrorCard(
                    msg: ctrl.errorMsg.value ?? 'Could not load roadmap',
                    onRetry: ctrl.loadRoadmap,
                  );
                }
                return _RoadmapSection(ctrl: ctrl);
              }),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, AuthController auth) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder:         (_) => _SettingsSheet(auth: auth),
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────
class _HomeHero extends StatelessWidget {
  final HomeController ctrl;
  final AuthController auth;
  const _HomeHero({required this.ctrl, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Mesh gradient
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [Color(0xFF1A0A2E), Color(0xFF0D1B3E), Color(0xFF080810)],
          ),
        ),
      ),
      // Glow orb
      Positioned(
        top: -40, right: -40,
        child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF7B5EA7).withOpacity(0.3),
              Colors.transparent,
            ]),
          ),
        ),
      ),
      // Content
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Obx(() {
            final user = auth.user.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF7B5EA7),
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null
                        ? Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w800))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: const TextStyle(
                            color: Color(0xFF888899), fontSize: 12),
                      ),
                      Text(
                        user?.name ?? 'Learner',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )),
                  // CEFR badge
                  _CefrBadge(level: ctrl.level),
                ]),
                const SizedBox(height: 16),
                Text(
                  'Keep going — you\'re on a ${ctrl.streak} day streak! 🔥',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFFB0B0CC),
                    fontSize: 13,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    ]);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ── XP strip ──────────────────────────────────────────────────────────────────
class _XpStrip extends StatelessWidget {
  final int xp, streak;
  final String level;
  const _XpStrip({required this.xp, required this.streak, required this.level});

  @override
  Widget build(BuildContext context) {
    final nextXp = _nextLevelXp(level);
    final ratio  = (xp % nextXp) / nextXp;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: const Color(0xFF1E1E32)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('⚡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text('$xp XP',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Text('Next level: $nextXp XP',
              style: const TextStyle(color: Color(0xFF666688), fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value:           ratio.clamp(0.0, 1.0),
            minHeight:       6,
            backgroundColor: const Color(0xFF1E1E32),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF7B5EA7)),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _StatPill(icon: '🔥', label: '$streak day streak'),
          const SizedBox(width: 10),
          _StatPill(icon: '📊', label: level),
          const SizedBox(width: 10),
          _StatPill(icon: '🏆', label: _rank(xp)),
        ]),
      ]),
    );
  }

  int    _nextLevelXp(String lvl) =>
      const {'A1':200,'A2':500,'B1':1000,'B2':2000,'C1':5000}[lvl] ?? 500;
  String _rank(int xp) =>
      xp < 100 ? 'Seedling' : xp < 500 ? 'Speaker' : xp < 1500 ? 'Fluent' : 'Master';
}

class _StatPill extends StatelessWidget {
  final String icon, label;
  const _StatPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color:        const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(100),
      border:       Border.all(color: const Color(0xFF2A2A4A)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Color(0xFFB0B0CC), fontSize: 11)),
    ]),
  );
}

// ── Quick actions ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick Practice',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ActionCard(
            icon:     '🎙️',
            label:    'Talk with Mira',
            subtitle: 'Voice call',
            gradient: const LinearGradient(colors: [Color(0xFF7B5EA7), Color(0xFF00D4FF)]),
            onTap:    () => _pickTopic(context),
          )),
          const SizedBox(width: 10),
          Expanded(child: _ActionCard(
            icon:     '💬',
            label:    'Chat with Mira',
            subtitle: 'Text tutor',
            gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFB547)]),
            onTap:    () => Get.toNamed(AppK.routeMira, arguments: {
              'skillId':         'general_english',
              'skillName':       'English Practice',
              'grammarRule':     'General English conversation',
              'sentencePattern': 'Subject + Verb + Object',
            }),
          )),
        ]),
      ]),
    );
  }

  void _pickTopic(BuildContext context) {
    final topics = [
      'Daily conversation', 'Introduce yourself', 'At the office',
      'Shopping & bargaining', 'Asking for directions', 'Job interview',
    ];
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopicPicker(topics: topics),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String   icon, label, subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon, required this.label, required this.subtitle,
    required this.gradient, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:     gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          color:      const Color(0xFF7B5EA7).withOpacity(0.25),
          blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: 13)),
        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    ),
  );
}

// ── Roadmap section ───────────────────────────────────────────────────────────
class _RoadmapSection extends StatelessWidget {
  final HomeController ctrl;
  const _RoadmapSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final roadmap = ctrl.roadmap.value!;
    final phases  = (roadmap['phases'] as List? ?? []).cast<Map<String, dynamic>>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your Roadmap',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        Text(
          '${roadmap['current_level']} → ${roadmap['target_level']} · ${roadmap['total_weeks']} weeks',
          style: const TextStyle(color: Color(0xFF666688), fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...phases.asMap().entries.map((e) => _PhaseCard(
          phase:      e.value,
          phaseIndex: e.key,
          ctrl:       ctrl,
        )),
      ]),
    );
  }
}

class _PhaseCard extends StatefulWidget {
  final Map<String, dynamic> phase;
  final int                  phaseIndex;
  final HomeController       ctrl;
  const _PhaseCard({required this.phase, required this.phaseIndex, required this.ctrl});
  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _expanded = widget.phaseIndex == 0; // expand first phase
  }

  @override
  Widget build(BuildContext context) {
    final phase  = widget.phase;
    final skills = (phase['skills'] as List? ?? []).cast<Map<String, dynamic>>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: const Color(0xFF1E1E32)),
      ),
      child: Column(children: [
        // Phase header
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width:  36, height: 36,
                decoration: BoxDecoration(
                  gradient: _phaseGradient(widget.phaseIndex),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('${widget.phaseIndex + 1}',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phase['phase_name'] ?? 'Phase ${widget.phaseIndex + 1}',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('${phase['duration_weeks']} weeks · ${skills.length} skills',
                      style: const TextStyle(color: Color(0xFF666688), fontSize: 11)),
                ],
              )),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF666688)),
            ]),
          ),
        ),
        // Skills
        if (_expanded)
          ...skills.asMap().entries.map((e) => Obx(() => _SkillRow(
            skill:     e.value,
            index:     e.key,
            isUnlocked: widget.ctrl.isSkillUnlocked(e.value['skill_id'] as String? ?? ''),
            progress:  widget.ctrl.progressFor(e.value['skill_id'] as String? ?? ''),
          ))),
      ]),
    );
  }

  LinearGradient _phaseGradient(int i) {
    const g = [
      LinearGradient(colors: [Color(0xFF7B5EA7), Color(0xFF00D4FF)]),
      LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFB547)]),
      LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00D4FF)]),
    ];
    return g[i % g.length];
  }
}

class _SkillRow extends StatelessWidget {
  final Map<String, dynamic> skill;
  final int                  index;
  final bool                 isUnlocked;
  final LessonProgress?      progress;
  const _SkillRow({
    required this.skill, required this.index,
    required this.isUnlocked, this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final skillId   = skill['skill_id']   as String? ?? '';
    final skillName = skill['skill_name'] as String? ?? '';
    final icon      = skill['icon']       as String? ?? '📚';
    final lessons   = skill['lesson_count'] as int? ?? 3;
    final done      = progress?.lessonsCompleted ?? 0;
    final isComplete = progress?.isCompleted ?? false;

    return GestureDetector(
      onTap: isUnlocked ? () => Get.toNamed(AppK.routeLesson, arguments: {
        'skillId':      skillId,
        'skillName':    skillName,
        'lessonNumber': done < lessons ? done + 1 : lessons,
      }) : null,
      child: AnimatedOpacity(
        duration: 300.ms,
        opacity:  isUnlocked ? 1.0 : 0.4,
        child: Container(
          margin:  const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        isUnlocked
                ? const Color(0xFF12121E) : const Color(0xFF0A0A14),
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(
              color: isComplete
                  ? const Color(0xFF00E5A0).withOpacity(0.4)
                  : const Color(0xFF1E1E32),
            ),
          ),
          child: Row(children: [
            // Icon
            Container(
              width:  44, height: 44,
              decoration: BoxDecoration(
                color:        const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(icon,
                  style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skillName,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : const Color(0xFF666688),
                      fontWeight: FontWeight.w600, fontSize: 13,
                    )),
                const SizedBox(height: 3),
                Text('$done / $lessons lessons',
                    style: const TextStyle(color: Color(0xFF666688), fontSize: 11)),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value:           lessons == 0 ? 0 : done / lessons,
                    minHeight:       3,
                    backgroundColor: const Color(0xFF1E1E32),
                    valueColor:      AlwaysStoppedAnimation(
                        isComplete ? const Color(0xFF00E5A0) : const Color(0xFF7B5EA7)),
                  ),
                ),
              ],
            )),
            const SizedBox(width: 10),
            // Right indicator
            if (!isUnlocked)
              const Icon(Icons.lock_outline, color: Color(0xFF444466), size: 18)
            else if (isComplete)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF00E5A0), size: 22)
            else
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF7B5EA7), size: 16),
          ]),
        ),
      ),
    );
  }
}

// ── Topic picker bottom sheet ─────────────────────────────────────────────────
class _TopicPicker extends StatelessWidget {
  final List<String> topics;
  const _TopicPicker({required this.topics});
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color:        Color(0xE8101020),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border:       Border(top: BorderSide(color: Color(0xFF1E1E32))),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFF2A2A4A),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Choose a topic',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            ...topics.map((t) => GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppK.routeVoice, arguments: {
                  'topic':       t,
                  'cefrLevel':   auth.user.value?.cefrLevel      ?? 'A1',
                  'nativeLang':  auth.user.value?.nativeLanguage ?? 'hindi',
                  'occupation':  auth.user.value?.occupation     ?? 'student',
                });
              },
              child: Container(
                width:   double.infinity,
                margin:  const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color:        const Color(0xFF12121E),
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: const Color(0xFF1E1E32)),
                ),
                child: Text(t, style: const TextStyle(color: Color(0xFFB0B0CC))),
              ),
            )),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}

// ── Settings sheet ────────────────────────────────────────────────────────────
class _SettingsSheet extends StatelessWidget {
  final AuthController auth;
  const _SettingsSheet({required this.auth});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        color:   const Color(0xE8101020),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFF2A2A4A),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B9D)),
            title:   const Text('Sign Out', style: TextStyle(color: Colors.white)),
            onTap:   () { Navigator.pop(context); auth.signOut(); },
          ),
          const SizedBox(height: 12),
        ]),
      ),
    ),
  );
}

// ── Skeleton loader ───────────────────────────────────────────────────────────
class _RoadmapSkeleton extends StatelessWidget {
  const _RoadmapSkeleton();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: List.generate(3, (i) => Container(
      margin:      const EdgeInsets.only(bottom: 12),
      height:      80,
      decoration:  BoxDecoration(
        color:        const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(18),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: const Color(0xFF1A1A2E)))),
  );
}

class _ErrorCard extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorCard({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      const Text('😕', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 8),
      Text(msg, style: const TextStyle(color: Color(0xFF888899)),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B5EA7)),
        child: const Text('Retry', style: TextStyle(color: Colors.white)),
      ),
    ]),
  );
}

class _CefrBadge extends StatelessWidget {
  final String level;
  const _CefrBadge({required this.level});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF7B5EA7), Color(0xFF00D4FF)]),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(level,
        style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 13)),
  );
}

