import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/analytics/app_analytics.dart';
import '../../providers/app_state_provider.dart';
import '../../l10n/l10n.dart';
import '../../services/recommendation/indian_states.dart';
import '../../services/recommendation/profile_canonicalizer.dart';
import '../profile/profile_value_formatters.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/legal/data_processing_consent_modal.dart';
import '../navigation_mode_screen.dart';
import '../../main.dart';
import 'basic_profile/location_geocoding.dart';
import 'basic_profile/profile_continue_button.dart';
import 'basic_profile/profile_progress_indicator.dart';
import 'basic_profile/step1_basic_details_form.dart';
import 'basic_profile/step2_location_form.dart';
import 'basic_profile/step3_about_you_form.dart';
import 'basic_profile/step4_eligibility_form.dart';
import '../../widgets/common/app_icon_button.dart';
import '../../services/location_lock/location_lock.dart';

export 'basic_profile/custom_input_field.dart';
export 'basic_profile/role_model.dart';
export 'basic_profile/step1_basic_details_form.dart';
export 'basic_profile/step2_location_form.dart';
export 'basic_profile/step3_about_you_form.dart';
export 'basic_profile/step4_eligibility_form.dart';

class BasicProfileScreen extends StatefulWidget {
  final int initialStep;
  final bool resume;

  const BasicProfileScreen({
    super.key,
    this.initialStep = 1,
    this.resume = false,
  });

