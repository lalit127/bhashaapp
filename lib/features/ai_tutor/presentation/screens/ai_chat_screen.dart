import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../features/subscription/revenuecat_service.dart';
import '../../../../core/constants/app_routes.dart';

class _Msg {
  final String text;
  final bool isUser;
  final String? correction, pronunciation, xpLabel;
  _Msg({required this.text, required this.isUser,
    this.correction, this.pronunciation, this.xpLabel});
}

class AiChatController extends GetxController {
  final _api     = Get.find<ApiService>();
  final _storage = Get.find<StorageService>();

  final messages = <_Msg>[].obs;
  final typing   = false.obs;
  final history  = <Map<String, String>>[];
  final topic    = 'daily conversation'.obs;
  final fearScore= 5.obs;

  @override
  void onInit() {
    super.onInit();
    final lang = _storage.getSelectedLanguage() ?? 'hindi';
    messages.add(_Msg(
      text: 'Namaste! 🙏 Main tera AI English teacher hoon.\n\nAaj hum kya practice karein? (Greetings / Office / Shopping / Interview)',
      isUser: false,
    ));
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    messages.add(_Msg(text: text, isUser: true));
    history.add({'role': 'user', 'content': text});
    typing.value = true;

    final resp = await _api.sendChatMessage(
      nativeLanguage: _storage.getSelectedLanguage() ?? 'hindi',
      cefrLevel: _storage.getSelectedLevel() ?? 'A1',
      occupation: _storage.getUserOccupation() ?? 'student',
      topic: topic.value,
      sessionGoal: 'Practice English confidently',
      userMessage: text,
      history: history.take(10).toList(),
      fearScore: fearScore.value,
    );

    typing.value = false;
    if (resp != null) {
      final turn = resp['turn'] as Map<String, dynamic>? ?? {};
      final tutorText = '${turn['tutorSetupNative'] ?? ''}\n\n'
          '${turn['targetEnglish'] ?? ''}'.trim();
      final correction = turn['correction'] as Map<String, dynamic>?;
      final correctionText = (correction?['original'] != null)
          ? '${correction!['praiseFirst']}\n❌ ${correction['original']} → ✅ ${correction['corrected']}'
          : null;

      messages.add(_Msg(
        text: tutorText,
        isUser: false,
        correction: correctionText,
        pronunciation: turn['turn']?['tutorSetupNative'],
        xpLabel: turn['metrics'] != null
            ? '+${turn['metrics']['xpEarned'] ?? 5} XP' : null,
      ));
      history.add({'role': 'assistant', 'content': tutorText});

      if ((turn['encouragementNative'] ?? '').toString().isNotEmpty) {
        messages.add(_Msg(text: turn['encouragementNative'].toString(), isUser: false));
      }
    } else {
      messages.add(_Msg(
        text: 'Internet problem hua. Dobara try karo! 🔄',
        isUser: false,
      ));
    }
  }
}

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.find<RevenueCatService>().isPro) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
        Get.offNamed(AppRoutes.paywall, arguments: 'ai_chat'));
      return const SizedBox();
    }
    final ctrl = Get.put(AiChatController());
    final textCtrl = TextEditingController();
    final scrollCtrl = ScrollController();

    void scrollDown() => Future.delayed(const Duration(milliseconds: 120), () {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Column(children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          color: AppColors.bgWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            GestureDetector(onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.indigoLight,
                borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AI Tutor — Alex', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: AppColors.textPrimary, fontFamily: 'Nunito')),
              Obx(() => Text('Topic: ${ctrl.topic.value}', style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted, fontFamily: 'Nunito'))),
            ])),
            // Fear meter display
            Obx(() => GestureDetector(
              onTap: () {
                ctrl.fearScore.value = ctrl.fearScore.value == 10 ? 1
                    : ctrl.fearScore.value + 1;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ctrl.fearScore.value >= 7 ? AppColors.errorLight
                    : ctrl.fearScore.value >= 4 ? AppColors.goldLight
                    : AppColors.successLight,
                  borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(ctrl.fearScore.value >= 7 ? '😨'
                    : ctrl.fearScore.value >= 4 ? '😐' : '😎'),
                  const SizedBox(width: 4),
                  Text('${ctrl.fearScore.value}/10', style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary, fontFamily: 'Nunito')),
                ])),
            )),
          ]),
        ),
        // ── Quick topic chips ────────────────────────────────────────────
        Container(
          color: AppColors.bgWhite,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Obx(() => Row(children: [
              'daily conversation', 'job interview', 'office email', 'greetings', 'shopping',
            ].map((t) {
              final active = ctrl.topic.value == t;
              return GestureDetector(
                onTap: () => ctrl.topic.value = t,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryLight : AppColors.bgSection,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                      width: active ? 1.5 : 1)),
                  child: Text(t, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                    color: active ? AppColors.primaryDark : AppColors.textMuted))),
              );
            }).toList()))),
        ),
        const Divider(height: 1, color: AppColors.border),
        // ── Messages ────────────────────────────────────────────────────
        Expanded(child: Obx(() {
          scrollDown();
          return ListView.builder(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: ctrl.messages.length + (ctrl.typing.value ? 1 : 0),
            itemBuilder: (_, i) {
              if (ctrl.typing.value && i == ctrl.messages.length) {
                return const _TypingBubble();
              }
              return _ChatBubble(msg: ctrl.messages[i]);
            },
          );
        })),
        // ── Input ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.bgWhite,
            border: Border(top: BorderSide(color: AppColors.border, width: 1.5))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: textCtrl,
              style: const TextStyle(
                fontSize: 15, color: AppColors.textPrimary, fontFamily: 'Nunito'),
              decoration: InputDecoration(
                hintText: 'Type in Hindi or English...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Nunito'),
                filled: true, fillColor: AppColors.bgSection,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              onSubmitted: (t) { ctrl.send(t); textCtrl.clear(); },
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () { ctrl.send(textCtrl.text); textCtrl.clear(); },
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary,
                  boxShadow: [BoxShadow(color: AppColors.primaryDark,
                    offset: const Offset(0, 3), blurRadius: 0)]),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
          ]),
        ),
      ])),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _Msg msg;
  const _ChatBubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(width: 34, height: 34,
              decoration: BoxDecoration(color: AppColors.indigoLight,
                borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16)))),
            const SizedBox(width: 8),
          ],
          Flexible(child: Column(
            crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: msg.isUser ? AppColors.primaryLight : AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: msg.isUser ? const Radius.circular(4) : null,
                    bottomLeft: !msg.isUser ? const Radius.circular(4) : null),
                  border: Border.all(
                    color: msg.isUser ? AppColors.primary.withOpacity(0.3) : AppColors.border)),
                child: Text(msg.text, style: const TextStyle(
                  fontSize: 15, color: AppColors.textPrimary,
                  fontFamily: 'Nunito', height: 1.5))),
              if (msg.correction != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.3))),
                  child: Text(msg.correction!, style: const TextStyle(
                    fontSize: 13, color: AppColors.primaryDark,
                    fontFamily: 'Nunito', fontWeight: FontWeight.w600))),
              ],
              if (msg.xpLabel != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(10)),
                  child: Text(msg.xpLabel!, style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: AppColors.gold, fontFamily: 'Nunito'))),
              ],
            ],
          )),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(color: AppColors.indigoLight, borderRadius: BorderRadius.circular(10)),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16)))),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _Dot(delay: 0), _Dot(delay: 200), _Dot(delay: 400),
        ])),
    ]));
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override State<_Dot> createState() => _DotState();
}
class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
    _anim = Tween(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _anim.value),
      child: Container(
        width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textMuted))));
}
