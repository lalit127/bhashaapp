// lib/features/auth/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: const Color(0xFF04040A),
      body: Stack(children: [
        // Orbs
        Positioned(top: -80, left: -60, child: _Orb(color: const Color(0xFF7B5EA7), size: 280)),
        Positioned(bottom: -60, right: -80, child: _Orb(color: const Color(0xFF00D4FF), size: 220)),
        // Content
        SafeArea(child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const Spacer(),
            // Logo
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7B5EA7), Color(0xFF00D4FF)]),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF7B5EA7).withOpacity(0.5),
                    blurRadius: 32, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.translate_rounded, color: Colors.white, size: 44),
            ).animate().scale(begin: const Offset(0.5, 0.5),
                duration: 700.ms, curve: Curves.elasticOut),

            const SizedBox(height: 28),

            Text('BhashaApp',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800,
                    letterSpacing: -1))
                .animate(delay: 200.ms).fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 10),

            Text('English speaking app for Indians',
                style: const TextStyle(color: Color(0xFF888899), fontSize: 15))
                .animate(delay: 300.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 48),

            // Feature pills
            Wrap(spacing: 8, runSpacing: 8,
                children: ['🎙️ Voice Practice', '🤖 AI Tutor', '📊 Track Progress',
                  '🇮🇳 Indian English']
                    .map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:        const Color(0xFF12121E),
                    borderRadius: BorderRadius.circular(100),
                    border:       Border.all(color: const Color(0xFF2A2A4A)),
                  ),
                  child: Text(t, style: const TextStyle(color: Color(0xFFB0B0CC), fontSize: 12)),
                )).toList())
                .animate(delay: 400.ms).fadeIn(duration: 400.ms),

            const Spacer(),

            // Sign in button

            // Error
            Obx(() => ctrl.error.value != null
                ? Text(ctrl.error.value!,
                    style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
                    textAlign: TextAlign.center)
                : const SizedBox()),

            const SizedBox(height: 12),
            const Text('By continuing you agree to our Terms & Privacy Policy',
                style: TextStyle(color: Color(0xFF444466), fontSize: 11),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ]),
        )),
      ]),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color  color;
  final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [
        color.withOpacity(0.3), Colors.transparent,
      ]),
    ),
  );
}
