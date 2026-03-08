import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/duo_button.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});
  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  String? _selected;

  final _languages = [
    {'code':'hi','name':'Hindi','native':'हिन्दी','flag':'🇮🇳','speakers':'600M speakers','color':Color(0xFFFF6B2B),'bg':Color(0xFFFFF3ED)},
    {'code':'gu','name':'Gujarati','native':'ગુજરાતી','flag':'🟠','speakers':'60M speakers','color':Color(0xFF5C6BC0),'bg':Color(0xFFEDE7F6)},
    {'code':'ta','name':'Tamil','native':'தமிழ்','flag':'🟢','speakers':'80M speakers','color':Color(0xFF00BFA5),'bg':Color(0xFFE0F7F4)},
    {'code':'te','name':'Telugu','native':'తెలుగు','flag':'🔵','speakers':'85M speakers','color':Color(0xFF1CB0F6),'bg':Color(0xFFE3F5FD)},
    {'code':'mr','name':'Marathi','native':'मराठी','flag':'🟡','speakers':'83M speakers','color':Color(0xFFFFB800),'bg':Color(0xFFFFF8E1)},
    {'code':'bn','name':'Bengali','native':'বাংলা','flag':'🔴','speakers':'230M speakers','color':Color(0xFFFF4081),'bg':Color(0xFFFFEBF2)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Apni bhasha chuniye',
                    style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted,
                      fontFamily: 'Nunito', fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Learn English from:',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary, fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._languages.map((lang) => _LangCard(
                    lang: lang,
                    isSelected: _selected == lang['code'],
                    onTap: () => setState(() => _selected = lang['code'] as String),
                  )),
                ],
              ),
            ),
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    color: AppColors.bgWhite,
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.bgSection,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textSecondary),
          ),
        ),
        const Spacer(),
        const Text('1 of 4', style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: AppColors.textMuted, fontFamily: 'Nunito',
        )),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    ),
  );

  Widget _buildBottom() => Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    color: AppColors.bgWhite,
    child: SizedBox(
      width: double.infinity,
      child: DuoButton(
        text: _selected == null ? 'Select a language' : 'Continue →',
        color: _selected == null ? AppColors.bgSection : AppColors.primary,
        shadowColor: _selected == null ? AppColors.border : AppColors.primaryDark,
        textColor: _selected == null ? AppColors.textMuted : Colors.white,
        onTap: _selected == null ? null : () {
          Get.find<StorageService>().saveSelectedLanguage(_selected!);
          Get.toNamed(AppRoutes.levelSelect);
        },
      ),
    ),
  );
}

class _LangCard extends StatelessWidget {
  final Map lang;
  final bool isSelected;
  final VoidCallback onTap;
  const _LangCard({required this.lang, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = lang['color'] as Color;
    final bg = lang['bg'] as Color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? bg : AppColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: color.withOpacity(0.2),
                blurRadius: 12, offset: const Offset(0, 4)),
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.bgSection,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  lang['native'] as String,
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang['name'] as String, style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900,
                    color: isSelected ? color : AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  )),
                  const SizedBox(height: 3),
                  Text(lang['speakers'] as String, style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted, fontFamily: 'Nunito',
                  )),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : AppColors.border, width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
