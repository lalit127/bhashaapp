import 'package:bhashaapp/features/subscription/revenuecat_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/analytics_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  List<Package> _packages = [];
  bool _loading = true;
  bool _purchasing = false;
  int _selectedIndex = 1; // Default to yearly (index 1)

  @override
  void initState() {
    super.initState();
    _loadOfferings();
    // Log paywall view
    final trigger = Get.arguments?['trigger'] as String? ?? 'unknown';
    Get.find<AnalyticsService>().logPaywallView(trigger);
  }

  Future<void> _loadOfferings() async {
    final packages = await Get.find<RevenueCatService>().getOfferings();
    setState(() {
      _packages = packages;
      _loading = false;
      // Default select yearly if available
      if (packages.length > 1) _selectedIndex = 1;
    });
  }

  Future<void> _purchase() async {
    if (_packages.isEmpty || _purchasing) return;
    setState(() => _purchasing = true);

    try {
      final success = await Get.find<RevenueCatService>()
          .purchasePackage(_packages[_selectedIndex]);
      if (success) {
        Get.find<AnalyticsService>().logSubscriptionStart(
          _packages[_selectedIndex].packageType == PackageType.annual
              ? 'yearly'
              : 'monthly',
        );
        Get.back();
        Get.snackbar(
          '🎉 Welcome to Pro!',
          'All AI features are now unlocked.',
          backgroundColor: AppColors.teal,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildFeatureList(),
                    const SizedBox(height: 28),
                    _buildPlansSection(),
                    const SizedBox(height: 20),
                    _buildSocialProof(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // Gradient background
        Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bgCard, AppColors.bgDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
            onPressed: () => Get.back(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.saffron],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unlock Pro',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Learn faster with AI-powered tutoring',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    const features = [
      _Feature('🤖', 'AI Conversation Tutor',
          'Chat with AI in Hindi, Gujarati & more', true),
      _Feature('🎙️', 'Pronunciation Feedback',
          'Get scored on your speaking accuracy', true),
      _Feature('✏️', 'Grammar Explanations',
          'Understand every mistake with context', true),
      _Feature('♾️', 'Unlimited Practice',
          'No daily limits — learn as much as you want', true),
      _Feature('🎯', 'Adaptive Lessons',
          'AI creates lessons based on your weak areas', true),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(f.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      f.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.teal, size: 22),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlansSection() {
    // Fallback demo plans when RevenueCat not configured
    final plans = _packages.isEmpty
        ? [
            _DemoPlan('Monthly', '₹199', '/month', false),
            _DemoPlan('Yearly', '₹1,499', '/year  •  Save 37%', true),
          ]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (plans != null)
          ...plans.asMap().entries.map((e) => _buildDemoPlanCard(e.key, e.value))
        else
          ..._packages.asMap().entries.map((e) => _buildPackageCard(e.key, e.value)),
      ],
    );
  }

  Widget _buildPackageCard(int index, Package pkg) {
    final selected = _selectedIndex == index;
    final isYearly = pkg.packageType == PackageType.annual;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: _PlanCardContainer(
        selected: selected,
        isRecommended: isYearly,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isYearly ? 'Yearly' : 'Monthly',
                    style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isYearly)
                    const Text('Save 37%',
                        style: TextStyle(color: AppColors.teal, fontSize: 12)),
                ],
              ),
            ),
            Text(
              pkg.storeProduct.priceString,
              style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoPlanCard(int index, _DemoPlan plan) {
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: _PlanCardContainer(
        selected: selected,
        isRecommended: plan.isRecommended,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.label,
                    style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    plan.subtitle,
                    style: const TextStyle(
                        color: AppColors.teal, fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: plan.price,
                    style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: plan.period,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (_) => const Text('⭐', style: TextStyle(fontSize: 18))),
              const SizedBox(width: 8),
              const Text(
                '4.8 / 5',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '"BhashaApp\'s AI tutor is incredible. I spoke my first Hindi sentence in just 2 weeks!"',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '— Priya M., Mumbai',
            style: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _purchasing ? null : _purchase,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppColors.saffron,
                shadowColor: AppColors.saffron.withOpacity(0.5),
                elevation: 12,
              ),
              child: _purchasing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Start Free Trial →',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              final restored =
                  await Get.find<RevenueCatService>().restorePurchases();
              if (restored) {
                Get.back();
                Get.snackbar('Purchases Restored', 'Pro features unlocked.',
                    backgroundColor: AppColors.teal,
                    colorText: Colors.white);
              }
            },
            child: const Text(
              'Restore Purchases',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          const Text(
            'Cancel anytime • Auto-renews • 7-day free trial',
            style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _PlanCardContainer extends StatelessWidget {
  final bool selected;
  final bool isRecommended;
  final Widget child;

  const _PlanCardContainer({
    required this.selected,
    required this.isRecommended,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.saffron.withOpacity(0.08)
                : AppColors.bgCard,
            border: Border.all(
              color: selected ? AppColors.saffron : AppColors.border,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: child,
        ),
        if (isRecommended)
          Positioned(
            top: -10,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.saffron, AppColors.rose],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'BEST VALUE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Feature {
  final String emoji;
  final String title;
  final String subtitle;
  final bool included;
  const _Feature(this.emoji, this.title, this.subtitle, this.included);
}

class _DemoPlan {
  final String label;
  final String price;
  final String period;
  final bool isRecommended;
  const _DemoPlan(this.label, this.price, this.period, this.isRecommended);

  String get subtitle => isRecommended ? 'Save 37% vs monthly' : 'Billed monthly';
}
