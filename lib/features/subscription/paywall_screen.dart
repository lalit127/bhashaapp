import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/duo_button.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});
  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPlan = 1; // 0=monthly, 1=yearly
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildHero(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFFF6B2B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('7 DAYS FREE', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900,
                      color: Colors.white, fontFamily: 'Nunito',
                    )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('👑', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('BhashaApp Pro', style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.w900,
              color: Colors.white, fontFamily: 'Nunito',
            )),
            const SizedBox(height: 6),
            const Text('English mein confident bano', style: TextStyle(
              fontSize: 16, color: Colors.white70, fontFamily: 'Nunito',
            )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildFeatureList(),
          const SizedBox(height: 24),
          _buildPlanSelector(),
          const SizedBox(height: 24),
          _buildCTA(),
          const SizedBox(height: 16),
          _buildSocialProof(),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {},
            child: const Text('Restore Purchase',
                style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito')),
          ),
          const Text('Cancel anytime • Secure UPI Payment',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Nunito')),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': '🤖', 'title': 'AI Voice Tutor', 'sub': 'Real voice conversations in English'},
      {'icon': '🎯', 'title': 'Mistake DNA Profile', 'sub': 'Your personal error patterns fixed'},
      {'icon': '💼', 'title': 'Job-Specific English', 'sub': 'IT, Sales, Teacher, Doctor tracks'},
      {'icon': '🎬', 'title': 'Shadow Speaking', 'sub': 'Practice with Bollywood & TED clips'},
      {'icon': '📧', 'title': 'WhatsApp Coach', 'sub': 'Fix your messages before you send'},
      {'icon': '🏆', 'title': 'Live Practice Rooms', 'sub': 'Speak with other learners live'},
    ];
    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(f['icon']!, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['title']!, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary, fontFamily: 'Nunito',
                )),
                Text(f['sub']!, style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted, fontFamily: 'Nunito',
                )),
              ],
            )),
            const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPlanSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose your plan:', style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary, fontFamily: 'Nunito',
        )),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _PlanCard(
            title: 'Monthly',
            price: '₹199',
            period: '/month',
            isSelected: _selected == 0,
            badge: null,
            onTap: () => setState(() => _selectedPlan = 0),
          )),
          const SizedBox(width: 12),
          Expanded(child: _PlanCard(
            title: 'Yearly',
            price: '₹999',
            period: '/year',
            perMonth: '₹83/mo',
            isSelected: _selectedPlan == 1,
            badge: 'BEST VALUE',
            onTap: () => setState(() => _selectedPlan = 1),
          )),
        ]),
      ],
    );
  }

  int get _selected => _selectedPlan;

  Widget _buildCTA() {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: DuoButton.saffron(
          text: 'Start Free Trial →',
          onTap: () => Get.back(),
          emoji: '🚀',
        ),
      ),
      const SizedBox(height: 10),
      const Text('7 days free, then auto-renews. Cancel anytime.',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Nunito')),
    ]);
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSection,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('4.8 / 5', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900,
              color: AppColors.textPrimary, fontFamily: 'Nunito',
            )),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '"Pro ne meri interview crack karne mein help ki. Pehli salary aayi aur yeh app ka shukriya diya."',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13, color: AppColors.textSecondary,
            fontFamily: 'Nunito', fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 6),
        const Text('— Rohit S., Surat', style: TextStyle(
          fontSize: 12, color: AppColors.textMuted,
          fontFamily: 'Nunito', fontWeight: FontWeight.w700,
        )),
      ]),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title, price, period;
  final String? badge, perMonth;
  final bool isSelected;
  final VoidCallback onTap;
  const _PlanCard({required this.title, required this.price, required this.period,
      this.badge, this.perMonth, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.goldLight : AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.gold : AppColors.border,
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected ? [
          const BoxShadow(color: AppColors.gold, offset: Offset(0, 4), blurRadius: 0),
        ] : [
          BoxShadow(color: AppColors.border, offset: const Offset(0, 3), blurRadius: 0),
        ],
      ),
      child: Column(children: [
        if (badge != null) Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(badge!, style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w900,
            color: Colors.white, fontFamily: 'Nunito',
          )),
        ),
        if (badge != null) const SizedBox(height: 8),
        Text(title, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: AppColors.textMuted, fontFamily: 'Nunito',
        )),
        const SizedBox(height: 4),
        Text(price, style: const TextStyle(
          fontSize: 26, fontWeight: FontWeight.w900,
          color: AppColors.textPrimary, fontFamily: 'Nunito',
        )),
        Text(period, style: const TextStyle(
          fontSize: 12, color: AppColors.textMuted, fontFamily: 'Nunito',
        )),
        if (perMonth != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(perMonth!, style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: AppColors.primaryDark, fontFamily: 'Nunito',
            )),
          ),
        ],
      ]),
    ),
  );
}
