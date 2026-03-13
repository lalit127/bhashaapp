// lib/features/nova/screens/nova_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/nova_controller.dart';

class MiraScreen extends StatelessWidget {
  const MiraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(MiraController());
    final textCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: Column(children: [
        // ── App bar ───────────────────────────────────────────────
        _MiraAppBar(ctrl: ctrl),

        // ── Messages ──────────────────────────────────────────────
        Expanded(child: _MessageList(ctrl: ctrl)),

        // ── Typing indicator ──────────────────────────────────────
        Obx(() => ctrl.isTyping.value
            ? const _TypingIndicator().animate().fadeIn(duration: 200.ms)
            : const SizedBox()),

        // ── Error ─────────────────────────────────────────────────
        Obx(() => ctrl.errorMsg.value != null
            ? _ErrorBanner(msg: ctrl.errorMsg.value!)
            : const SizedBox()),

        // ── Input ─────────────────────────────────────────────────
        _InputBar(textCtrl: textCtrl, ctrl: ctrl),
      ]),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────
class _MiraAppBar extends StatelessWidget {
  final MiraController ctrl;
  const _MiraAppBar({required this.ctrl});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E32))),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: ctrl.endSession,
        ),
        // Mira avatar
        Container(
          width:  40, height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFFB547)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('N',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mira',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            Text(ctrl.skillName,
                style: const TextStyle(color: Color(0xFF666688), fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ],
        )),
        // XP counter
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFFB547)]),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text('+${ctrl.totalXp.value} XP',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 11)),
        )),
      ]),
    ),
  );
}

// ── Message list ──────────────────────────────────────────────────────────────
class _MessageList extends StatefulWidget {
  final MiraController ctrl;
  const _MessageList({required this.ctrl});
  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ever(widget.ctrl.messages, (_) => _scrollDown());
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: 300.ms, curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Obx(() => ListView.builder(
    controller:  _scroll,
    padding:     const EdgeInsets.fromLTRB(16, 16, 16, 8),
    itemCount:   widget.ctrl.messages.length,
    itemBuilder: (_, i) {
      final msg = widget.ctrl.messages[i];
      return _MessageBubble(msg: msg, ctrl: widget.ctrl)
          .animate().fadeIn(duration: Duration(milliseconds: 300))
          .slideY(begin: 0.05, end: 0);
    },
  ));
}

