/// Represents an available legal document in the backend registry (GET /v1/me/legal-documents).
class LegalDocumentItem {
  final String documentType;
  final String documentVersion;

  const LegalDocumentItem({
    required this.documentType,
    required this.documentVersion,
  });

  factory LegalDocumentItem.fromJson(Map<String, dynamic> json) {
    return LegalDocumentItem(
      documentType: json['document_type']?.toString() ?? '',
      documentVersion: json['document_version']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'document_type': documentType,
        'document_version': documentVersion,
      };
}

/// Registry response indicating whether legal versions are configured and active.
class LegalDocumentsResponse {
  final bool configured;
  final List<LegalDocumentItem> items;

  const LegalDocumentsResponse({
    required this.configured,
    required this.items,
  });

  factory LegalDocumentsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return LegalDocumentsResponse(
      configured: json['configured'] == true,
      items: list
          .whereType<Map<String, dynamic>>()
          .map(LegalDocumentItem.fromJson)
          .toList(),
    );
  }
}

/// Structured business section DTO for onboarding (PUT /v1/me/onboarding).
class BusinessProfileDto {
  final String profileName;
  final String industry;
  final String applicantType;
  final String businessStage; // Idea, Prototype, Registered, Operational, Expansion
  final bool businessRegistered;
  final double fundingRequiredAmount;
  final String registrationNumbers;
  final bool isFirstGenerationEntrepreneur;

  const BusinessProfileDto({
    required this.profileName,
    required this.industry,
    required this.applicantType,
    required this.businessStage,
    required this.businessRegistered,
    required this.fundingRequiredAmount,
    this.registrationNumbers = '',
    required this.isFirstGenerationEntrepreneur,
  });

  Map<String, dynamic> toJson() => {
        'profile_name': profileName.trim(),
        'industry': industry.trim(),
        'applicant_type': applicantType.trim(),
        'business_stage': businessStage.trim(),
        'business_registered': businessRegistered,
        'funding_required_amount': fundingRequiredAmount,
        'registration_numbers': registrationNumbers.trim(),
        'is_first_generation_entrepreneur': isFirstGenerationEntrepreneur,
      };
}

/// Full payload for atomic onboarding completion (PUT /v1/me/onboarding).
class OnboardingSubmissionDto {
  final Map<String, dynamic> profile;
  final BusinessProfileDto? business;
  final List<LegalDocumentItem> legalAcceptances;

  const OnboardingSubmissionDto({
    required this.profile,
    this.business,
    required this.legalAcceptances,
  });

  Map<String, dynamic> toJson() => {
        'profile': profile,
        'business': business?.toJson(),
        'legal_acceptances': legalAcceptances.map((l) => l.toJson()).toList(),
      };
}
