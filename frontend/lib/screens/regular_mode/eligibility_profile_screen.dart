import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/profile_l10n.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_toast.dart';
import '../../main.dart';
import '../../utils/app_spacing.dart';

class EligibilityProfileScreen extends StatefulWidget {
  const EligibilityProfileScreen({super.key});

  @override
  State<EligibilityProfileScreen> createState() =>
      _EligibilityProfileScreenState();
}

class _EligibilityProfileScreenState extends State<EligibilityProfileScreen> {
  late String _selectedEducation;
  late String _selectedCommunity;
  late double _selectedIncome;
  late bool _isDifferentlyAbled;
  late bool _isVeteran;
  late bool _isFirstGenGraduate;

  bool _isSubmitting = false;

  // Theme Constants
  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate800 = Color(0xFF1E293B);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);

  final List<Map<String, String>> _educationOptions = [
    {'id': 'School', 'label': 'School (10th / 12th)', 'labelTa': 'பள்ளி (10 / 12ம்)'},
    {'id': 'Diploma', 'label': 'Diploma / ITI', 'labelTa': 'டிப்ளமோ / ITI'},
    {'id': 'Undergraduate', 'label': 'Undergraduate (Degree)', 'labelTa': 'இளங்கலை (பட்டப்படிப்பு)'},
    {'id': 'Postgraduate', 'label': 'Postgraduate (Master)', 'labelTa': 'முதுகலை (மாஸ்டர்)'},
    {'id': 'Ph.D.', 'label': 'Ph.D. / Doctorate', 'labelTa': 'முனைவர் பட்டம் (Ph.D.)'},
  ];

  final List<Map<String, String>> _communityOptions = [
    {'id': 'General', 'label': 'General (OC)', 'labelTa': 'பொதுப் பிரிவு (OC)'},
    {'id': 'OBC', 'label': 'OBC / BC / MBC', 'labelTa': 'OBC / BC / MBC'},
    {'id': 'SC', 'label': 'SC', 'labelTa': 'பட்டியலினம் (SC)'},
    {'id': 'ST', 'label': 'ST', 'labelTa': 'பழங்குடியினர் (ST)'},
    {'id': 'EWS', 'label': 'EWS', 'labelTa': 'பொருளாதார நலிந்தோர் (EWS)'},
    {'id': 'Minority', 'label': 'Minority', 'labelTa': 'சிறுபான்மையினர்'},
  ];

  final List<Map<String, dynamic>> _incomeOptions = [
    {'value': 100000.0, 'label': 'Under ₹1.5 Lakhs', 'labelTa': '₹1.5 லட்சத்திற்கு கீழ்'},
    {'value': 250000.0, 'label': '₹1.5L - ₹3 Lakhs', 'labelTa': '₹1.5L - ₹3 லட்சம்'},
    {'value': 450000.0, 'label': '₹3L - ₹6 Lakhs', 'labelTa': '₹3L - ₹6 லட்சம்'},
    {'value': 800000.0, 'label': '₹6L - ₹10 Lakhs', 'labelTa': '₹6L - ₹10 லட்சம்'},
    {'value': 1500000.0, 'label': 'Above ₹10 Lakhs', 'labelTa': '₹10 லட்சத்திற்கு மேல்'},
  ];

  @override
  void initState() {
    super.initState();
    final profile =
        Provider.of<AppProvider>(context, listen: false).profile;
    _selectedEducation = profile.qualification.isNotEmpty
        ? profile.qualification
        : (profile.educationLevel.isNotEmpty
            ? profile.educationLevel
            : 'Undergraduate');
    _selectedCommunity =
        profile.community.isNotEmpty ? profile.community : 'General';
    _selectedIncome = profile.annualIncome > 0 ? profile.annualIncome : 100000.0;
    _isDifferentlyAbled = profile.disability.isNotEmpty &&
        profile.disability.toLowerCase() != 'no';
    _isVeteran = profile.veteran;
    _isFirstGenGraduate = profile.firstGenGraduate;
  }

  Future<void> _completeProfile({bool isSkip = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final currentProfile = provider.profile;

    final updatedProfile = isSkip
        ? currentProfile.copyWith(profileCompleted: true)
        : currentProfile.copyWith(
            qualification: _selectedEducation,
            educationLevel: _selectedEducation,
            community: _selectedCommunity,
            annualIncome: _selectedIncome,
            disability: _isDifferentlyAbled ? 'Yes' : 'No',
            veteran: _isVeteran,
            firstGenGraduate: _isFirstGenGraduate,
            profileCompleted: true,
          );

    try {
      await provider.updateProfile(updatedProfile, requireCloudSync: true);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainTabsContainer()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(
        context,
        'Unable to save profile. Please check connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTa = context.select<AppProvider, bool>(
      (provider) => provider.selectedLanguage == 'ta',
    );
    String l(String key) => ProfileL10n.t(key, isTa);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background/Login_bg.webp',
              fit: BoxFit.cover,
            ),
          ),

          // Foreground Content
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: kSlate800,
                            size: 24,
                          ),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        FlexText(
                          child: Text(
                            l('complete_your_profile'),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kSlate900,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _completeProfile(isSkip: true),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l('skip'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Main Card Container
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: kBorderGrey),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Scrollable Area
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Progress Stepper (4 of 4)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildProgressSegment(true),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: _buildProgressSegment(true),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: _buildProgressSegment(true),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: _buildProgressSegment(true),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Center(
                                      child: Text(
                                        l('step_4_of_4'),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kPrimaryBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),

                                    // Header Title & Subtitle
                                    Text(
                                      l('eligibility_details'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: kSlate900,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      l('eligibility_subtitle'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: kSlate500,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),

                                    // 1. Education Level
                                    _buildSectionLabel(
                                      l('qualification'),
                                      Icons.school_outlined,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: _educationOptions.map((opt) {
                                        final isSelected =
                                            _selectedEducation.toLowerCase() ==
                                                opt['id']!.toLowerCase();
                                        final text = isTa
                                            ? opt['labelTa']!
                                            : opt['label']!;
                                        return _buildChoiceChip(
                                          label: text,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setState(() {
                                              _selectedEducation = opt['id']!;
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),

                                    // 2. Community Category
                                    _buildSectionLabel(
                                      l('community'),
                                      Icons.people_outline,
                                    ),
                                    const SizedBox(height: AppSpacing.tight),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.tight,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.privacy_tip_outlined,
                                            size: 14,
                                            color: Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: AppSpacing.tight),
                                          Expanded(
                                            child: Text(
                                              isTa
                                                  ? 'DPDPA 2023: சமூகப் பிரிவு தகவல் அரசு நலத்திட்ட தகுதி சரிபார்ப்பிற்கு மட்டுமே பாதுகாப்பாக பயன்படுத்தப்படும்.'
                                                  : 'DPDPA 2023: Demographic data is processed exclusively for welfare scheme matching and is never shared.',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: const Color(0xFF475569),
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: _communityOptions.map((opt) {
                                        final isSelected =
                                            _selectedCommunity.toLowerCase() ==
                                                opt['id']!.toLowerCase();
                                        final text = isTa
                                            ? opt['labelTa']!
                                            : opt['label']!;
                                        return _buildChoiceChip(
                                          label: text,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setState(() {
                                              _selectedCommunity = opt['id']!;
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),

                                    // 3. Annual Income Range
                                    _buildSectionLabel(
                                      l('income'),
                                      Icons.currency_rupee,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: _incomeOptions.map((opt) {
                                        final val = opt['value'] as double;
                                        final isSelected =
                                            (_selectedIncome - val).abs() < 1000;
                                        final text = isTa
                                            ? opt['labelTa'] as String
                                            : opt['label'] as String;
                                        return _buildChoiceChip(
                                          label: text,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setState(() {
                                              _selectedIncome = val;
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),

                                    // 4. Special Categories / Priority
                                    _buildSectionLabel(
                                      l('special_categories'),
                                      Icons.verified_user_outlined,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),

                                    _buildToggleCard(
                                      title: l('first_gen_graduate'),
                                      value: _isFirstGenGraduate,
                                      onChanged: (val) {
                                        setState(() {
                                          _isFirstGenGraduate = val;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.tight),

                                    _buildToggleCard(
                                      title: l('disability'),
                                      value: _isDifferentlyAbled,
                                      onChanged: (val) {
                                        setState(() {
                                          _isDifferentlyAbled = val;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.tight),

                                    _buildToggleCard(
                                      title: l('veteran'),
                                      value: _isVeteran,
                                      onChanged: (val) {
                                        setState(() {
                                          _isVeteran = val;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // Sticky Action Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size.fromHeight(50),
                                elevation: 0,
                              ),
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _completeProfile(isSkip: false),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: FitOneLine(
                                            child: Text(
                                              l('complete_profile'),
                                              style: GoogleFonts.inter(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kPrimaryBlue),
        const SizedBox(width: AppSpacing.tight),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: kSlate800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        // Never let a single chip exceed the card's content width, so a long
        // label ellipsizes instead of overflowing the Wrap line.
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 72,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? kPrimaryBlue : kBorderGrey,
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kPrimaryBlue.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_circle, size: 14, color: kPrimaryBlue),
                const SizedBox(width: AppSpacing.tight),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isSelected
                        ? kPrimaryBlue
                        : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? kPrimaryBlue.withValues(alpha: 0.5) : kBorderGrey,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                color: value ? kSlate900 : const Color(0xFF475569),
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: kPrimaryBlue,
            activeTrackColor: kPrimaryBlue.withValues(alpha: 0.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSegment(bool isCompleted) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isCompleted ? kPrimaryBlue : kBorderGrey,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
