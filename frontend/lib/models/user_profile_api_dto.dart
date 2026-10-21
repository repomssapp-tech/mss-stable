import 'user_profile.dart';

/// Strongly-typed model representing the backend ProfileAggregate from GET/PATCH /v1/me/profile.
/// Interface languages sent to the profile API: every language the app offers.
const Set<String> serverLanguages = {'en', 'ta', 'hi', 'mr'};

class ProfileAggregate {
  // Read-only server fields
  final String id;
  final String email;
  final String? photoUrl;
  final int version;
  final bool isProfileComplete;
  final List<String> missingFields;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? business;
  final List<Map<String, dynamic>> legalAcceptances;

  // Writable fields
  final String name;
  final String? dob; // YYYY-MM-DD
  final String? gender;
  final String? phone;
  final String? state;
  final String? district;
  final String? city;
  final String? pincode;
  final String? house;
  final String? area;
  final String? community;
  final String? religion;
  final String? educationLevel;
  final String? qualification;
  final String? applicantType;
  final String? disability;
  final bool? firstGenGraduate;
  final bool? veteran;
  final double? annualIncome;
  final String language;
  final bool notifications;
  final String theme;
  final String navigationMode;

  const ProfileAggregate({
    required this.id,
    required this.email,
    this.photoUrl,
    required this.version,
    required this.isProfileComplete,
    this.missingFields = const [],
    this.createdAt,
    this.updatedAt,
    this.business,
    this.legalAcceptances = const [],
    required this.name,
    this.dob,
    this.gender,
    this.phone,
    this.state,
    this.district,
    this.city,
    this.pincode,
    this.house,
    this.area,
    this.community,
    this.religion,
    this.educationLevel,
    this.qualification,
    this.applicantType,
    this.disability,
    this.firstGenGraduate,
    this.veteran,
    this.annualIncome,
    this.language = 'en',
    this.notifications = true,
    this.theme = 'light',
    this.navigationMode = 'regular',
  });