  @override
  State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends State<BasicProfileScreen> {
  final _analyticsInteractionId = AppAnalytics.instance.interactionId();
  static const _analyticsSections = [
    'basic_details',
    'location',
    'about_you',
    'eligibility',
  ];

  void _trackProfileStep(int step, String action) {
    AppAnalytics.instance.track(
      AnalyticsEvent.profileProgress,
      interactionId: _analyticsInteractionId,
      properties: {'section': _analyticsSections[step - 1], 'action': action},
    );
  }

  late int _currentStep;

  // Theme Constants

  // --- Step 1: Basic Details Controllers & State ---
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;
  late final TextEditingController _ageController;
  String _selectedGender = '';
  DateTime? _selectedDob;
  bool _hasSubmittedStep1 = false;

  // --- Step 2: Location Controllers & State ---
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  bool _isLoadingLocation = false;
  bool _hasSubmittedStep2 = false;

  // --- Step 3: About You State ---
  Set<String> _selectedRoles = {};
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
    _trackProfileStep(_currentStep, 'shown');
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
    // Saved labels may be in another language than the one now selected.
    final labels = l10nFor(provider.selectedLanguage);
    _selectedGender = profile.gender.isNotEmpty
        ? ProfileValueFormatters.inLanguageOf(profile.gender, labels)
        : '';

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
    _pincodeController = TextEditingController(text: profile.pinCode);
    _fillFromLocationLock();

    // 3. Initialize Step 3 role. Saved answers prefill steps 3-4 even while
    // the server has not marked the profile complete; otherwise a re-run of
    // onboarding showed them blank and required (issue #123).
    _selectedRoles =
        ProfileCanonicalizer.employmentRoles(profile.employmentStatus)
            .map(Step3AboutYouForm.roleIdFromEmploymentStatus)
            .whereType<String>()
            .toSet();

    // 4. Initialize Step 4 eligibility
    final hasSavedEligibility =
        profile.qualification.isNotEmpty ||
        profile.educationLevel.isNotEmpty ||
        profile.community.isNotEmpty ||
        profile.annualIncome > 0;
    if (profile.profileCompleted || hasSavedEligibility) {
      _selectedEducation = ProfileCanonicalizer.education(
        profile.educationLevel.isNotEmpty
            ? profile.educationLevel
            : profile.qualification,
      );
      _selectedCommunity = ProfileCanonicalizer.community(profile.community);
      _selectedIncome = profile.annualIncome;
      _isDifferentlyAbled =
          profile.disability.isNotEmpty &&
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
    if (widget.resume) {
      _currentStep = !_isStep1Valid
          ? 1
          : !_isStep2Valid
          ? 2
          : _selectedRoles.isEmpty
          ? 3
          : 4;
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
    _pincodeController.dispose();
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

  Future<void> _openDataProcessingConsentModal() =>
      DataProcessingConsentModal.show(context);

  static bool _looksLikePlaceName(String value, {int min = 2}) =>
      Step2LocationForm.looksLikePlaceName(value, min: min);

  bool get _isStep1Valid =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.contains('@') &&
      _phoneController.text.trim().length == 10 &&
      _selectedGender.isNotEmpty &&
      _selectedDob != null;

  bool get _isStep2Valid =>
      _addressController.text.trim().isNotEmpty &&
      _looksLikePlaceName(_cityController.text, min: 2) &&
      _looksLikePlaceName(_districtController.text, min: 2) &&
      Step2LocationForm.isKnownState(_stateController.text) &&
      Step2LocationForm.isValidPincode(_pincodeController.text);

  // Step 4 (Eligibility) now requires education, community and income --
  // these drive scheme matching, so the profile is not "complete" without
  // them. Special-category toggles stay optional.
  bool get _isStep4Valid =>
      _selectedEducation.isNotEmpty &&
      _selectedCommunity.isNotEmpty &&
      _selectedIncome != null;

  /// Location lock: the GPS address fills any empty address field, and the
  /// state is always the GPS state. Filled fields keep what the user typed.
  void _fillFromLocationLock() {
    final lock = LocationScope.active ? LocationScope.current.value : null;
    if (lock == null) return;
    void fill(TextEditingController c, String value) {
      if (c.text.trim().isEmpty && value.trim().isNotEmpty) c.text = value;
    }

    fill(_addressController, lock.address);
    fill(_cityController, lock.city);
    fill(_districtController, lock.district);
    fill(_pincodeController, lock.pincode);
    _stateController.text = lock.stateName;
  }

  // Geocoding live fetch for Step 2 -- see basic_profile/location_geocoding.dart
  Future<void> _fetchAndGeocodeLocation() => fetchAndGeocodeLocation(
    context: context,
    addressController: _addressController,
    cityController: _cityController,
    districtController: _districtController,
    stateController: _stateController,
    pincodeController: _pincodeController,
    isMounted: () => mounted,
    setLoading: (loading) {
      if (mounted) setState(() => _isLoadingLocation = loading);
    },
  );

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
      _trackProfileStep(_currentStep, 'shown');
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

      if (!_isStep1Valid) {
        AppToast.showError(
          context,
          context.l10n.profileErrCompleteFieldsCorrectly,
        );
        return;
      }

      final provider = Provider.of<AppProvider>(context, listen: false);
      provider
          .updateProfile(
            provider.profile.copyWith(
              name: name,
              email: email,
              mobile: phone,
              gender: _selectedGender,
              dob: _selectedDob,
            ),
            requireCloudSync: false,
          )
          .then((_) => _trackProfileStep(1, 'draft_saved'));

      setState(() => _currentStep = 2);
      _trackProfileStep(2, 'shown');
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
      final state = IndianStates.canonical(_stateController.text);

      final provider = Provider.of<AppProvider>(context, listen: false);
      provider
          .updateProfile(
            provider.profile.copyWith(
              house: address,
              area: address,
              city: city,
              district: district,
              state: state,
              pinCode: _pincodeController.text.trim(),
            ),
            requireCloudSync: false,
          )
          .then((_) => _trackProfileStep(2, 'draft_saved'));

      setState(() => _currentStep = 3);
      _trackProfileStep(3, 'shown');
    } else if (_currentStep == 3) {
      if (_selectedRoles.isEmpty) {
        setState(() => _hasSubmittedStep3 = true);
        return;
      }

      final provider = Provider.of<AppProvider>(context, listen: false);
      provider
          .updateProfile(
            provider.profile.copyWith(
              employmentStatus: _selectedRoles
                  .map(Step3AboutYouForm.canonicalRoleTitle)
                  .join(', '),
            ),
            requireCloudSync: false,
          )
          .then((_) => _trackProfileStep(3, 'draft_saved'));

      setState(() => _currentStep = 4);
      _trackProfileStep(4, 'shown');
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
      final localOnly = provider.isGuest;
      await provider.updateProfile(updatedProfile, requireCloudSync: true);
      _trackProfileStep(4, localOnly ? 'draft_saved' : 'cloud_saved');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainTabsContainer()),
        (route) => false,
      );
    } catch (error, stackTrace) {
      if (!provider.isGuest) _trackProfileStep(4, 'sync_failed');
      debugPrint(
        '[BasicProfileScreen] Error submitting profile: $error\n$stackTrace',
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.showError(context, context.l10n.profileErrUnableToSave);
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
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          AppIconButton(
                            icon: Icons.arrow_back_rounded,
                            semanticLabel: l10n.back,
                            onPressed: _handleBack,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.completeYourProfile,
                              style: context.text.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: ValueKey(_currentStep),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ProfileProgressIndicator(
                                currentStep: _currentStep,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _buildStepForm(_currentStep),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: ProfileContinueButton(
                          currentStep: _currentStep,
                          isSubmitting: _isSubmitting,
                          isStep2Valid: _isStep2Valid,
                          hasSelectedRole: _selectedRoles.isNotEmpty,
                          isStep4Valid: _isStep4Valid,
                          onPressed: _handleContinue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Final-submit overlay: the cloud sync can take a few seconds,
            // so show progress instead of an idle-looking form.
            if (_isSubmitting)
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.textPrimary.withValues(alpha: 0.35),
                  child: Center(
                    child: Semantics(
                      liveRegion: true,
                      label: l10n.profileSettingUp,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.textOnPrimary,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.profileSettingUp,
                            style: context.text.button.copyWith(
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
          pincodeController: _pincodeController,
          isLoadingLocation: _isLoadingLocation,
          hasSubmitted: _hasSubmittedStep2,
          onFetchLocation: _fetchAndGeocodeLocation,
          onChanged: () => setState(() {}),
        );
      case 3:
        return Step3AboutYouForm(
          selectedRoleIds: _selectedRoles,
          onRoleToggled: (roleId) {
            setState(() {
              if (!_selectedRoles.add(roleId)) _selectedRoles.remove(roleId);
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
