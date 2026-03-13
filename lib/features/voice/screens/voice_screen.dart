// lib/features/voice/screens/voice_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/voice_controller.dart';
import '../../../services/gemini_live_service.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(VoiceController());
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => ctrl.endCall(),
      child: Scaffold(
        backgroundColor: const Color(0xFF04040A),
        body: Stack(children: [
          // ── Animated background ──────────────────────────────────
          const _CallBackground(),
          // ── Main content ─────────────────────────────────────────
          SafeArea(
            child: Column(children: [
              // Top bar
              _TopBar(ctrl: ctrl),
              // AI avatar + status
              Expanded(child: _CallCenter(ctrl: ctrl)),
              // Transcript
              _TranscriptArea(ctrl: ctrl),
              // Controls
              _CallControls(ctrl: ctrl),
              const SizedBox(height: 32),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Animated mesh background ──────────────────────────────────────────────────
class _CallBackground extends StatefulWidget {
  const _CallBackground();
  @override
  State<_CallBackground> createState() => _CallBackgroundState();
}

class _CallBackgroundState extends State<_CallBackground>
    with TickerProviderStateMixin {
  late final AnimationController _orb1;
  late final AnimationController _orb2;

  @override
  void initState() {
    super.initState();
    _orb1 = AnimationController(vsync: this, duration: Duration(seconds: 4))
        ..repeat(reverse: true);
    _orb2 = AnimationController(vsync: this, duration: Duration(seconds: 6))
        ..repeat(reverse: true);
  }

  @override
  void dispose() { _orb1.dispose(); _orb2.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(children: [
      Container(color: const Color(0xFF04040A)),
      AnimatedBuilder(
        animation: _orb1,
        builder: (_, __) => Positioned(
          left:   -60 + _orb1.value * 40,
          top:    size.height * 0.1 + _orb1.value * 60,
          child:  Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF7B5EA7).withOpacity(0.25),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      AnimatedBuilder(
        animation: _orb2,
        builder: (_, __) => Positioned(
          right: -80 + _orb2.value * 30,
          bottom: size.height * 0.2 + _orb2.value * 40,
          child: Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF00D4FF).withOpacity(0.2),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoiceController ctrl;
  const _TopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: Row(children: [
      // Topic chip
      Expanded(child:  Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        const Color(0xFF0F0F1A),
          borderRadius: BorderRadius.circular(100),
          border:       Border.all(color: const Color(0xFF1E1E32)),
        ),
        child: Row(children: [
          const Icon(Icons.topic_outlined, color: Color(0xFF666688), size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(ctrl.topic,
              style: const TextStyle(color: Color(0xFFB0B0CC), fontSize: 12),
              overflow: TextOverflow.ellipsis)),
        ]),
      )),
      const SizedBox(width: 12),
      // Timer
      Obx(() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        const Color(0xFF0F0F1A),
          borderRadius: BorderRadius.circular(100),
          border:       Border.all(color: const Color(0xFF1E1E32)),
        ),
        child: Row(children: [
          const Icon(Icons.timer_outlined, color: Color(0xFF666688), size: 14),
          const SizedBox(width: 6),
          Text(ctrl.formattedDuration,
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      )),
    ]),
  );
}

// ── Center — avatar + state indicator ────────────────────────────────────────
class _CallCenter extends StatelessWidget {
  final VoiceController ctrl;
  const _CallCenter({required this.ctrl});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Mira avatar with pulse rings
      GetBuilder<VoiceController>(
        builder: (_) => _MiraAvatar(state: ctrl.callState),
      ),
      const SizedBox(height: 24),
      // Status text
      GetBuilder<VoiceController>(
        builder: (_) => _StatusLabel(state: ctrl.callState),
      ),
      const SizedBox(height: 12),
      // AI reply preview (last few words)
      Obx(() => ctrl.aiReply.isNotEmpty
          ? Container(
              margin:  const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:        const Color(0xFF0F0F1A),
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(color: const Color(0xFF1E1E32)),
              ),
              child: Text(
                // Show last 80 chars of AI reply
                ctrl.aiReply.length > 80
                    ? '…${ctrl.aiReply.substring(ctrl.aiReply.length - 80)}'
                    : ctrl.aiReply,
                style: const TextStyle(color: Color(0xFFB0B0CC), fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(duration: 300.ms)
          : const SizedBox()),
    ],
  );
}

class _MiraAvatar extends StatefulWidget {
  final CallState state;
  const _MiraAvatar({required this.state});
  @override
  State<_MiraAvatar> createState() => _MiraAvatarState();
}

class _MiraAvatarState extends State<_MiraAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;
  @override
  void initState() {
    super.initState();
    _ring = AnimationController(vsync: this, duration: 1500.ms)..repeat();
  }
  @override
  void dispose() { _ring.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.state == CallState.listening ||
        widget.state == CallState.aiSpeaking;
    return SizedBox(
      width: 180, height: 180,
      child: Stack(alignment: Alignment.center, children: [
        // Pulse rings when active
        if (isActive) ...[
          AnimatedBuilder(
            animation: _ring,
            builder: (_, __) {
              final v = _ring.value;
              return Container(
                width:  100 + 60 * v, height: 100 + 60 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF7B5EA7).withOpacity(0.4 * (1 - v)),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _ring,
            builder: (_, __) {
              final v = (_ring.value + 0.5) % 1.0;
              return Container(
                width:  100 + 60 * v, height: 100 + 60 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withOpacity(0.3 * (1 - v)),
                    width: 1,
                  ),
                ),
              );
            },
          ),
        ],
        // Avatar circle
        Container(
          width:  100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: isActive
                  ? [const Color(0xFF7B5EA7), const Color(0xFF00D4FF)]
                  : [const Color(0xFF1A1A2E), const Color(0xFF2A2A4A)],
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color:      const Color(0xFF7B5EA7).withOpacity(0.4),
                blurRadius: 24, spreadRadius: 2,
              ),
            ] : [],
          ),
          child: Center(
            child: Text(
              widget.state == CallState.connecting ? '⏳'
                : widget.state == CallState.error   ? '⚠️'
                : '🎙️',
              style: const TextStyle(fontSize: 44),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final CallState state;
  const _StatusLabel({required this.state});
  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (state) {
      CallState.connecting  => ('Connecting to Mira…', const Color(0xFFFFB547)),
      CallState.connected   => ('Mira is ready', const Color(0xFF00E5A0)),
      CallState.listening   => ('Listening…', const Color(0xFF7B5EA7)),
      CallState.aiSpeaking  => ('Mira is speaking', const Color(0xFF00D4FF)),
      CallState.error       => ('Connection error', const Color(0xFFFF4D6A)),
      CallState.idle        => ('', Colors.transparent),
    };
    return Text(text,
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600))
        .animate(key: ValueKey(state)).fadeIn(duration: 300.ms);
  }
}

// ── Scrolling transcript ───────────────────────────────────────────────────────
class _TranscriptArea extends StatelessWidget {
  final VoiceController ctrl;
  const _TranscriptArea({required this.ctrl});

  @override
  Widget build(BuildContext context) => Obx(() {
    if (ctrl.messages.isEmpty) return const SizedBox(height: 40);
    return SizedBox(
      height: 130,
      child: ListView.builder(
        padding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        reverse:     true,
        itemCount:   ctrl.messages.length,
        itemBuilder: (_, i) {
          final msg = ctrl.messages[ctrl.messages.length - 1 - i];
          return _BubbleRow(isUser: msg.isUser, text: msg.text);
        },
      ),
    );
  });
}

class _BubbleRow extends StatelessWidget {
  final bool   isUser;
  final String text;
  const _BubbleRow({required this.isUser, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) ...[
          const CircleAvatar(radius: 12,
              backgroundColor: Color(0xFF7B5EA7),
              child: Text('M', style: TextStyle(color: Colors.white, fontSize: 10))),
          const SizedBox(width: 6),
        ],
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:        isUser
                ? const Color(0xFF7B5EA7).withOpacity(0.2)
                : const Color(0xFF12121E),
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: isUser
                ? const Color(0xFF7B5EA7).withOpacity(0.3)
                : const Color(0xFF1E1E32)),
          ),
          child: Text(text,
              style: const TextStyle(color: Color(0xFFDDDDEE), fontSize: 12,
                  height: 1.4)),
        )),
        if (isUser) const SizedBox(width: 6),
      ],
    ),
  );
}

// ── Controls ──────────────────────────────────────────────────────────────────
class _CallControls extends StatelessWidget {
  final VoiceController ctrl;
  const _CallControls({required this.ctrl});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      // End call
      _CircleBtn(
        icon:  Icons.call_end_rounded,
        color: const Color(0xFFFF4D6A),
        size:  64,
        onTap: ctrl.endCall,
      ),
      // Mic hold-to-talk
      GetBuilder<VoiceController>(builder: (_) {
        final isListening = ctrl.callState == CallState.listening;
        return GestureDetector(
          onTapDown:   (_) => ctrl.startSpeaking(),
          onTapUp:     (_) => ctrl.stopSpeaking(),
          onTapCancel: ()  => ctrl.stopSpeaking(),
          child: AnimatedContainer(
            duration: 200.ms,
            width:    80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isListening
                  ? const LinearGradient(
                      colors: [Color(0xFF7B5EA7), Color(0xFF00D4FF)])
                  : const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF2A2A4A)]),
              boxShadow: isListening ? [
                BoxShadow(
                  color:      const Color(0xFF7B5EA7).withOpacity(0.5),
                  blurRadius: 20),
              ] : [],
            ),
            child: Icon(
              isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: Colors.white, size: 36,
            ),
          ),
        );
      }),
      // Waveform visualizer (decorative)
      _WaveVisualizer(),
    ]),
  );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final double   size;
  final VoidCallback onTap;
  const _CircleBtn({
    required this.icon, required this.color,
    this.size = 56, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Icon(icon, color: color, size: size * 0.45),
    ),
  );
}

class _WaveVisualizer extends StatefulWidget {
  @override
  State<_WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<_WaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 800.ms)..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 56, height: 56,
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (i) {
          final h = 4 + sin(_ctrl.value * pi + i * 0.8) * 14;
          return Container(
            width:  3,
            height: h.abs() + 4,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF7B5EA7), Color(0xFF00D4FF)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    ),
  );
}
