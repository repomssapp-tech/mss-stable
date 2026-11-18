import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../main.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/common/app_toast.dart';
import 'assisted_profile/assisted_step_footer.dart';
import 'assisted_profile/step1_state_selector.dart';
import 'assisted_profile/step2_gender_age_selector.dart';
import 'assisted_profile/step3_role_stage_selector.dart';
import 'assisted_profile/step4_sector_selector.dart';
import 'assisted_profile/step5_community_selector.dart';
import 'assisted_profile/step6_education_selector.dart';
import 'assisted_profile/step_indicator_bar.dart';
import '../../services/location_lock/location_lock.dart';

export 'assisted_profile/assisted_selection_card.dart';
export 'assisted_profile/assisted_step_footer.dart';
export 'assisted_profile/step1_state_selector.dart';
export 'assisted_profile/step2_gender_age_selector.dart';
export 'assisted_profile/step3_role_stage_selector.dart';
export 'assisted_profile/step4_sector_selector.dart';
export 'assisted_profile/step5_community_selector.dart';
export 'assisted_profile/step6_education_selector.dart';
export 'assisted_profile/step_indicator_bar.dart';

/// Clean coordinator for the Assisted Profile Creation flow in Companion Mode.
///
/// Collects only the essential demographic & eligibility facets needed by the
/// recommendation engine without requiring keyboard typing.
class SaarthiWelcomeScreen extends StatefulWidget {
  const SaarthiWelcomeScreen({super.key});

  @override
  State<SaarthiWelcomeScreen> createState() => _SaarthiWelcomeScreenState();
}

class _SaarthiWelcomeScreenState extends State<SaarthiWelcomeScreen> {
  static const int kTotalSteps = 6;

  int _currentStep = 1;
  bool _isSubmitting = false;

