import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key});
  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _hasResult = false;
  int _score = 0;
  late AnimationController _waveController;

  final _phrases = ['नमस्ते', 'धन्यवाद', 'आप कैसे हैं?', 'मेरा नाम है'];
  int _phraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() { _isRecording = true; _hasResult = false; });
    await Future.delayed(const Duration(seconds: 3));
    // Simulate scoring — replace with real Whisper API call
    setState(() {
      _isRecording = false;
      _hasResult = true;
      _score = 78 + (DateTime.now().millisecond % 20); // demo score
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Pronunciation Practice')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('SAY THIS PHRASE', style: TextStyle(
                fontSize: 12, letterSpacing: 2, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(_phrases[_phraseIndex], textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 48),
            // Mic button
            GestureDetector(
              onTap: _isRecording ? null : _startRecording,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isRecording) ...[
                      Container(
                        width: 120 + 20 * _waveController.value,
                        height: 120 + 20 * _waveController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.rose.withOpacity(0.1 * _waveController.value)),
                      ),
                    ],
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? AppColors.rose.withOpacity(0.2) : AppColors.saffron.withOpacity(0.15),
                        border: Border.all(
                          color: _isRecording ? AppColors.rose : AppColors.saffron, width: 3),
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: _isRecording ? AppColors.rose : AppColors.saffron, size: 44),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_isRecording ? 'Listening... speak now' : 'Tap to record',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
            const SizedBox(height: 40),
            if (_hasResult) _buildScoreCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final color = _score >= 80 ? AppColors.emerald : _score >= 60 ? AppColors.gold : AppColors.rose;
    final label = _score >= 80 ? 'Excellent!' : _score >= 60 ? 'Good job!' : 'Keep practicing';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Text('$_score/100', style: TextStyle(
                  fontSize: 48, fontWeight: FontWeight.w900, color: color)),
              Text(label, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _startRecording,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border)),
                  child: const Center(child: Text('Try Again', style: TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _phraseIndex = (_phraseIndex + 1) % _phrases.length;
                  _hasResult = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('Next Phrase', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700))),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
