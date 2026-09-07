import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../l10n/l10n.dart';
import '../../utils/permission_helper.dart';
import '../../utils/app_spacing.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_toast.dart';
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
  String _selectedGender = '';
  DateTime? _selectedDob;
  bool _hasSubmittedStep1 = false;

  // --- Step 2: Location Controllers & State ---
  late final TextEditingController _doorStreetController;
  late final TextEditingController _areaLocalityController;
  late final TextEditingController _cityDistrictController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
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
    {'value': 0.0, 'label': 'No Income', 'labelTa': 'வருமானம் இல்லை'},
    {'value': 100000.0, 'label': 'Under ₹1.5 Lakhs', 'labelTa': '₹1.5 லட்சத்திற்கு கீழ்'},
    {'value': 250000.0, 'label': '₹1.5L - ₹3 Lakhs', 'labelTa': '₹1.5L - ₹3 லட்சம்'},
    {'value': 450000.0, 'label': '₹3L - ₹6 Lakhs', 'labelTa': '₹3L - ₹6 லட்சம்'},
    {'value': 800000.0, 'label': '₹6L - ₹10 Lakhs', 'labelTa': '₹6L - ₹10 லட்சம்'},
    {'value': 1500000.0, 'label': 'Above ₹10 Lakhs', 'labelTa': '₹10 லட்சத்திற்கு மேல்'},
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
    } else {
      _dobController = TextEditingController();
    }
    _selectedGender = profile.profileCompleted ? profile.gender : '';

    // 2. Initialize Step 2 controllers
    _doorStreetController = TextEditingController(text: profile.house.trim());
    _areaLocalityController = TextEditingController(text: profile.area);
    String cityDistrict = profile.district;
    if (profile.city.isNotEmpty && profile.city != profile.district) {
      if (cityDistrict.isNotEmpty) {
        cityDistrict = '${profile.city}, $cityDistrict';
      } else {
        cityDistrict = profile.city;
      }
    }
    _cityDistrictController = TextEditingController(text: cityDistrict);
    _stateController = TextEditingController(text: profile.state);
    _pincodeController = TextEditingController(text: profile.pinCode);

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
    _doorStreetController.dispose();
    _areaLocalityController.dispose();
    _cityDistrictController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  String _formatDob(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Future<void> _selectDob(BuildContext context) async {
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

  String? _phoneErrorText() {
    if (!_hasSubmittedStep1) return null;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return context.l10n.profileErrEnterPhone;
    if (phone.length != 10) return context.l10n.profileErrPhone10Digits;
    return null;
  }

  String? _pincodeErrorText() {
    if (!_hasSubmittedStep2) return null;
    final pin = _pincodeController.text.trim();
    if (pin.isEmpty) return context.l10n.badgeRequired;
    if (pin.length != 6) return context.l10n.profileErrPincode6Digits;
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
      _doorStreetController.text.trim().isNotEmpty &&
      _areaLocalityController.text.trim().isNotEmpty &&
      _looksLikePlaceName(_cityDistrictController.text, min: 2) &&
      _looksLikePlaceName(_stateController.text, min: 3) &&
      _pincodeController.text.trim().length == 6;

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
          _areaLocalityController.text =
              place.subLocality ?? place.locality ?? '';

          String district = place.subAdministrativeArea ?? '';
          String city = place.locality ?? '';
          if (district.isEmpty) {
            district = city;
          } else if (city.isNotEmpty && city != district) {
            district = '$city, $district';
          }
          _cityDistrictController.text = district;

          _stateController.text = place.administrativeArea ?? '';
          _pincodeController.text = place.postalCode ?? '';
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

      final doorStreet = _doorStreetController.text.trim();
      final area = _areaLocalityController.text.trim();
      final cityDistrict = _cityDistrictController.text.trim();
      final state = _stateController.text.trim();
      final pincode = _pincodeController.text.trim();

      String city = cityDistrict;
      String district = cityDistrict;
      if (cityDistrict.contains(',')) {
        final parts = cityDistrict.split(',');
        city = parts.first.trim();
        district = parts.sublist(1).join(',').trim();
      }

      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.updateProfile(
        provider.profile.copyWith(
          house: doorStreet,
          area: area,
          city: city,
          district: district,
          state: state,
          pinCode: pincode,
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
    // `isTa` still feeds the inline label ternaries in Step 4 (opt['labelTa'])
    // and the DPDPA privacy note -- those are migrated in a later batch.
    final isTa =
        Provider.of<AppProvider>(context).selectedLanguage == 'ta';

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
                                  child: _buildStepForm(_currentStep, isTa),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // 4. Static Continue Button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (_currentStep == 2 && !_isStep2Valid)
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

  Widget _buildStepForm(int step, bool isTa) {
    switch (step) {
      case 1:
        return _buildStep1Form();
      case 2:
        return _buildStep2Form();
      case 3:
        return _buildStep3Form();
      case 4:
        return _buildStep4Form(isTa);
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
          label: '${l10n.dateOfBirth} *',
          controller: _dobController,
          leadingIcon: Icons.calendar_today_outlined,
          trailingIcon: Icons.arrow_drop_down,
          readOnly: true,
          hintText: l10n.profileHintDdmmyyyy,
          onTap: () => _selectDob(context),
          errorText: _hasSubmittedStep1 && _selectedDob == null
              ? l10n.profileErrSelectDob
              : null,
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Info Box
        _buildInfoBox(),
        const SizedBox(height: AppSpacing.md),
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

        // Door / House No / Street Address Field
        _buildLabel('${l10n.doorNoStreet} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _doorStreetController,
          hintText: l10n.profileHintDoorStreetExample,
          icon: Icons.home_outlined,
          errorText: _hasSubmittedStep2 &&
                  _doorStreetController.text.trim().isEmpty
              ? l10n.profileErrEnterHouseStreet
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Area / Locality Field
        _buildLabel('${l10n.areaLocality} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _areaLocalityController,
          hintText: l10n.profileHintAreaExample,
          icon: Icons.location_on_outlined,
          errorText: _hasSubmittedStep2 &&
                  _areaLocalityController.text.trim().isEmpty
              ? l10n.profileErrEnterArea
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),

        // City / District Field
        _buildLabel('${l10n.cityDistrict} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _cityDistrictController,
          hintText: l10n.profileHintCityExample,
          icon: Icons.location_city_outlined,
          errorText: _hasSubmittedStep2 &&
                  !_looksLikePlaceName(_cityDistrictController.text, min: 2)
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
        const SizedBox(height: AppSpacing.lg),

        // Pincode Field (below State)
        _buildLabel('${l10n.pincode} *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _pincodeController,
          hintText: '600040',
          icon: Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          errorText: _pincodeErrorText(),
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

  // ---------------------------------------------------------------------------
  // STEP 4 FORM: Eligibility
  // ---------------------------------------------------------------------------
  Widget _buildStep4Form(bool isTa) {
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
          final text =
              isTa ? opt['labelTa'] as String : opt['label'] as String;
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
        _buildPrivacyNote(isTa),
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
  Widget _buildPrivacyNote(bool isTa) {
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
              isTa
                  ? 'DPDPA 2023: சமூகப் பிரிவு தகவல் அரசு நலத்திட்டத் தகுதி சரிபார்ப்பிற்கு மட்டுமே பயன்படுத்தப்படும்; பகிரப்படாது.'
                  : 'DPDPA 2023: Used only to match you with welfare schemes. Never shared.',
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
