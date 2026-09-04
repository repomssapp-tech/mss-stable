import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../utils/profile_l10n.dart';
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
    final doorStreetParts = <String>[
      if (profile.house.trim().isNotEmpty) profile.house.trim(),
      if (profile.street.trim().isNotEmpty &&
          profile.street.trim() != profile.house.trim())
        profile.street.trim(),
    ];
    _doorStreetController =
        TextEditingController(text: doorStreetParts.join(', '));
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
      helpText: 'SELECT DATE OF BIRTH',
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
    if (phone.isEmpty) return 'Please enter your phone number';
    if (phone.length != 10) return 'Enter a 10-digit mobile number';
    return null;
  }

  String? _pincodeErrorText() {
    if (!_hasSubmittedStep2) return null;
    final pin = _pincodeController.text.trim();
    if (pin.isEmpty) return 'Required';
    if (pin.length != 6) return 'Enter 6 digits';
    return null;
  }

  bool get _isStep2Valid =>
      _doorStreetController.text.trim().isNotEmpty &&
      _areaLocalityController.text.trim().isNotEmpty &&
      _cityDistrictController.text.trim().isNotEmpty &&
      _stateController.text.trim().isNotEmpty &&
      _pincodeController.text.trim().length == 6;

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

  List<RoleModel> _buildRoles(String Function(String) l) => [
        RoleModel(
          id: 'student',
          title: l('student'),
          subtitle: l('student_subtitle'),
          imagePath: 'assets/images/roles/student.webp',
          icon: Icons.school_outlined,
          color: const Color(0xFF3B82F6),
        ),
        RoleModel(
          id: 'entrepreneur',
          title: l('aspiring_entrepreneur'),
          subtitle: l('aspiring_entrepreneur_subtitle'),
          imagePath: 'assets/images/roles/entrepreneur.webp',
          icon: Icons.lightbulb_outline,
          color: const Color(0xFFF59E0B),
        ),
        RoleModel(
          id: 'existing_business',
          title: l('existing_business'),
          subtitle: l('existing_business_subtitle'),
          imagePath: 'assets/images/roles/business.webp',
          icon: Icons.business_center_outlined,
          color: const Color(0xFF6366F1),
        ),
        RoleModel(
          id: 'msme',
          title: l('msme_owner'),
          subtitle: l('msme_owner_subtitle'),
          imagePath: 'assets/images/roles/msme.webp',
          icon: Icons.storefront_outlined,
          color: const Color(0xFF10B981),
        ),
        RoleModel(
          id: 'farmer',
          title: l('farmer'),
          subtitle: l('farmer_subtitle'),
          imagePath: 'assets/images/roles/farmer.webp',
          icon: Icons.agriculture_outlined,
          color: const Color(0xFF14B8A6),
        ),
        RoleModel(
          id: 'artisan',
          title: l('artisan_shg'),
          subtitle: l('artisan_shg_subtitle'),
          imagePath: 'assets/images/roles/artisan.webp',
          icon: Icons.palette_outlined,
          color: const Color(0xFFEC4899),
        ),
      ];

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
          'Could not fetch location. Please enter manually.',
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
          'Please complete all required fields correctly.',
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
          'Please fill in all required location fields correctly.',
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
          street: doorStreet,
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
      _completeProfile(isSkip: false);
    }
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
        'Unable to save profile. Please check connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTa =
        Provider.of<AppProvider>(context).selectedLanguage == 'ta';
    String l(String key) => ProfileL10n.t(key, isTa);

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
                            onPressed: _handleBack,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              l('complete_your_profile'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kSlate900,
                              ),
                            ),
                          ),
                          if (_currentStep == 4) ...[
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
                                child: _buildProgressFraction(_currentStep, isTa),
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // 3. Scrollable Form Content (Only forms scroll and change!)
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
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
                                                    ? l('complete_profile')
                                                    : l('continue'),
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

  Widget _buildProgressFraction(int step, bool isTa) {
    final key = switch (step) {
      1 => 'step_1_of_4',
      2 => 'step_2_of_4',
      3 => 'step_3_of_4',
      4 => 'step_4_of_4',
      _ => 'step_1_of_4',
    };
    return Text(
      ProfileL10n.t(key, isTa),
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
        return _buildStep1Form(isTa);
      case 2:
        return _buildStep2Form(isTa);
      case 3:
        return _buildStep3Form(isTa);
      case 4:
        return _buildStep4Form(isTa);
      default:
        return _buildStep1Form(isTa);
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1 FORM: Basic Details
  // ---------------------------------------------------------------------------
  Widget _buildStep1Form(bool isTa) {
    String l(String key) => ProfileL10n.t(key, isTa);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Let's start with your basic details.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: kSlate500,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Full Name
        CustomInputField(
          label: '${l('full_name')} *',
          controller: _nameController,
          leadingIcon: Icons.person_outline,
          trailingIcon: Icons.edit_outlined,
          errorText: _hasSubmittedStep1 && _nameController.text.trim().isEmpty
              ? 'Please enter your full name'
              : null,
          onChanged: (_) {
            if (_hasSubmittedStep1) setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Email Address
        CustomInputField(
          label: '${l('email_address')} *',
          controller: _emailController,
          leadingIcon: Icons.mail_outline,
          trailingIcon: Icons.edit_outlined,
          keyboardType: TextInputType.emailAddress,
          errorText: _hasSubmittedStep1 &&
                  (_emailController.text.trim().isEmpty ||
                      !_emailController.text.contains('@'))
              ? 'Please enter a valid email address'
              : null,
          onChanged: (_) {
            if (_hasSubmittedStep1) setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Phone Number (+91 prefix)
        CustomInputField(
          label: '${l('phone_number')} *',
          controller: _phoneController,
          leadingIcon: Icons.phone_outlined,
          trailingIcon: Icons.edit_outlined,
          keyboardType: TextInputType.phone,
          hintText: '10-digit mobile number',
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
                text: l('gender'),
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
                Expanded(child: _buildGenderBox(l('male'), Icons.male)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _buildGenderBox(l('female'), Icons.female)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildGenderBox(l('other'), Icons.transgender),
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
                      'Please select your gender',
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
          label: '${l('date_of_birth')} *',
          controller: _dobController,
          leadingIcon: Icons.calendar_today_outlined,
          trailingIcon: Icons.arrow_drop_down,
          readOnly: true,
          hintText: 'DD/MM/YYYY',
          onTap: () => _selectDob(context),
          errorText: _hasSubmittedStep1 && _selectedDob == null
              ? 'Please select your date of birth'
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
              'Your details are safe with us. We use this information to personalize your scheme recommendations.',
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
  Widget _buildStep2Form(bool isTa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Where Are You Located?',
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
                    'Use Current Location',
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
                'OR',
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
        _buildLabel('Door No / Flat / House No / Street *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _doorStreetController,
          hintText: 'e.g. Flat 402, Royal Enclave',
          icon: Icons.home_outlined,
          errorText: _hasSubmittedStep2 &&
                  _doorStreetController.text.trim().isEmpty
              ? 'Please enter your house/street address'
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Area / Locality Field
        _buildLabel('Area / Locality *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _areaLocalityController,
          hintText: 'e.g. Anna Nagar West',
          icon: Icons.location_on_outlined,
          errorText: _hasSubmittedStep2 &&
                  _areaLocalityController.text.trim().isEmpty
              ? 'Please enter your area or locality'
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),

        // City / District Field
        _buildLabel('City / District *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _cityDistrictController,
          hintText: 'e.g. Chennai',
          icon: Icons.location_city_outlined,
          errorText: _hasSubmittedStep2 &&
                  _cityDistrictController.text.trim().isEmpty
              ? 'Please enter your city or district'
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),

        // State Field
        _buildLabel('State *'),
        const SizedBox(height: AppSpacing.tight),
        _buildTextField(
          controller: _stateController,
          hintText: 'e.g. Tamil Nadu',
          icon: Icons.map_outlined,
          errorText:
              _hasSubmittedStep2 && _stateController.text.trim().isEmpty
                  ? 'Please enter state'
                  : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Pincode Field (below State)
        _buildLabel('Pincode *'),
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
  Widget _buildStep3Form(bool isTa) {
    String l(String key) => ProfileL10n.t(key, isTa);
    final roles = _buildRoles(l);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l('tell_us_about_you'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kSlate900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l('about_you_subtitle'),
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
                    'Please select an option to continue.',
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
    String l(String key) => ProfileL10n.t(key, isTa);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          l('check_eligibility'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
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
            final isSelected = _selectedEducation.isNotEmpty &&
                _selectedEducation.toLowerCase() == opt['id']!.toLowerCase();
            final text = isTa ? opt['labelTa']! : opt['label']!;
            return _buildChoiceChip(
              label: text,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedEducation = isSelected ? '' : opt['id']!;
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
            final isSelected = _selectedCommunity.isNotEmpty &&
                _selectedCommunity.toLowerCase() == opt['id']!.toLowerCase();
            final text = isTa ? opt['labelTa']! : opt['label']!;
            return _buildChoiceChip(
              label: text,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedCommunity = isSelected ? '' : opt['id']!;
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
            final isSelected = _selectedIncome != null &&
                (_selectedIncome! - val).abs() < 1000;
            final text = isTa
                ? opt['labelTa'] as String
                : opt['label'] as String;
            return _buildChoiceChip(
              label: text,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedIncome = isSelected ? null : val;
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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 72,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
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
