import 'package:flutter/material.dart';
import '../../utils/app_size.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/language_pack_manager.dart';
import '../../widgets/common/floating_logo.dart';
import '../../l10n/l10n.dart';
import '../login_screen.dart';
import '../../utils/responsive.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

class LanguageOption {
  final String code;
  final String nativeTitle;
  final String englishTitle;
  final String circleText;
  final Color circleBgColor;
  final Color circleTextColor;

  const LanguageOption({
    required this.code,
    required this.nativeTitle,
    required this.englishTitle,
    required this.circleText,
    required this.circleBgColor,
    required this.circleTextColor,
  });
}

class LanguageSelectionScreen extends StatefulWidget {
  /// True during first-run onboarding (splash / beta gate / navigation-mode
  /// screen): "Continue" moves the user forward to the login flow. False when
  /// opened later from Settings or Profile: "Continue" just applies the
  /// language and pops back — it must NOT re-enter the onboarding /
  /// navigation-mode flow.
  final bool isOnboarding;

  const LanguageSelectionScreen({super.key, this.isOnboarding = true});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLang = 'en';
  bool _hiSupported = false;
  // True once the user has tapped a language, so the async Hindi-support check
  // below never overrides an explicit choice.
  bool _userPicked = false;

  final List<LanguageOption> _languages = const [
    LanguageOption(
      code: 'en',
      nativeTitle: 'English',
      englishTitle: 'English',
      circleText: 'EN',
      circleBgColor: AppColors.primarySoft, // Blue 50
      circleTextColor: AppColors.primaryStrong, // Blue 700
    ),
    LanguageOption(
      code: 'ta',
      nativeTitle: 'தமிழ்',
      englishTitle: 'Tamil',
      circleText: 'தமிழ்',
      circleBgColor: AppColors.primarySoft, // Emerald 50
      circleTextColor: AppColors.primaryStrong, // Emerald 700
    ),
    LanguageOption(
      code: 'hi',
      nativeTitle: 'हिन्दी',
      englishTitle: 'Hindi',
      circleText: 'हिन्दी',
      circleBgColor: AppColors.languageHindiBg,
      circleTextColor: AppColors.languageHindiFg,
    ),
  ];

  List<LanguageOption> get _visibleLanguages => _languages.where((option) {
    if (option.code == 'hi') {
      return _hiSupported;
    }
    return true;
  }).toList();

  @override
  void initState() {
    super.initState();
    _checkLanguageSupport();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<AppProvider>(context, listen: false);
      // Seed from the ambient locale (driven by MaterialApp.locale) so the
      // preview defaults to the language the app is currently showing, then
      // fall back to the provider value / 'en'.
      final ambient = Localizations.localeOf(context).languageCode;
      setState(() {
        final candidate =
            (ambient == 'ta' ||
                ambient == 'en' ||
                (ambient == 'hi' && _hiSupported))
            ? ambient
            : (provider.selectedLanguage.isEmpty
                  ? 'en'
                  : provider.selectedLanguage);
        _selectedLang = (candidate == 'hi' && !_hiSupported) ? 'en' : candidate;
      });
    });
  }

  Future<void> _checkLanguageSupport() async {
    final supported = await LanguagePackManager.instance.isLanguageSupported(
      'hi',
    );
    if (mounted && supported != _hiSupported) {
      setState(() {
        _hiSupported = supported;
        if (!_hiSupported && _selectedLang == 'hi') {
          _selectedLang = 'en';
        }
        // initState could not pick Hindi before support was known, so a
        // Hindi-language user would see English pre-selected here.
        if (_hiSupported &&
            !_userPicked &&
            Localizations.localeOf(context).languageCode == 'hi') {
          _selectedLang = 'hi';
        }
      });
    }
  }

  void _onLanguageSelected(String langCode) {
    setState(() {
      _userPicked = true;
      _selectedLang = langCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    final scaffold = Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image from Asset
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background/Login_bg.webp',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Main content structure (Responsive scrolling layout)
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                            vertical: AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Spacer(flex: 2),

                              // 3. Isolated Floating Logo
                              const FloatingLogo(),

                              const Spacer(flex: 2),

                              // 4. Title & Subtitle
                              Column(
                                children: [
                                  Text(
                                    context.l10n.chooseYourLanguage,
                                    textAlign: TextAlign.center,
                                    style: context.text.titleMedium.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    context.l10n.languageSubtitle,
                                    textAlign: TextAlign.center,
                                    style: context.text.body.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(flex: 2),

                              // 5. Language List
                              Column(
                                children: _visibleLanguages.map((option) {
                                  final isSelected =
                                      _selectedLang == option.code;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                    ),
                                    child: _buildLanguageItem(
                                      option,
                                      isSelected,
                                    ),
                                  );
                                }).toList(),
                              ),

                              const Spacer(flex: 1),

                              // 6. Info Box Card
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft, // Blue 50
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primaryBorder,
                                  ), // Blue 200
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.sm,
                                      ),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primaryTint,
                                      ),
                                      child: const Icon(
                                        Icons.language,
                                        color: AppColors.primary, // Blue 600
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.l10n.yourLanguageExperience,
                                            style: context.text.button.copyWith(
                                              color: AppColors.primaryDeep,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.hairline,
                                          ),
                                          Text(
                                            context.l10n.changeAnytime,
                                            style: context.text.bodySmall
                                                .copyWith(
                                                  color:
                                                      AppColors.primaryStrong,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(flex: 2),

                              // 7. Continue Button
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2563EB,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    provider.changeLanguage(_selectedLang);
                                    if (widget.isOnboarding) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          context.l10n.navContinueButton,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: AppSize.icon,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Spacer(flex: 1),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    // Live per-tap preview: content inside resolves `context.l10n` to the
    // currently tapped language before Continue commits it via the provider.
    return Localizations.override(
      context: context,
      locale: Locale(_selectedLang),
      child: scaffold,
    );
  }

  Widget _buildLanguageItem(LanguageOption option, bool isSelected) {
    return InkWell(
      onTap: () => _onLanguageSelected(option.code),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border, // Blue 500 or Slate 200
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Colored circle with native symbol/text
            Container(
              width: adaptiveSize(context, base: 40, min: 28, max: 40),
              height: adaptiveSize(context, base: 40, min: 28, max: 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: option.circleBgColor,
              ),
              alignment: Alignment.center,
              child: Text(
                option.circleText,
                style: context.text.label.copyWith(
                  color: option.circleTextColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Language names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    option.nativeTitle,
                    style: context.text.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    option.englishTitle,
                    style: context.text.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator (Checked circle vs empty circle)
            isSelected
                ? const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 22,
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderStrong, // Slate 300
                        width: 1.5,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
