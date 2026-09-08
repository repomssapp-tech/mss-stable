import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/floating_logo.dart';
import '../../l10n/l10n.dart';
import '../login_screen.dart';
import '../../utils/responsive.dart';
import '../../utils/app_spacing.dart';

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
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLang = 'en';

  final List<LanguageOption> _languages = const [
    LanguageOption(
      code: 'en',
      nativeTitle: 'English',
      englishTitle: 'English',
      circleText: 'EN',
      circleBgColor: Color(0xFFEFF6FF), // Blue 50
      circleTextColor: Color(0xFF1D4ED8), // Blue 700
    ),
    LanguageOption(
      code: 'ta',
      nativeTitle: 'தமிழ்',
      englishTitle: 'Tamil',
      circleText: 'தமிழ்',
      circleBgColor: Color(0xFFECFDF5), // Emerald 50
      circleTextColor: Color(0xFF047857), // Emerald 700
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<AppProvider>(context, listen: false);
      // Seed from the ambient locale (driven by MaterialApp.locale) so the
      // preview defaults to the language the app is currently showing, then
      // fall back to the provider value / 'en'.
      final ambient = Localizations.localeOf(context).languageCode;
      setState(() {
        _selectedLang = (ambient == 'ta' || ambient == 'en')
            ? ambient
            : (provider.selectedLanguage.isEmpty
                ? 'en'
                : provider.selectedLanguage);
      });
    });
  }

  void _onLanguageSelected(String langCode) {
    setState(() {
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
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    context.l10n.languageSubtitle,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(flex: 2),

                              // 5. Restricted Language List (English, Tamil)
                              Column(
                                children: _languages.map((option) {
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
                                      padding: const EdgeInsets.all(AppSpacing.sm),
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
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1E3A8A),
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.hairline),
                                          Text(
                                            context.l10n.changeAnytime,
                                            style: GoogleFonts.inter(
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
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: FitOneLine(
                                          child: Text(
                                            context.l10n.navContinueButton,
                                            style: GoogleFonts.inter(
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
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
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A), // Slate 900
                    ),
                  ),
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    option.englishTitle,
                    style: GoogleFonts.inter(
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