  // Form State
  String _selectedState = 'Tamil Nadu';
  String _selectedGender = '';
  int _selectedAge = 28;
  String _selectedRoleId = '';
  String _selectedSector = '';
  String _selectedCommunity = '';
  String _selectedEducation = '';

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppProvider>(context, listen: false).profile;
    if (profile.state.isNotEmpty) _selectedState = profile.state;
    final locked = LocationScope.stateName;
    if (locked != null) _selectedState = locked;
    if (profile.gender.isNotEmpty) _selectedGender = profile.gender;
    if (profile.dob != null) _selectedAge = profile.age;
    if (profile.businessIndustry.isNotEmpty) {
      _selectedSector = profile.businessIndustry;
    }
    if (profile.community.isNotEmpty) _selectedCommunity = profile.community;
    if (profile.educationLevel.isNotEmpty) {
      _selectedEducation = profile.educationLevel;
    }
    _selectedRoleId = _inferRoleId(profile.employmentStatus);
  }

  String _inferRoleId(String employment) {
    final lower = employment.toLowerCase().trim();
    if (lower.contains('student')) return 'student';
    if (lower.contains('farmer')) return 'farmer';
    if (lower.contains('artisan') || lower.contains('shg')) return 'artisan';
    if (lower.contains('business') || lower.contains('msme')) {
      return 'existing_business';
    }
    if (lower.contains('entrepreneur')) return 'entrepreneur';
    return '';
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleContinue() {
    if (_currentStep < kTotalSteps) {
      // Smart infer default sector if moving from Step 3 to Step 4
      if (_currentStep == 3 && _selectedSector.isEmpty) {
        if (_selectedRoleId == 'farmer') {
          _selectedSector = 'Agriculture';
        } else if (_selectedRoleId == 'artisan') {
          _selectedSector = 'Handicrafts';
        } else if (_selectedRoleId == 'student') {
          _selectedSector = 'General';
        }
      }
      setState(() => _currentStep++);
    } else {
      _submitProfile();
    }
  }

  Future<void> _submitProfile() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Map role & stage cleanly
    String employmentStatus = 'Entrepreneur';
    String businessStage = 'Idea';
    bool existingBusiness = false;

    switch (_selectedRoleId) {
      case 'student':
        employmentStatus = 'Student';
        businessStage = '';
        existingBusiness = false;
        break;
      case 'farmer':
        employmentStatus = 'Farmer';
        businessStage = 'Operational';
        existingBusiness = true;
        break;
      case 'artisan':
        employmentStatus = 'Artisan / SHG Member';
        businessStage = 'Operational';
        existingBusiness = true;
        break;
      case 'existing_business':
        employmentStatus = 'Business Owner';
        businessStage = 'Operational';
        existingBusiness = true;
        break;
      case 'entrepreneur':
      default:
        employmentStatus = 'Entrepreneur';
        businessStage = 'Idea';
        existingBusiness = false;
        break;
    }

    final calculatedDob = DateTime(DateTime.now().year - _selectedAge, 1, 1);
    final isMinority = _selectedCommunity.toLowerCase() == 'minority';

    final updatedProfile = provider.profile.copyWith(
      state: _selectedState,
      gender: _selectedGender,
      dob: calculatedDob,
      employmentStatus: employmentStatus,
      businessStage: businessStage,
      existingBusiness: existingBusiness,
      businessIndustry: _selectedSector,
      community: _selectedCommunity,
      religion: isMinority ? 'Minority' : provider.profile.religion,
      educationLevel: _selectedEducation,
      qualification: _selectedEducation,
      profileCompleted: true,
      navigationMode: 'companion',
    );

    try {
      await provider.updateProfile(updatedProfile, requireCloudSync: true);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainTabsContainer()),
        (route) => false,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[SaarthiWelcomeScreen] Error submitting profile: $error\n$stackTrace',
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // Unable to save profile notice
      AppToast.showError(context, context.l10n.profileErrUnableToSave);
    }
  }

  bool get _isStepValid {
    switch (_currentStep) {
      case 1:
        return _selectedState.isNotEmpty;
      case 2:
        return _selectedGender.isNotEmpty && _selectedAge >= 18;
      case 3:
        return _selectedRoleId.isNotEmpty;
      case 4:
        return _selectedSector.isNotEmpty;
      case 5:
        return _selectedCommunity.isNotEmpty;
      case 6:
        return _selectedEducation.isNotEmpty;
      default:
        return false;
    }
  }

  String _getStepTitle(BuildContext context) {
    final l10n = context.l10n;
    switch (_currentStep) {
      case 1:
        return l10n.simpleProfileStepStateTitle;
      case 2:
        return l10n.simpleProfileStepGenderAgeTitle;
      case 3:
        return l10n.simpleProfileStepWorkTitle;
      case 4:
        return l10n.simpleProfileStepSectorTitle;
      case 5:
        return l10n.simpleProfileStepCommunityTitle;
      case 6:
        return l10n.simpleProfileStepEducationTitle;
      default:
        return '';
    }
  }

  String _getStepSubtitle(BuildContext context) {
    final l10n = context.l10n;
    switch (_currentStep) {
      case 1:
        return l10n.simpleProfileStepStateSubtitle;
      case 2:
        return l10n.simpleProfileStepGenderAgeSubtitle;
      case 3:
        return l10n.simpleProfileStepWorkSubtitle;
      case 4:
        return l10n.simpleProfileStepSectorSubtitle;
      case 5:
        return l10n.simpleProfileStepCommunitySubtitle;
      case 6:
        return l10n.simpleProfileStepEducationSubtitle;
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return Step1StateSelector(
          selectedState: _selectedState,
          onStateSelected: (val) => setState(() => _selectedState = val),
        );
      case 2:
        return Step2GenderAgeSelector(
          selectedGender: _selectedGender,
          onGenderSelected: (val) => setState(() => _selectedGender = val),
          selectedAge: _selectedAge,
          onAgeChanged: (val) => setState(() => _selectedAge = val),
        );
      case 3:
        return Step3RoleStageSelector(
          selectedRoleId: _selectedRoleId,
          onRoleSelected: (val) => setState(() => _selectedRoleId = val),
        );
      case 4:
        return Step4SectorSelector(
          selectedSector: _selectedSector,
          onSectorSelected: (val) => setState(() => _selectedSector = val),
        );
      case 5:
        return Step5CommunitySelector(
          selectedCommunity: _selectedCommunity,
          onCommunitySelected: (val) =>
              setState(() => _selectedCommunity = val),
        );
      case 6:
        return Step6EducationSelector(
          selectedEducation: _selectedEducation,
          onEducationSelected: (val) =>
              setState(() => _selectedEducation = val),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          // Header and options scroll; the footer stays pinned so the primary
          // button is always reachable, even when translated options are tall.
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                StepIndicatorBar(
                  currentStep: _currentStep,
                  totalSteps: kTotalSteps,
                  title: _getStepTitle(context),
                  subtitle: _getStepSubtitle(context),
                  onBack: _handleBack,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_currentStep),
                        child: _buildCurrentStepContent(),
                      ),
                    ),
                  ),
                ),
                AssistedStepFooter(
                  isLastStep: _currentStep == kTotalSteps,
                  isSubmitting: _isSubmitting,
                  isEnabled: _isStepValid,
                  onContinue: _handleContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
