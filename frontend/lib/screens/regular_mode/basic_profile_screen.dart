import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../l10n/l10n.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/permission_helper.dart';
import '../../utils/app_spacing.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/data_processing_consent_modal.dart';
import '../../utils/responsive.dart';
import '../navigation_mode_screen.dart';
import '../../main.dart';

// ---------------------------------------------------------------------------
// Consolidated Profile Completion Flow
// All 4 forms in one file with a static outer container and sticky CTA button.
// ---------------------------------------------------------------------------

class BasicProfileScreen extends StatefulWidget {
  final int initialStep;
  const BasicProfileScreen({super.key, this.initialStep = 1});

  @override
  State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends State<BasicProfileScreen> {
  late int _currentStep;

  // Theme Constants
  static const Color kPrimaryBlue = Color(0xFF2563EB);
  static const Color kSlate900 = Color(0xFF0F172A);
  static const Color kSlate800 = Color(0xFF1E293B);
  static const Color kSlate500 = Color(0xFF64748B);
  static const Color kBorderGrey = Color(0xFFE2E8F0);
  static const Color kInfoBlueBg = Color(0xFFF0F5FA);

  // --- Step 1: Basic Details Controllers & State ---
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;
  late final TextEditingController _ageController;
  String _selectedGender = '';
  DateTime? _selectedDob;
  bool _hasSubmittedStep1 = false;
  bool _hasConsentedDataProcessing = false;

  // --- Step 2: Location Controllers & State ---
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _stateController;
  bool _isLoadingLocation = false;
  bool _hasSubmittedStep2 = false;

  // --- Step 3: About You State ---
  String? _selectedRole;
  bool _hasSubmittedStep3 = false;
  bool _hasSubmittedStep4 = false;

  // --- Step 4: Eligibility State ---
  late String _selectedEducation;
  late String _selectedCommunity;
  double? _selectedIncome;
  late bool _isDifferentlyAbled;
  late bool _isVeteran;
  late bool _isFirstGenGraduate;
  bool _isSubmitting = false;

  // Step 4 Options
  // Labels resolve through gen-l10n (`_optionLabel`) via the `key` field, so
  // Tamil copy lives in the ARB files, not inline here.
  final List<Map<String, String>> _educationOptions = [
    {'id': 'School', 'key': 'eduSchool'},
    {'id': 'Diploma', 'key': 'eduDiploma'},
    {'id': 'Undergraduate', 'key': 'eduUndergraduate'},
    {'id': 'Postgraduate', 'key': 'eduPostgraduate'},
    {'id': 'Ph.D.', 'key': 'eduPhd'},
  ];

  final List<Map<String, String>> _communityOptions = [
    {'id': 'General', 'key': 'commGeneralOc'},
    {'id': 'OBC', 'key': 'commObcBcMbc'},
    {'id': 'SC', 'key': 'commScCategory'},
    {'id': 'ST', 'key': 'commStCategory'},
    {'id': 'EWS', 'key': 'commEwsCategory'},
    {'id': 'Minority', 'key': 'commMinority'},
  ];

  final List<Map<String, dynamic>> _incomeOptions = [
    {'value': 0.0, 'key': 'incomeNone'},
    {'value': 100000.0, 'key': 'incomeUnder15L'},
    {'value': 250000.0, 'key': 'income15to3L'},
    {'value': 450000.0, 'key': 'income3to6L'},
    {'value': 800000.0, 'key': 'income6to10L'},
    {'value': 1500000.0, 'key': 'incomeAbove10L'},
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final profile = provider.profile;

    // 1. Initialize Step 1 controllers
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(
      text: profile.mobile.isNotEmpty ? profile.mobile : provider.mobileNumber,
    );
    if (profile.dob != null) {
      _selectedDob = profile.dob;
      _dobController = TextEditingController(text: _formatDob(_selectedDob!));
      _ageController = TextEditingController(text: profile.age.toString());
    } else {
      _dobController = TextEditingController();
      _ageController = TextEditingController();
    }
    _selectedGender = profile.profileCompleted ? profile.gender : '';

    // 2. Initialize Step 2 controllers
    _addressController = TextEditingController(
      text: profile.house.isNotEmpty ? profile.house : profile.area,
    );
    String initialCity = profile.city;
    String initialDistrict = profile.district;
    if (initialCity.isEmpty && initialDistrict.isNotEmpty) {
      if (initialDistrict.contains(',')) {
        final parts = initialDistrict.split(',');
        initialCity = parts.first.trim();
        initialDistrict = parts.sublist(1).join(',').trim();
      }
    }
    _cityController = TextEditingController(text: initialCity);
    _districtController = TextEditingController(text: initialDistrict);
    _stateController = TextEditingController(text: profile.state);

    // 3. Initialize Step 3 role
    if (profile.profileCompleted && profile.employmentStatus.isNotEmpty) {
      _selectedRole = _roleIdFromEmploymentStatus(profile.employmentStatus);
    }

    // 4. Initialize Step 4 eligibility
    if (profile.profileCompleted) {
      _selectedEducation = profile.qualification.isNotEmpty
          ? profile.qualification
          : profile.educationLevel;
      _selectedCommunity = profile.community;
      _selectedIncome = profile.annualIncome;
      _isDifferentlyAbled = profile.disability.isNotEmpty &&
          profile.disability.toLowerCase() != 'no' &&
          profile.disability.toLowerCase() != 'none';
      _isVeteran = profile.veteran;
      _isFirstGenGraduate = profile.firstGenGraduate;
    } else {
      _selectedEducation = '';
      _selectedCommunity = '';
      _selectedIncome = null;
      _isDifferentlyAbled = false;
      _isVeteran = false;
      _isFirstGenGraduate = false;
    }
  }

  @override
  void didUpdateWidget(covariant BasicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStep != widget.initialStep) {
      setState(() {
        _currentStep = widget.initialStep;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  String _formatDob(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Future<void> selectDob(BuildContext context) async {
    final DateTime? picked = await showThemedDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: context.l10n.profileHintSelectDob,
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = _formatDob(picked);
      });
    }
  }

  Future<void> _openDataProcessingConsentModal() async {
    final consented = await DataProcessingConsentModal.show(context);
    if (consented != null && mounted) {
      setState(() {
        _hasConsentedDataProcessing = consented;
      });
    }
  }

  String? _phoneErrorText() {
    if (!_hasSubmittedStep1) return null;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return context.l10n.profileErrEnterPhone;
    if (phone.length != 10) return context.l10n.profileErrPhone10Digits;
    return null;
  }

  String? _ageErrorText() {
    if (!_hasSubmittedStep1) return null;
    final ageStr = _ageController.text.trim();
    if (ageStr.isEmpty) return context.l10n.profileErrEnterAge;
    final age = int.tryParse(ageStr);
    if (age == null || age < 1 || age > 120) {
      return context.l10n.profileErrValidAge;
    }
    return null;
  }

  /// A place name must have some letters (Latin or Tamil) and a sane length --
  /// rejects junk like "1" / "11" / "." that non-empty checks let through.
  static final RegExp _placeNameLetters = RegExp(r'[A-Za-z஀-௿]');
  static bool _looksLikePlaceName(String value, {int min = 2}) {
    final t = value.trim();
    return t.length >= min && _placeNameLetters.hasMatch(t);
  }

  bool get _isStep2Valid =>
      _addressController.text.trim().isNotEmpty &&
      _looksLikePlaceName(_cityController.text, min: 2) &&
      _looksLikePlaceName(_districtController.text, min: 2) &&
      _looksLikePlaceName(_stateController.text, min: 3);

  // Step 4 (Eligibility) now requires education, community and income --
  // these drive scheme matching, so the profile is not "complete" without
  // them. Special-category toggles stay optional.
  bool get _isStep4Valid =>
      _selectedEducation.isNotEmpty &&
      _selectedCommunity.isNotEmpty &&
      _selectedIncome != null;

  static String _canonicalRoleTitle(String roleId) => switch (roleId) {
        'student' => 'Student',
        'entrepreneur' => 'Entrepreneur',
        'existing_business' => 'Business',
        'msme' => 'MSME Owner',
        'farmer' => 'Farmer',
        'artisan' => 'Artisan / SHG Member',
        _ => roleId,
      };

  static String? _roleIdFromEmploymentStatus(String status) =>
      switch (status.trim().toLowerCase()) {
        'student' => 'student',
        'aspiring entrepreneur' || 'entrepreneur' => 'entrepreneur',
        'existing business' || 'business' => 'existing_business',
        'msme owner' || 'msme' => 'msme',
        'farmer' => 'farmer',
        'artisan / shg member' || 'artisan' || 'artisan_shg' => 'artisan',
        _ => null,
      };

  List<RoleModel> _buildRoles() {
    final l10n = context.l10n;
    return [
      RoleModel(
        id: 'student',
        title: l10n.empStudent,
        subtitle: l10n.studentSubtitle,
        imagePath: 'assets/images/roles/student.webp',
        icon: Icons.school_outlined,
        color: const Color(0xFF3B82F6),
      ),
      RoleModel(
        id: 'entrepreneur',
        title: l10n.aspiringEntrepreneur,
        subtitle: l10n.aspiringEntrepreneurSubtitle,
        imagePath: 'assets/images/roles/entrepreneur.webp',
        icon: Icons.lightbulb_outline,
        color: const Color(0xFFF59E0B),
      ),
      RoleModel(
        id: 'existing_business',
        title: l10n.existingBusiness,
        subtitle: l10n.existingBusinessSubtitle,
        imagePath: 'assets/images/roles/business.webp',
        icon: Icons.business_center_outlined,
        color: const Color(0xFF6366F1),
      ),
      RoleModel(
        id: 'msme',
        title: l10n.msmeOwner,
        subtitle: l10n.msmeOwnerSubtitle,
        imagePath: 'assets/images/roles/msme.webp',
        icon: Icons.storefront_outlined,
        color: const Color(0xFF10B981),
      ),
      RoleModel(
        id: 'farmer',
        title: l10n.empFarmer,
        subtitle: l10n.farmerSubtitle,
        imagePath: 'assets/images/roles/farmer.webp',
        icon: Icons.agriculture_outlined,
        color: const Color(0xFF14B8A6),
      ),
      RoleModel(
        id: 'artisan',
        title: l10n.artisanShg,
        subtitle: l10n.artisanShgSubtitle,
        imagePath: 'assets/images/roles/artisan.webp',
        icon: Icons.palette_outlined,
        color: const Color(0xFFEC4899),
      ),
    ];
  }

  // Geocoding live fetch for Step 2
  Future<void> _fetchAndGeocodeLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        await showLocationServiceOffDialog(context);
      }
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        await showLocationServiceOffDialog(context);
      }
      return;
    }

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          final addressParts = <String>[];
          if (place.subThoroughfare != null &&
              place.subThoroughfare!.isNotEmpty) {
            addressParts.add(place.subThoroughfare!);
          }
          if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            addressParts.add(place.thoroughfare!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (addressParts.isNotEmpty) {
            _addressController.text = addressParts.join(', ');
          } else if ((place.street ?? '').isNotEmpty) {
            _addressController.text = place.street!;
          }

          _cityController.text = place.locality ?? place.subLocality ?? '';
          _districtController.text =
              place.subAdministrativeArea ?? place.locality ?? '';
          _stateController.text = place.administrativeArea ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          context.l10n.profileErrLocationFetchFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NavigationModeScreen()),
        );
      }
    }
  }



  void _handleContinue() {
    if (_currentStep == 1) {
      setState(() => _hasSubmittedStep1 = true);
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      if (name.isEmpty ||
          email.isEmpty ||
          !email.contains('@') ||
          phone.length != 10 ||
          _selectedGender.isEmpty ||
          _selectedDob == null) {
        AppToast.showError(
          context,
          context.l10n.profileErrCompleteFieldsCorrectly,
        );
        return;
      }

      if (!_hasConsentedDataProcessing) {
        AppToast.showError(
          context,
          context.l10n.profileConsentRequiredToast,
        );
        return;
      }

      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.updateProfile(
        provider.profile.copyWith(
          name: name,
          email: email,
          mobile: phone,
          gender: _selectedGender,
          dob: _selectedDob,
        ),
        requireCloudSync: false,
      );

      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      setState(() => _hasSubmittedStep2 = true);
      if (!_isStep2Valid) {
        AppToast.showError(
          context,
          context.l10n.profileErrLocationFieldsCorrectly,
        );
        return;
      }

      final address = _addressController.text.trim();
      final city = _cityController.text.trim();
      final district = _districtController.text.trim();
      final state = _stateController.text.trim();

      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.updateProfile(
        provider.profile.copyWith(
          house: address,
          area: address,
          city: city,
          district: district,
          state: state,
        ),
        requireCloudSync: false,
      );

      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      if (_selectedRole == null) {
        setState(() => _hasSubmittedStep3 = true);
        return;
      }

      final selectedRole = _selectedRole!;
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.updateProfile(
        provider.profile.copyWith(
          employmentStatus: _canonicalRoleTitle(selectedRole),
        ),
        requireCloudSync: false,
      );

      setState(() => _currentStep = 4);
    } else if (_currentStep == 4) {
      setState(() => _hasSubmittedStep4 = true);
      if (!_isStep4Valid) {
        AppToast.showError(
          context,
          context.l10n.profileErrCompleteFieldsToContinue,
        );
        return;
      }
      _completeProfile();
    }
  }

  Future<void> _completeProfile() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final updatedProfile = provider.profile.copyWith(
      qualification: _selectedEducation,
      educationLevel: _selectedEducation,
      community: _selectedCommunity,
      annualIncome: _selectedIncome ?? 0.0,
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
        context.l10n.profileErrUnableToSave,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // 1. Background Layer (Anchored to screen height so typing keyboard does not scale/zoom it)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.sizeOf(context).height,
              child: Image.asset(
                'assets/images/Background/Login_bg.webp',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // 2. Foreground Layout
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Static Header Bar outside card
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: kSlate800,
                              size: 24,
                            ),
                            tooltip: l10n.back,
                            onPressed: _handleBack,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              l10n.completeYourProfile,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kSlate900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.tight),

                      // Static White Card Container
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
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
                              // 1. Static 4-segment Stepper
                              _buildStepper(_currentStep),
                              const SizedBox(height: AppSpacing.sm),

                              // 2. Static Progress Fraction
                              Center(
                                child: _buildProgressFraction(_currentStep),
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // 3. Scrollable Form Content (Only forms scroll and change!)
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: _buildStepForm(_currentStep),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // 4. Static Continue Button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (_currentStep == 1 &&
                                              !_hasConsentedDataProcessing)
                                          ? Colors.grey.shade300
                                          : (_currentStep == 2 && !_isStep2Valid)
                                          ? Colors.grey.shade300
                                          : (_currentStep == 3 &&
                                                  _selectedRole == null)
                                              ? Colors.grey.shade300
                                              : (_currentStep == 4 &&
                                                      !_isStep4Valid)
                                                  ? Colors.grey.shade300
                                                  : kPrimaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize: const Size.fromHeight(52),
                                  elevation: 0,
                                ),
                                onPressed:
                                    _isSubmitting ? null : _handleContinue,
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
                                                _currentStep == 4
                                                    ? l10n.completeProfile
                                                    : l10n.navContinueButton,
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_currentStep < 4) ...[
                                            const SizedBox(
                                                width: AppSpacing.xs),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ],
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
      ),
    );
  }

  // --- Static Stepper & Progress Fraction ---

  Widget _buildStepper(int step) {
    return Row(
      children: [
        Expanded(child: _buildProgressSegment(step >= 1)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _buildProgressSegment(step >= 2)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _buildProgressSegment(step >= 3)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _buildProgressSegment(step >= 4)),
      ],
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

  Widget _buildProgressFraction(int step) {
    final l10n = context.l10n;
    final text = switch (step) {
      1 => l10n.step1Of4,
      2 => l10n.step2Of4,
      3 => l10n.step3Of4,
      4 => l10n.step4Of4,
      _ => l10n.step1Of4,
    };
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kPrimaryBlue,
      ),
    );
  }

  // --- Step Forms ---

  Widget _buildStepForm(int step) {
    switch (step) {
      case 1:
        return _buildStep1Form();
      case 2:
        return _buildStep2Form();
      case 3:
        return _buildStep3Form();
      case 4:
        return _buildStep4Form();
      default:
        return _buildStep1Form();
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1 FORM: Basic Details
  // ---------------------------------------------------------------------------
  Widget _buildStep1Form() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.basicDetailsSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: kSlate500,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Full Name
        CustomInputField(
          label: '${l10n.labelFullName} *',
          controller: _nameController,
          leadingIcon: Icons.person_outline,
          trailingIcon: Icons.edit_outlined,
          errorText: _hasSubmittedStep1 && _nameController.text.trim().isEmpty
              ? l10n.profileErrEnterFullName
              : null,
          onChanged: (_) {
            if (_hasSubmittedStep1) setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Email Address
        CustomInputField(
          label: '${l10n.emailAddress} *',
          controller: _emailController,
          leadingIcon: Icons.mail_outline,
          trailingIcon: Icons.edit_outlined,
          keyboardType: TextInputType.emailAddress,
          errorText: _hasSubmittedStep1 &&
                  (_emailController.text.trim().isEmpty ||
                      !_emailController.text.contains('@'))
              ? l10n.profileErrValidEmail
              : null,
          onChanged: (_) {
            if (_hasSubmittedStep1) setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Phone Number (+91 prefix)
        CustomInputField(
          label: '${l10n.phoneNumber} *',
          controller: _phoneController,
          leadingIcon: Icons.phone_outlined,
          trailingIcon: Icons.edit_outlined,
          keyboardType: TextInputType.phone,
          hintText: l10n.profileHint10DigitMobile,
          prefixText: '+91 ',
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          errorText: _phoneErrorText(),
          onChanged: (_) {
            if (_hasSubmittedStep1) setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Gender Selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: l10n.labelGender,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kSlate900,
                ),
                children: const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(child: _buildGenderBox(l10n.genderMale, Icons.male)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _buildGenderBox(l10n.genderFemale, Icons.female)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildGenderBox(l10n.genderOther, Icons.transgender),
                ),
              ],
            ),
            if (_hasSubmittedStep1 && _selectedGender.isEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 13,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.profileErrSelectGender,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Date of Birth
        CustomInputField(
          label: '${l10n.labelAge} *',
          controller: _ageController,
          leadingIcon: Icons.cake_outlined,
          trailingIcon: Icons.edit_outlined,
          keyboardType: TextInputType.number,
          hintText: 'e.g. 25',
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          errorText: _ageErrorText(),
          onChanged: (val) {
            final age = int.tryParse(val.trim());
            if (age != null && age > 0 && age <= 120) {
              final now = DateTime.now();
              _selectedDob = DateTime(now.year - age, now.month, now.day);
            } else {
              _selectedDob = null;
            }
            if (_hasSubmittedStep1) setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Info Box
        _buildInfoBox(),
        const SizedBox(height: AppSpacing.xxl),

        // Data-processing consent (DPDPA) — Step 1 is gated on this
        _buildConsentSection(),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildConsentSection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileConsentSectionTitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kSlate900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _hasConsentedDataProcessing,
                activeColor: kPrimaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: (_hasSubmittedStep1 && !_hasConsentedDataProcessing)
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF94A3B8),
                  width: 1.5,
                ),
                onChanged: (val) {
                  setState(() {
                    _hasConsentedDataProcessing = val ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _hasConsentedDataProcessing = !_hasConsentedDataProcessing;
                  });
                },
                child: Text(
                  l10n.profileConsentCheckboxLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: kSlate800,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxxl),
          child: InkWell(
            onTap: _openDataProcessingConsentModal,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                l10n.profileConsentReadMore,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryBlue,
                  decoration: TextDecoration.underline,
                  decorationColor: kPrimaryBlue.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        if (_hasSubmittedStep1 && !_hasConsentedDataProcessing) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxxl),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.profileConsentPleaseConsent,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderBox(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    final activeBg = const Color(0xFFF0F5FF);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = isSelected ? '' : gender;
        });
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimaryBlue : kBorderGrey,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? kPrimaryBlue : kSlate500,
              size: 13,
            ),
            const SizedBox(width: AppSpacing.hairline),
            Flexible(
              child: Text(
                gender,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? kPrimaryBlue : kSlate800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: kInfoBlueBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0E1FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: kPrimaryBlue,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.profileInfoNote,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: kSlate800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2 FORM: Location
  // ---------------------------------------------------------------------------
  Widget _buildStep2Form() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.whereLocated,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kSlate900,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Live Location Button
        InkWell(
          onTap: _isLoadingLocation ? null : _fetchAndGeocodeLocation,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCE7F5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: kPrimaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoadingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.useCurrentLocation,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kSlate900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: kPrimaryBlue,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // OR Divider
        Row(
          children: [
            const Expanded(
              child: Divider(
                color: Color(0xFFE2E8F0),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.or,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kSlate500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Expanded(
              child: Divider(
                color: Color(0xFFE2E8F0),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Full Address Multi-line Text Area
        _buildLabel('${l10n.fullAddress} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _addressController,
          hintText: 'e.g. Door/Flat No, Street Name, Locality',
          icon: Icons.home_outlined,
          errorText: _hasSubmittedStep2 &&
                  _addressController.text.trim().isEmpty
              ? l10n.profileErrEnterHouseStreet
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),

        // City / Town Field
        _buildLabel('${l10n.cityTown} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _cityController,
          hintText: 'e.g. Chennai',
          icon: Icons.location_city_outlined,
          errorText: _hasSubmittedStep2 &&
                  !_looksLikePlaceName(_cityController.text, min: 2)
              ? l10n.profileErrValidCity
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),

        // District Field
        _buildLabel('${l10n.district} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _districtController,
          hintText: 'e.g. Chennai',
          icon: Icons.domain_outlined,
          errorText: _hasSubmittedStep2 &&
                  !_looksLikePlaceName(_districtController.text, min: 2)
              ? l10n.profileErrValidCity
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),

        // State Field
        _buildLabel('${l10n.state} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _stateController,
          hintText: l10n.profileHintStateExample,
          icon: Icons.map_outlined,
          errorText:
              _hasSubmittedStep2 &&
                      !_looksLikePlaceName(_stateController.text, min: 3)
                  ? l10n.profileErrValidState
                  : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildLabel(String text) {
    final hasAsterisk = text.contains('*');
    final baseText = text.replaceAll('*', '').trim();
    return Text.rich(
      TextSpan(
        text: baseText,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: kSlate800,
        ),
        children: hasAsterisk
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: kSlate900,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF94A3B8),
        ),
        prefixIcon: Icon(icon, color: kSlate500, size: 20),
        errorText: errorText,
        errorStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFDC2626),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3 FORM: About You (Roles)
  // ---------------------------------------------------------------------------
  Widget _buildStep3Form() {
    final l10n = context.l10n;
    final roles = _buildRoles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.tellUsAboutYou,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kSlate900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.aboutYouSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: kSlate500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Grid of role cards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: roles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio:
                MediaQuery.sizeOf(context).width < 360 ? 1.05 : 1.22,
          ),
          itemBuilder: (context, index) {
            final role = roles[index];
            final isSelected = _selectedRole == role.id;
            return _buildRoleCard(role, isSelected);
          },
        ),
        if (_hasSubmittedStep3 && _selectedRole == null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFECACA),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.profileErrSelectOptionToContinue,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildRoleCard(RoleModel role, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = isSelected ? null : role.id;
          _hasSubmittedStep3 = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPrimaryBlue : kBorderGrey,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryBlue.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Micro Radio Button indicator
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? kPrimaryBlue : Colors.white,
                  border: Border.all(
                    color: isSelected ? kPrimaryBlue : kBorderGrey,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 10)
                    : null,
              ),
            ),

            // Perfectly centered content with equal spacing and padding
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: role.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(role.icon, color: role.color, size: 19),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  SizedBox(
                    height: 32,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        role.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kSlate900,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Maps a Step 4 option `key` to its localized label. Kept as an explicit
  // switch because gen-l10n getters can't be looked up dynamically by name.
  String _optionLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'eduSchool':
        return l10n.eduSchool;
      case 'eduDiploma':
        return l10n.eduDiploma;
      case 'eduUndergraduate':
        return l10n.eduUndergraduate;
      case 'eduPostgraduate':
        return l10n.eduPostgraduate;
      case 'eduPhd':
        return l10n.eduPhd;
      case 'commGeneralOc':
        return l10n.commGeneralOc;
      case 'commObcBcMbc':
        return l10n.commObcBcMbc;
      case 'commScCategory':
        return l10n.commScCategory;
      case 'commStCategory':
        return l10n.commStCategory;
      case 'commEwsCategory':
        return l10n.commEwsCategory;
      case 'commMinority':
        return l10n.commMinority;
      case 'incomeNone':
        return l10n.incomeNone;
      case 'incomeUnder15L':
        return l10n.incomeUnder15L;
      case 'income15to3L':
        return l10n.income15to3L;
      case 'income3to6L':
        return l10n.income3to6L;
      case 'income6to10L':
        return l10n.income6to10L;
      case 'incomeAbove10L':
        return l10n.incomeAbove10L;
      default:
        return key;
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 4 FORM: Eligibility
  // ---------------------------------------------------------------------------
  Widget _buildStep4Form() {
    final l10n = context.l10n;

    // Two-column grid of selectable cards -- same visual language as the
    // Step 3 role grid, so Step 4 reads as a sibling of the other steps
    // instead of a loose chip cloud.
    Widget optionGrid({
      required List<Map<String, dynamic>> options,
      required bool Function(Map<String, dynamic> opt) isSelected,
      required void Function(Map<String, dynamic> opt) onSelect,
    }) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          mainAxisExtent: 52,
        ),
        itemBuilder: (context, index) {
          final opt = options[index];
          final text = _optionLabel(l10n, opt['key'] as String);
          return _buildSelectCard(
            label: text,
            isSelected: isSelected(opt),
            onTap: () => setState(() {
              onSelect(opt);
              _hasSubmittedStep4 = false;
            }),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.checkEligibility,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kSlate900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.eligibilitySubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: kSlate500,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 1. Education level (required)
        _buildLabel('${l10n.qualification} *'),
        const SizedBox(height: AppSpacing.sm),
        optionGrid(
          options: _educationOptions,
          isSelected: (opt) =>
              _selectedEducation.isNotEmpty &&
              _selectedEducation.toLowerCase() ==
                  (opt['id'] as String).toLowerCase(),
          onSelect: (opt) {
            final id = opt['id'] as String;
            _selectedEducation =
                _selectedEducation.toLowerCase() == id.toLowerCase() ? '' : id;
          },
        ),
        if (_hasSubmittedStep4 && _selectedEducation.isEmpty)
          _buildFieldError(l10n.profileErrSelectEducation),
        const SizedBox(height: AppSpacing.lg),

        // 2. Community category (required)
        _buildLabel('${l10n.community} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildPrivacyNote(),
        const SizedBox(height: AppSpacing.sm),
        optionGrid(
          options: _communityOptions,
          isSelected: (opt) =>
              _selectedCommunity.isNotEmpty &&
              _selectedCommunity.toLowerCase() ==
                  (opt['id'] as String).toLowerCase(),
          onSelect: (opt) {
            final id = opt['id'] as String;
            _selectedCommunity =
                _selectedCommunity.toLowerCase() == id.toLowerCase() ? '' : id;
          },
        ),
        if (_hasSubmittedStep4 && _selectedCommunity.isEmpty)
          _buildFieldError(l10n.profileErrSelectCommunity),
        const SizedBox(height: AppSpacing.lg),

        // 3. Annual household income (required)
        _buildLabel('${l10n.income} *'),
        const SizedBox(height: AppSpacing.sm),
        optionGrid(
          options: _incomeOptions,
          isSelected: (opt) =>
              _selectedIncome != null &&
              (_selectedIncome! - (opt['value'] as double)).abs() < 1000,
          onSelect: (opt) {
            final val = opt['value'] as double;
            _selectedIncome = (_selectedIncome != null &&
                    (_selectedIncome! - val).abs() < 1000)
                ? null
                : val;
          },
        ),
        if (_hasSubmittedStep4 && _selectedIncome == null)
          _buildFieldError(l10n.profileErrSelectIncome),
        const SizedBox(height: AppSpacing.lg),

        // 4. Special categories (optional)
        _buildLabel(l10n.specialCategories),
        const SizedBox(height: AppSpacing.sm),
        _buildToggleCard(
          title: l10n.firstGenGraduate,
          value: _isFirstGenGraduate,
          onChanged: (val) => setState(() => _isFirstGenGraduate = val),
        ),
        const SizedBox(height: AppSpacing.tight),
        _buildToggleCard(
          title: l10n.disability,
          value: _isDifferentlyAbled,
          onChanged: (val) => setState(() => _isDifferentlyAbled = val),
        ),
        const SizedBox(height: AppSpacing.tight),
        _buildToggleCard(
          title: l10n.veteran,
          value: _isVeteran,
          onChanged: (val) => setState(() => _isVeteran = val),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  // Slim privacy reassurance, styled like the Step 1 info box.
  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: kInfoBlueBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0E1FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            size: 14,
            color: kPrimaryBlue,
          ),
          const SizedBox(width: AppSpacing.tight),
          Expanded(
            child: Text(
              context.l10n.profilePrivacyNoteDpdpa,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: kSlate800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Inline validation pill -- identical to the Step 3 error style.
  Widget _buildFieldError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 16,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Selectable option card -- mirrors _buildRoleCard (Step 3).
  Widget _buildSelectCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPrimaryBlue : kBorderGrey,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryBlue.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? kPrimaryBlue : kSlate800,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? kPrimaryBlue : Colors.white,
                border: Border.all(
                  color: isSelected ? kPrimaryBlue : kBorderGrey,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 10)
                  : null,
            ),
          ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? kPrimaryBlue : kBorderGrey,
          width: 1.0,
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
                fontWeight: FontWeight.w500,
                color: kSlate800,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: kPrimaryBlue,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Custom Input Field Widget
// ---------------------------------------------------------------------------
class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData leadingIcon;
  final IconData trailingIcon;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? prefixText;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final void Function(String)? onChanged;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.leadingIcon,
    required this.trailingIcon,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.prefixText,
    this.hintText,
    this.inputFormatters,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: AppConstants.primaryText,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppConstants.surfaceColor,
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: AppConstants.secondaryText,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                prefixIcon: prefixText == null
                    ? Icon(
                        leadingIcon,
                        color: hasError
                            ? AppConstants.errorColor
                            : AppConstants.secondaryText,
                        size: 20,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: AppSpacing.lg),
                          Icon(
                            leadingIcon,
                            color: hasError
                                ? AppConstants.errorColor
                                : AppConstants.secondaryText,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            prefixText!,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryText,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.tight),
                        ],
                      ),
                prefixIconConstraints: prefixText == null
                    ? null
                    : const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: Icon(
                  trailingIcon,
                  color: hasError
                      ? AppConstants.errorColor
                      : AppConstants.secondaryText,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? AppConstants.errorColor
                        : AppConstants.cardBorderColor,
                    width: hasError ? 1.4 : 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? AppConstants.errorColor
                        : AppConstants.cardBorderColor,
                    width: hasError ? 1.4 : 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? AppConstants.errorColor
                        : AppConstants.primaryColor,
                    width: 1.8,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 13,
                color: AppConstants.errorColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  errorText!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Role Data Model
// ---------------------------------------------------------------------------

class RoleModel {
  final String id;
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final Color color;

  RoleModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.color,
  });
}
