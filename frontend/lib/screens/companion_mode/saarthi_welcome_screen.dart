import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/l10n.dart';
import '../../main.dart';
import '../../providers/app_state_provider.dart';
import '../../services/voice_agent_preferences.dart';
import '../../services/voice_agent_preview_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_toast.dart';
import '../../utils/app_spacing.dart';

class SaarthiWelcomeScreen extends StatefulWidget {
  const SaarthiWelcomeScreen({super.key});

  @override
  State<SaarthiWelcomeScreen> createState() => _SaarthiWelcomeScreenState();
}

class _SaarthiWelcomeScreenState extends State<SaarthiWelcomeScreen> {
  String _selectedLang = 'en';
  String _selectedVoice = VoiceAgentPreferences.defaultVoice;
  bool _previewingVoice = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _selectedLang = provider.selectedLanguage;
    VoiceAgentPreferences.loadVoice().then((voice) {
      if (mounted) setState(() => _selectedVoice = voice);
    });
  }

  Future<void> _selectVoice(String voice) async {
    setState(() => _selectedVoice = voice);
    await VoiceAgentPreferences.saveVoice(voice);
  }

  Future<void> _previewVoice() async {
    if (_previewingVoice) return;
    setState(() => _previewingVoice = true);
    try {
      await VoiceAgentPreviewService.preview(_selectedVoice);
    } catch (error) {
      if (!mounted) return;
      AppToast.showError(
        context,
        context.l10n.welcomePreviewVoiceError,
      );
    } finally {
      if (mounted) setState(() => _previewingVoice = false);
    }
  }

  static const Color kBrandBlue = Color(0xFF2563EB);
  static const Color kDarkBlue = Color(0xFF1E3A8A);
  static const Color kDarkSlate = Color(0xFF0F172A);
  static const Color kSlate500 = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    // Live per-tap preview: content inside resolves `context.l10n` to the
    // currently selected language before "Let's Begin" commits it via the
    // provider. Helper builders that need it take the below-override context.
    return Localizations.override(
      context: context,
      locale: Locale(_selectedLang),
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Hero Blue Section with Background & Avatar
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFEBF5FF), Color(0xFFF8FAFC)],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Background Image Overlay
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.8,
                                child: Image.asset(
                                  'assets/images/Background/companion intro bg.webp',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.xl,
                                right: AppSpacing.xl,
                                top: 44.0,
                                bottom: AppSpacing.lg,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Heading: Meet Saarthi
                                      Expanded(
                                        flex: 6,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              context.l10n.welcomeMeetPrefix,
                                              style: GoogleFonts.poppins(
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                                color: kDarkSlate,
                                                height: 1.1,
                                              ),
                                            ),
                                            Text(
                                              'Saarthi',
                                              style: GoogleFonts.poppins(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: kBrandBlue,
                                                height: 1.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Avatar right above the card (aligned to the right)
                                      Expanded(
                                        flex: 4,
                                        child: Align(
                                          alignment: Alignment.bottomRight,
                                          child: Transform.translate(
                                            offset: const Offset(
                                              0,
                                              10,
                                            ), // Shifting avatar down to sit on the card
                                            child: SizedBox(
                                              height: 100,
                                              child: Image.asset(
                                                'assets/images/saarthi/sarathi.webp',
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.android,
                                                      size: 60,
                                                      color: kBrandBlue,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.none),
                                  // Speech Card inside the blue header area
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.06,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(AppSpacing.sm),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEFF6FF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            color: kBrandBlue,
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
                                                context.l10n.welcomeIntroLine1,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: kDarkBlue,
                                                ),
                                              ),
                                              const SizedBox(height: AppSpacing.xs),
                                              Text(
                                                context.l10n.welcomeIntroLine2,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: kSlate500,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 2 & 3. Middle content area
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 2. "Saarthi can help you with" Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        context.l10n.welcomeSectionHeader,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: kDarkSlate,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildFeatureCard(
                                        icon: Icons.mic_none_rounded,
                                        title: context.l10n.welcomeFeatureTalkNaturally,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _buildFeatureCard(
                                        icon: Icons.language_outlined,
                                        title: context.l10n.welcomeFeatureFindSchemes,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildFeatureCard(
                                        icon: Icons.alt_route_outlined,
                                        title: context.l10n.welcomeFeatureBusinessRoadmap,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _buildFeatureCard(
                                        icon: Icons.assignment_outlined,
                                        title: context.l10n.welcomeFeatureApplicationSupport,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // 3. Choose Language Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.language,
                                      color: kBrandBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Flexible(
                                      child: Text(
                                        context.l10n.welcomeChooseLanguage,
                                        softWrap: true,
                                        style: GoogleFonts.inter(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: kDarkSlate,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  context.l10n.welcomeChooseLanguageSubtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: kSlate500,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _buildLanguageCard(
                                  code: 'en',
                                  title: 'English',
                                  subtitle: 'English',
                                  circleChar: 'A',
                                  circleBg: const Color(0xFFEFF6FF),
                                  circleTextColor: kBrandBlue,
                                ),
                                _buildLanguageCard(
                                  code: 'ta',
                                  title: 'தமிழ்',
                                  subtitle: 'Tamil',
                                  circleChar: 'அ',
                                  circleBg: const Color(0xFFFFF7ED),
                                  circleTextColor: const Color(0xFFEA580C),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _buildVoiceSelector(context),
                                const SizedBox(height: AppSpacing.sm),
                                _buildInfoBanner(context),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // 4. Action Button at Bottom
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.xl,
                          right: AppSpacing.xl,
                          bottom: AppSpacing.lg,
                          top: AppSpacing.md,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBrandBlue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final provider = Provider.of<AppProvider>(
                                    context,
                                    listen: false,
                                  );
                                  setState(() => _isSubmitting = true);
                                  try {
                                    await provider.changeLanguage(
                                      _selectedLang,
                                    );
                                    final updatedProfile = provider.profile
                                        .copyWith(profileCompleted: true);
                                    await provider.updateProfile(
                                      updatedProfile,
                                      requireCloudSync: true,
                                    );

                                    if (!context.mounted) return;
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MainTabsContainer(),
                                      ),
                                      (route) => false,
                                    );
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    setState(() => _isSubmitting = false);
                                    AppToast.showError(
                                      context,
                                      context.l10n.welcomeSavePreferencesError,
                                    );
                                  }
                                },
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: FitOneLine(
                                        child: Text(
                                          context.l10n.welcomeLetsBegin,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.tight),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kBrandBlue, size: 16),
          ),
          const SizedBox(height: AppSpacing.tight),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: kDarkSlate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard({
    required String code,
    required String title,
    required String subtitle,
    required String circleChar,
    required Color circleBg,
    required Color circleTextColor,
  }) {
    final isSelected = _selectedLang == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLang = code;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.tight),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kBrandBlue : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.015),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rounded character circle
            Container(
              width: adaptiveSize(context, base: 44, min: 31, max: 44),
              height: adaptiveSize(context, base: 44, min: 31, max: 44),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
              ),
              child: FitOneLine(
                child: Text(
                  circleChar,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: circleTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? kBrandBlue : kDarkSlate,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11.5, color: kSlate500),
                  ),
                ],
              ),
            ),
            // Selection indicator circle / icon
            isSelected
                ? const Icon(Icons.check_circle, color: kBrandBlue, size: 22)
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSelector(BuildContext context) {
    final voiceLabel = context.l10n.welcomeVoiceLabel;
    final naturalLabel = context.l10n.welcomeVoiceNatural;
    final clearLabel = context.l10n.welcomeVoiceClear;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_outlined,
                color: kBrandBlue,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  voiceLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: kDarkSlate,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _previewingVoice ? null : _previewVoice,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _previewingVoice
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kBrandBlue,
                                ),
                              )
                            : const Icon(
                                Icons.volume_up_rounded,
                                size: 16,
                                color: kBrandBlue,
                              ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          context.l10n.welcomePreviewVoice,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: kBrandBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildVoiceOptionChip(
                  label: naturalLabel,
                  value: 'natural',
                  isSelected: _selectedVoice == 'natural',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildVoiceOptionChip(
                  label: clearLabel,
                  value: 'clear',
                  isSelected: _selectedVoice == 'clear',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceOptionChip({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectVoice(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? kBrandBlue : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: isSelected ? kBrandBlue : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: AppSpacing.tight),
            Flexible(
              child: FitOneLine(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? kBrandBlue : kDarkSlate,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1.0),
          child: Icon(
            Icons.info_outline,
            color: kBrandBlue,
            size: 14,
          ),
        ),
        const SizedBox(width: AppSpacing.tight),
        Expanded(
          child: Text(
            context.l10n.welcomeChangeAnytimeNote,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: kSlate500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
