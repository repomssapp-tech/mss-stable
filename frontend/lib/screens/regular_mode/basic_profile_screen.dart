import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../l10n/l10n.dart';
import '../../utils/permission_helper.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/legal/data_processing_consent_modal.dart';
import '../../utils/responsive.dart';
import '../navigation_mode_screen.dart';
import '../../main.dart';
import 'basic_profile/step1_basic_details_form.dart';
import 'basic_profile/step2_location_form.dart';
import 'basic_profile/step3_about_you_form.dart';
import 'basic_profile/step4_eligibility_form.dart';

export 'basic_profile/custom_input_field.dart';
export 'basic_profile/role_model.dart';
export 'basic_profile/step1_basic_details_form.dart';
export 'basic_profile/step2_location_form.dart';
export 'basic_profile/step3_about_you_form.dart';
export 'basic_profile/step4_eligibility_form.dart';

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
  static const Color kBorderGrey = Color(0xFFE2E8F0);

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

  // Step 4 Options (defaults provided by Step4EligibilityForm)
  final List<Map<String, String>> _educationOptions =
      Step4EligibilityForm.defaultEducationOptions;
  final List<Map<String, String>> _communityOptions =
      Step4EligibilityForm.defaultCommunityOptions;
  final List<Map<String, dynamic>> _incomeOptions =
      Step4EligibilityForm.defaultIncomeOptions;

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

  static bool _looksLikePlaceName(String value, {int min = 2}) =>
      Step2LocationForm.looksLikePlaceName(value, min: min);

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

  static String _canonicalRoleTitle(String roleId) =>
      Step3AboutYouForm.canonicalRoleTitle(roleId);

  static String? _roleIdFromEmploymentStatus(String status) =>
      Step3AboutYouForm.roleIdFromEmploymentStatus(status);

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
        return Step1BasicDetailsForm(
          nameController: _nameController,
          emailController: _emailController,
          phoneController: _phoneController,
          ageController: _ageController,
          selectedGender: _selectedGender,
          onGenderChanged: (gender) {
            setState(() {
              _selectedGender = gender;
            });
          },
          onDobDerived: (dob) {
            _selectedDob = dob;
          },
          hasSubmitted: _hasSubmittedStep1,
          hasConsented: _hasConsentedDataProcessing,
          onConsentChanged: (consented) {
            setState(() {
              _hasConsentedDataProcessing = consented;
            });
          },
          onOpenConsentModal: _openDataProcessingConsentModal,
          onFieldChanged: () {
            if (_hasSubmittedStep1) setState(() {});
          },
        );
      case 2:
        return Step2LocationForm(
          addressController: _addressController,
          cityController: _cityController,
          districtController: _districtController,
          stateController: _stateController,
          isLoadingLocation: _isLoadingLocation,
          hasSubmitted: _hasSubmittedStep2,
          onFetchLocation: _fetchAndGeocodeLocation,
          onChanged: () => setState(() {}),
        );
      case 3:
        return Step3AboutYouForm(
          selectedRoleId: _selectedRole,
          onRoleSelected: (roleId) {
            setState(() {
              _selectedRole = roleId;
              _hasSubmittedStep3 = false;
            });
          },
          hasSubmitted: _hasSubmittedStep3,
        );
      case 4:
        return Step4EligibilityForm(
          selectedEducation: _selectedEducation,
          onEducationChanged: (edu) {
            setState(() {
              _selectedEducation = edu;
              _hasSubmittedStep4 = false;
            });
          },
          selectedCommunity: _selectedCommunity,
          onCommunityChanged: (comm) {
            setState(() {
              _selectedCommunity = comm;
              _hasSubmittedStep4 = false;
            });
          },
          selectedIncome: _selectedIncome,
          onIncomeChanged: (inc) {
            setState(() {
              _selectedIncome = inc;
              _hasSubmittedStep4 = false;
            });
          },
          isFirstGenGraduate: _isFirstGenGraduate,
          onFirstGenGraduateChanged: (val) {
            setState(() => _isFirstGenGraduate = val);
          },
          isDifferentlyAbled: _isDifferentlyAbled,
          onDifferentlyAbledChanged: (val) {
            setState(() => _isDifferentlyAbled = val);
          },
          isVeteran: _isVeteran,
          onVeteranChanged: (val) {
            setState(() => _isVeteran = val);
          },
          hasSubmitted: _hasSubmittedStep4,
          educationOptions: _educationOptions,
          communityOptions: _communityOptions,
          incomeOptions: _incomeOptions,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