  factory ProfileAggregate.fromJson(Map<String, dynamic> json) {
    return ProfileAggregate(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
      version: (json['version'] as num?)?.toInt() ?? 1,
      isProfileComplete: json['is_profile_complete'] == true,
      missingFields:
          (json['missing_fields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      business: json['business'] is Map<String, dynamic>
          ? json['business'] as Map<String, dynamic>
          : null,
      legalAcceptances:
          (json['legal_acceptances'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          const [],
      name: json['name']?.toString() ?? '',
      dob: json['dob']?.toString(),
      gender: json['gender']?.toString(),
      phone: json['phone']?.toString(),
      state: json['state']?.toString(),
      district: json['district']?.toString(),
      city: json['city']?.toString(),
      pincode: json['pincode']?.toString(),
      house: json['house']?.toString(),
      area: json['area']?.toString(),
      community: json['community']?.toString(),
      religion: json['religion']?.toString(),
      educationLevel: json['education_level']?.toString(),
      qualification: json['qualification']?.toString(),
      applicantType: json['applicant_type']?.toString(),
      disability: json['disability']?.toString(),
      firstGenGraduate: json['first_gen_graduate'] as bool?,
      veteran: json['veteran'] as bool?,
      annualIncome: (json['annual_income'] as num?)?.toDouble(),
      language: json['language']?.toString() ?? 'en',
      notifications: json['notifications'] != false,
      theme: json['theme']?.toString() ?? 'light',
      navigationMode: json['navigation_mode']?.toString() ?? 'regular',
    );
  }

  /// Converts this server aggregate into the local Flutter [UserProfile].
  UserProfile toUserProfile() {
    DateTime? parsedDob;
    if (dob != null && dob!.isNotEmpty) {
      parsedDob = DateTime.tryParse(dob!);
    }

    final hasBusiness = business != null;
    final businessData = business ?? const {};

    return UserProfile(
      googleUserId: id,
      email: email,
      profilePhoto: photoUrl ?? '',
      name: name,
      dob: parsedDob,
      gender: gender ?? '',
      mobile: phone ?? '',
      state: state ?? '',
      district: district ?? '',
      city: city ?? '',
      pinCode: pincode ?? '',
      house: house ?? '',
      area: area ?? '',
      community: community ?? '',
      religion: religion ?? '',
      educationLevel: educationLevel ?? '',
      qualification: qualification ?? '',
      employmentStatus: applicantType ?? '',
      disability: disability ?? 'None',
      firstGenGraduate: firstGenGraduate ?? false,
      veteran: veteran ?? false,
      annualIncome: annualIncome ?? 0.0,
      language: language,
      notificationsEnabled: notifications,
      theme: theme,
      navigationMode: navigationMode,
      profileCompleted: isProfileComplete,
      updatedAt: updatedAt,
      existingBusiness: hasBusiness
          ? (businessData['business_registered'] == true)
          : false,
      businessStage: businessData['business_stage']?.toString() ?? '',
      businessIndustry: businessData['industry']?.toString() ?? '',
      fundingRequired:
          (businessData['funding_required_amount'] as num?)?.toDouble() ?? 0.0,
      registrationNumbers:
          businessData['registration_numbers']?.toString() ?? '',
    );
  }

  /// Builds a PATCH map containing only modified, allowed writable fields.
  static Map<String, dynamic> buildPatchPayload({
    required UserProfile current,
    ProfileAggregate? baseline,
  }) {
    final base =
        baseline ??
        const ProfileAggregate(
          id: '',
          email: '',
          name: '',
          version: 1,
          isProfileComplete: false,
        );
    final patch = <String, dynamic>{};

    void checkString(
      String key,
      String newVal,
      String? oldVal, {
      bool nullable = true,
    }) {
      final trimmed = newVal.trim();
      final oldTrimmed = oldVal?.trim();
      if (trimmed != (oldTrimmed ?? '')) {
        if (trimmed.isEmpty && nullable) {
          patch[key] = null;
        } else if (trimmed.isNotEmpty) {
          patch[key] = trimmed;
        }
      }
    }

    // Name (non-nullable, trimmed 1..150)
    if (current.name.trim().isNotEmpty &&
        current.name.trim() != base.name.trim()) {
      patch['name'] = current.name.trim();
    }

    // DOB (YYYY-MM-DD)
    final currentDobStr = current.dob != null
        ? current.dob!.toIso8601String().split('T')[0]
        : null;
    if (currentDobStr != base.dob) {
      patch['dob'] = currentDobStr;
    }

    checkString('gender', current.gender, base.gender);
    checkString('phone', current.mobile, base.phone);
    checkString('state', current.state, base.state);
    checkString('district', current.district, base.district);
    checkString('city', current.city, base.city);
    checkString('pincode', current.pinCode, base.pincode);
    checkString('house', current.house, base.house);
    checkString('area', current.area, base.area);
    checkString('community', current.community, base.community);
    // `religion` is not part of the profile API any more (backend migration
    // 017); a legacy local value is never sent.
    checkString('education_level', current.educationLevel, base.educationLevel);
    checkString('qualification', current.qualification, base.qualification);
    checkString('applicant_type', current.employmentStatus, base.applicantType);
    checkString('disability', current.disability, base.disability);

    if (current.firstGenGraduate != (base.firstGenGraduate ?? false)) {
      patch['first_gen_graduate'] = current.firstGenGraduate;
    }

    if (current.veteran != (base.veteran ?? false)) {
      patch['veteran'] = current.veteran;
    }

    if (current.annualIncome != (base.annualIncome ?? -1)) {
      patch['annual_income'] = current.annualIncome;
    }

    // The profile API stores only en|ta. A language it cannot store (Hindi)
    // stays on the device; sending it would reject the whole patch.
    if (current.language != base.language &&
        serverLanguages.contains(current.language)) {
      patch['language'] = current.language;
    }

    if (current.notificationsEnabled != base.notifications) {
      patch['notifications'] = current.notificationsEnabled;
    }

    if (current.theme != base.theme) {
      patch['theme'] = current.theme;
    }

    if (current.navigationMode != base.navigationMode) {
      patch['navigation_mode'] = current.navigationMode;
    }

    return patch;
  }
}
