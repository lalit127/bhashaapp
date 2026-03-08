import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/duo_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _langCtrl;
  late AnimationController _mascotCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _mascotBounce;
  int _langIndex = 0;

  final _langs = [
    {'text': 'हिंदी', 'sub': 'Hindi', 'color': Color(0xFFFF6B2B)},
    {'text': 'ગુજરાતી', 'sub': 'Gujarati', 'color': Color(0xFF5C6BC0)},
    {'text': 'தமிழ்', 'sub': 'Tamil', 'color': Color(0xFF00BFA5)},
    {'text': 'తెలుగు', 'sub': 'Telugu', 'color': Color(0xFFFFB800)},
    {'text': 'मराठी', 'sub': 'Marathi', 'color': Color(0xFFFF4081)},
    {'text': 'বাংলা', 'sub': 'Bengali', 'color': Color(0xFF4CAF50)},
  ];

  @override
  void initState() {
    super.initState();
    final storage = Get.find<StorageService>();
    if (storage.isOnboardingComplete()) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          Get.offAllNamed(AppRoutes.home));
      return;
    }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));

    _mascotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _mascotBounce = Tween<double>(begin: 0, end: -10)
        .animate(CurvedAnimation(parent: _mascotCtrl, curve: Curves.easeInOut));

    _langCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _langCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _langIndex = (_langIndex + 1) % _langs.length);
        _langCtrl.reset();
        _langCtrl.forward();
      }
    });

    _heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _langCtrl.forward());
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _langCtrl.dispose();
    _mascotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        child: FadeTransition(
          opacity: _heroFade,
          child: SlideTransition(
            position: _heroSlide,
            child: Column(
              children: [
                _buildTopStrip(),
                Expanded(child: _buildHero(size)),
                _buildBottom(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Green top strip like Duolingo
  Widget _buildTopStrip() {
    return Container(
      height: 6,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
    );
  }

  Widget _buildHero(Size size) {
    final lang = _langs[_langIndex];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),

        // Mascot — animated bounce
        AnimatedBuilder(
          animation: _mascotBounce,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _mascotBounce.value),
            child: _buildMascot(),
          ),
        ),

        const SizedBox(height: 32),

        // App name
        const Text(
          'BhashaApp',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Learn English in your language',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              fontFamily: 'Nunito',
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Animated language word
        SizedBox(
          height: 72,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5), end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Column(
              key: ValueKey(_langIndex),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang['text'] as String,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: lang['color'] as Color,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Language dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_langs.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _langIndex ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == _langIndex
                  ? _langs[i]['color'] as Color
                  : AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),

        const SizedBox(height: 32),

        // Stats strip
        _buildStatsStrip(),
      ],
    );
  }

  Widget _buildMascot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
          ),
        ),
        // Mascot character
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🦜', style: TextStyle(fontSize: 52)),
            ],
          ),
        ),
        // Star decoration
        Positioned(
          top: 8, right: 8,
          child: _StarBadge(emoji: '✨'),
        ),
      ],
    );
  }

  Widget _buildStatsStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatPill(emoji: '🔥', value: '7M+', label: 'Learners'),
          _StatPill(emoji: '🏆', value: '6', label: 'Languages'),
          _StatPill(emoji: '⭐', value: '4.8', label: 'Rating'),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: DuoButton(
              text: 'Get Started →',
              onTap: () => Get.toNamed(AppRoutes.languageSelect),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: DuoButton.outline(
              text: 'I already have an account',
              onTap: () => Get.toNamed(AppRoutes.home),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Free forever • No credit card required',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarBadge extends StatelessWidget {
  final String emoji;
  const _StarBadge({required this.emoji});
  @override
  Widget build(BuildContext context) => Container(
    width: 28, height: 28,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.goldLight),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 14))),
  );
}

class _StatPill extends StatelessWidget {
  final String emoji, value, label;
  const _StatPill({required this.emoji, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(
        fontSize: 16, fontWeight: FontWeight.w900,
        color: AppColors.textPrimary, fontFamily: 'Nunito',
      )),
      Text(label, style: const TextStyle(
        fontSize: 11, color: AppColors.textMuted, fontFamily: 'Nunito',
      )),
    ],
  );
}
