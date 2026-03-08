import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../language_pack/pack_service.dart';

class PackDownloadScreen extends StatefulWidget {
  const PackDownloadScreen({super.key});
  @override
  State<PackDownloadScreen> createState() => _PackDownloadScreenState();
}

class _PackDownloadScreenState extends State<PackDownloadScreen> {
  double _progress = 0;
  bool _isDownloading = false;
  bool _isDone = false;
  String _statusText = 'Download to learn offline — no internet needed later.';

  // Language emoji/name mapping
  static const _langMeta = {
    'hi': {'name': 'Hindi',    'emoji': '🔶', 'size': '18.4 MB'},
    'gu': {'name': 'Gujarati', 'emoji': '🌸', 'size': '14.2 MB'},
    'ta': {'name': 'Tamil',    'emoji': '🌊', 'size': '16.8 MB'},
    'te': {'name': 'Telugu',   'emoji': '⭐', 'size': '15.9 MB'},
    'mr': {'name': 'Marathi',  'emoji': '🏔️', 'size': '13.7 MB'},
    'bn': {'name': 'Bengali',  'emoji': '🌺', 'size': '17.1 MB'},
  };

  Future<void> _startDownload() async {
    final langCode = Get.find<StorageService>().getSelectedLanguage() ?? 'hi';
    setState(() { _isDownloading = true; _statusText = 'Downloading...'; });

    // Simulate download for now — replace with real PackService call
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() => _progress = i / 100);
    }

    setState(() {
      _isDone = true;
      _statusText = 'Pack ready! You can now learn offline.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Get.find<StorageService>().getSelectedLanguage() ?? 'hi';
    final meta = _langMeta[langCode] ?? _langMeta['hi']!;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepBadge(),
              const SizedBox(height: 16),
              Text('Download ${meta['name']} Pack',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_statusText, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.5)),
              const SizedBox(height: 48),

              // Progress circle
              _ProgressCircle(progress: _progress, emoji: meta['emoji']!,
                  isDone: _isDone),

              const SizedBox(height: 40),

              // Pack info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _PackInfoRow(icon: '📦', label: 'Pack size', value: meta['size']!),
                    const Divider(color: AppColors.border, height: 20),
                    _PackInfoRow(icon: '🎓', label: 'Lessons', value: '120+ lessons'),
                    const Divider(color: AppColors.border, height: 20),
                    _PackInfoRow(icon: '🔊', label: 'Audio', value: 'Native speaker audio'),
                    const Divider(color: AppColors.border, height: 20),
                    _PackInfoRow(icon: '📶', label: 'Offline', value: 'Works without internet'),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: _isDone
                    ? _GradientButton(
                        label: 'Start Learning! 🚀',
                        onTap: () async {
                          await Get.find<StorageService>().setOnboardingComplete();
                          Get.offAllNamed(AppRoutes.home);
                        })
                    : _isDownloading
                        ? _ProgressButton(progress: _progress)
                        : _GradientButton(
                            label: 'Download Pack (${meta['size']})',
                            onTap: _startDownload),
              ),
              const SizedBox(height: 12),
              if (!_isDownloading && !_isDone)
                TextButton(
                  onPressed: () async {
                    await Get.find<StorageService>().setOnboardingComplete();
                    Get.offAllNamed(AppRoutes.home);
                  },
                  child: const Text('Skip for now (requires internet)',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.saffron.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text('Step 3 of 4', style: TextStyle(
        color: AppColors.saffron, fontSize: 13, fontWeight: FontWeight.w700)),
  );
}

class _ProgressCircle extends StatelessWidget {
  final double progress;
  final String emoji;
  final bool isDone;
  const _ProgressCircle({required this.progress, required this.emoji, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160, height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? AppColors.emerald : AppColors.saffron),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isDone ? '✅' : emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                      color: AppColors.saffron)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackInfoRow extends StatelessWidget {
  final String icon, label, value;
  const _PackInfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
      const Spacer(),
      Text(value, style: const TextStyle(color: AppColors.textPrimary,
          fontSize: 14, fontWeight: FontWeight.w700)),
    ],
  );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: AppColors.saffron.withOpacity(0.4), blurRadius: 20)],
      ),
      child: Center(child: Text(label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
              color: Colors.white))),
    ),
  );
}

class _ProgressButton extends StatelessWidget {
  final double progress;
  const _ProgressButton({required this.progress});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Center(
      child: Text('Downloading... ${(progress * 100).toInt()}%',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
              color: AppColors.textMuted)),
    ),
  );
}