// ── Message bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatefulWidget {
  final MiraMessage    msg;
  final MiraController ctrl;
  const _MessageBubble({required this.msg, required this.ctrl});
  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _showTranslation = false;
  bool _showGrammar     = false;

  @override
  Widget build(BuildContext context) {
    final msg    = widget.msg;
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Mira avatar
              if (!isUser) ...[
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFFFB547)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('N',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 13))),
                ),
                const SizedBox(width: 8),
              ],

              // Bubble
              Flexible(child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF7B5EA7), Color(0xFF5A3D8A)])
                      : null,
                  color: isUser ? null : const Color(0xFF12121E),
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4  : 18),
                  ),
                  border: isUser ? null
                      : Border.all(color: const Color(0xFF1E1E32)),
                  boxShadow: isUser ? [
                    BoxShadow(
                      color:      const Color(0xFF7B5EA7).withOpacity(0.25),
                      blurRadius: 12, offset: const Offset(0, 4)),
                  ] : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(msg.text,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, height: 1.5)),
                    // XP earned
                    if (!isUser && msg.xp > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:        const Color(0xFFFFB547).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text('+${msg.xp} XP',
                            style: const TextStyle(color: Color(0xFFFFB547),
                                fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              )),

              if (isUser) const SizedBox(width: 8),
            ],
          ),

          // ── Action row ────────────────────────────────────────────
          if (!isUser) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Row(children: [
                // Speak
                _ActionChip(
                  icon:  Icons.volume_up_rounded,
                  label: 'Speak',
                  onTap: () => widget.ctrl.speakMessage(msg.text),
                ),
                if (msg.translation != null) ...[
                  const SizedBox(width: 6),
                  _ActionChip(
                    icon:  Icons.translate_rounded,
                    label: _showTranslation ? 'Hide' : 'Translate',
                    onTap: () => setState(() => _showTranslation = !_showTranslation),
                  ),
                ],
                if (msg.grammarNote != null) ...[
                  const SizedBox(width: 6),
                  _ActionChip(
                    icon:  Icons.auto_fix_high_rounded,
                    label: _showGrammar ? 'Hide' : 'Grammar',
                    color: const Color(0xFFFF6B9D),
                    onTap: () => setState(() => _showGrammar = !_showGrammar),
                  ),
                ],
              ]),
            ),
            // Translation card
            if (_showTranslation && msg.translation != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 6, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        const Color(0xFF00D4FF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(
                        color: const Color(0xFF00D4FF).withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Text('🌐 ', style: TextStyle(fontSize: 12)),
                    Expanded(child: Text(msg.translation!,
                        style: const TextStyle(color: Color(0xFF88DDFF),
                            fontSize: 12, height: 1.4))),
                  ]),
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0),
            // Grammar note card
            if (_showGrammar && msg.grammarNote != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 6, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFFF6B9D).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(
                        color: const Color(0xFFFF6B9D).withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Text('📌 ', style: TextStyle(fontSize: 12)),
                    Expanded(child: Text(msg.grammarNote!,
                        style: const TextStyle(color: Color(0xFFFFAACC),
                            fontSize: 12, height: 1.4))),
                  ]),
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0),
            // Encouragement
            if (msg.encouragement != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 4, 16, 0),
                child: Text('✨ ${msg.encouragement}',
                    style: const TextStyle(color: Color(0xFFFFB547), fontSize: 11)),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _ActionChip({
    required this.icon, required this.label,
    this.color = const Color(0xFF666688), required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: color, fontSize: 10,
            fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ── Typing indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: 600.ms)..repeat(reverse: true); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
    child: Row(children: List.generate(3, (i) => AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final delay = i * 0.2;
        final v = ((_ctrl.value + delay) % 1.0);
        return Container(
          width:  6, height: 6,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
                const Color(0xFF444466), const Color(0xFFFF6B9D), v)!,
          ),
        );
      },
    ))),
  );
}

// ── Error banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
    margin:  const EdgeInsets.fromLTRB(16, 0, 16, 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color:        const Color(0xFFFF4D6A).withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: const Color(0xFFFF4D6A).withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Color(0xFFFF4D6A), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: const TextStyle(color: Color(0xFFFF9999), fontSize: 12))),
    ]),
  );
}

// ── Input bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController textCtrl;
  final MiraController        ctrl;
  const _InputBar({required this.textCtrl, required this.ctrl});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color:  Color(0xFF0F0F1A),
      border: Border(top: BorderSide(color: Color(0xFF1E1E32))),
    ),
    padding: EdgeInsets.only(
      left: 16, right: 8, top: 10,
      bottom: MediaQuery.of(context).viewInsets.bottom + 10,
    ),
    child: Row(children: [
      // Text field
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: textCtrl,
            style:      const TextStyle(color: Colors.white, fontSize: 14),
            maxLines:   4, minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (v) {
              ctrl.send(v);
              textCtrl.clear();
            },
            decoration: InputDecoration(
              hintText:  'Type your reply…',
              hintStyle: const TextStyle(color: Color(0xFF444466)),
              filled:    true,
              fillColor: const Color(0xFF12121E),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide:   BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Color(0xFFFF6B9D), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Color(0xFF1E1E32)),
              ),
            ),
          ),
        ),
      )),
      const SizedBox(width: 8),
      // Send button
      Obx(() => GestureDetector(
        onTap: () {
          ctrl.send(textCtrl.text);
          textCtrl.clear();
        },
        child: AnimatedContainer(
          duration: 200.ms,
          width:  48, height: 48,
          decoration: BoxDecoration(
            gradient: ctrl.isTyping.value
                ? null : const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFFB547)]),
            color:        ctrl.isTyping.value
                ? const Color(0xFF1A1A2E) : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            ctrl.isTyping.value
                ? Icons.hourglass_empty_rounded
                : Icons.send_rounded,
            color: Colors.white, size: 20,
          ),
        ),
      )),
    ]),
  );
}
