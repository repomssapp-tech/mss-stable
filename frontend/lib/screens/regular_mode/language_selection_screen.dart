import 'package:flutter/material.dart';
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
import '../../utils/language_names.dart';

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
  List<String> _offered = LanguagePackManager.baseLanguages;
  // True once the user has tapped a language, so the async check of what the
  // catalogue offers never overrides an explicit choice.
  bool _userPicked = false;

  // Circle colours by language; any other language gets the neutral pair.
  static const _circleColors = <String, (Color, Color)>{
    'en': (Color(0xFFEFF6FF), Color(0xFF1D4ED8)), // Blue 50, Blue 700
    'ta': (Color(0xFFECFDF5), Color(0xFF047857)), // Emerald 50, Emerald 700
    'hi': (AppColors.languageHindiBg, AppColors.languageHindiFg),
  };
  static const _neutralCircle = (
    AppColors.languageNeutralBg,
    AppColors.languageNeutralFg,
  );

  LanguageOption _optionFor(String code) {
    final (background, foreground) = _circleColors[code] ?? _neutralCircle;
    return LanguageOption(
      code: code,
      nativeTitle: languageEndonym(code),
      englishTitle: languageEnglishName(code),
      circleText: code == 'en' ? 'EN' : languageEndonym(code),
      circleBgColor: background,
      circleTextColor: foreground,
    );
  }

  List<LanguageOption> get _visibleLanguages =>
      _offered.map(_optionFor).toList();

  /// The language the app is showing now. The ambient locale (driven by
  /// MaterialApp.locale) says so, unless the choice has no interface strings
  /// and the locale resolved to English.
  String get _showingLanguage {
    final saved = Provider.of<AppProvider>(
      context,
      listen: false,
    ).selectedLanguage;
    return saved.isEmpty || LanguagePackManager.hasUiStrings(saved)
        ? Localizations.localeOf(context).languageCode
        : saved;
  }

  @override
  void initState() {
    super.initState();
    _loadOffered();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<AppProvider>(context, listen: false);
      // Seed so the preview defaults to the language the app is currently
      // showing, then fall back to the provider value / 'en'.
      setState(() {
        final showing = _showingLanguage;
        final candidate = _offered.contains(showing)
            ? showing
            : provider.selectedLanguage;
        _selectedLang = _offered.contains(candidate) ? candidate : 'en';
      });
    });
  }

  Future<void> _loadOffered() async {
    final offered = await LanguagePackManager.instance.offeredLanguages();
    if (!mounted) return;
    setState(() {
      _offered = offered;
      if (!offered.contains(_selectedLang)) _selectedLang = 'en';
      // The seed above could not pick a language before the offer was known,
      // so its user would see English pre-selected here.
      if (!_userPicked && offered.contains(_showingLanguage)) {
        _selectedLang = _showingLanguage;
      }
    });
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
                                    style: AppGoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    context.l10n.languageSubtitle,
                                    textAlign: TextAlign.center,
                                    style: AppGoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF64748B),
                                      height: 1.4,
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
                                  color: const Color(0xFFEFF6FF), // Blue 50
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
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
                                        color: Color(0xFFDBEAFE),
                                      ),
                                      child: const Icon(
                                        Icons.language,
                                        color: Color(0xFF2563EB), // Blue 600
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
                                            style: AppGoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1E3A8A),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.hairline,
                                          ),
                                          Text(
                                            context.l10n.changeAnytime,
                                            style: AppGoogleFonts.inter(
                                              fontSize: 11,
                                              color: const Color(0xFF1D4ED8),
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF2563EB,
                                    ), // Royal Blue
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg,
                                    ),
                                    elevation: 0,
                                  ),
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
                                        child: FitOneLine(
                                          child: Text(
                                            context.l10n.navContinueButton,
                                            style: AppGoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 20,
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
      locale: Locale(
        LanguagePackManager.hasUiStrings(_selectedLang) ? _selectedLang : 'en',
      ),
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
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE2E8F0), // Blue 500 or Slate 200
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
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
                style: TextStyle(
                  fontSize: option.circleText.length > 3 ? 10 : 13,
                  fontWeight: FontWeight.bold,
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
                    style: AppGoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A), // Slate 900
                    ),
                  ),
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    option.englishTitle,
                    style: AppGoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B), // Slate 500
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator (Checked circle vs empty circle)
            isSelected
                ? const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2563EB),
                    size: 22,
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFCBD5E1), // Slate 300
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
