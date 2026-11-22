import '../../models/questionnaire.dart';

List<QuestionnaireField> assessmentFields(
  QuestionnaireDefinition definition, {
  required String title,
  required String cardType,
}) {
  final ids = switch ((cardType, title)) {
    ('category', 'Startup & Incubation') => const [
      'business_age',
      'business_nature',
      'scheme_goal',
      'assistance_needed',
    ],
    ('category', 'Student & Youth Startups') => const [
      'business_age',
      'education_level',
      'scheme_goal',
      'assistance_needed',
    ],
    ('category', 'Loans & Credit Support' || 'Finance & Banking') ||
    ('ministry', 'Ministry of Finance') => const [
      'scheme_goal',
      'business_age',
      'org_structure',
      'tax_compliance_comfort',
    ],
    ('category', 'Women Entrepreneurship') => const [
      'general_gender',
      'business_age',
      'org_structure',
      'assistance_needed',
    ],
    ('category', 'Skill Development') ||
    ('ministry', 'Ministry of Skill Development') => const [
      'education_level',
      'business_nature',
      'digital_literacy_level',
      'assistance_needed',
    ],
    ('category', 'Artisan & Craftsmen' || 'Khadi & Village Industries') =>
      const [
        'business_age',
        'has_gi_tag',
        'cluster_membership',
        'assistance_needed',
      ],
    ('category', 'Digital India & Tech') => const [
      'digital_literacy_level',
      'business_nature',
      'assistance_needed',
    ],
    ('category', 'Technology & Innovation') => const [
      'business_nature',
      'business_age',
      'scheme_goal',
      'digital_literacy_level',
    ],
    ('category', 'Manufacturing & Industry' || 'Food Processing') => const [
      'business_nature',
      'business_age',
      'cluster_membership',
      'scheme_goal',
      'assistance_needed',
    ],
    ('category', 'Export & Trade Promotion') => const [
      'export_status',
      'business_age',
      'has_gi_tag',
      'assistance_needed',
      'tax_compliance_comfort',
    ],
    ('category', 'Agriculture & Allied') ||
    ('ministry', 'Ministry of Agriculture') => const [
      'business_nature',
      'org_structure',
      'special_focus_zone',
      'assistance_needed',
    ],
    ('category', 'Rural Development & SHG') ||
    ('ministry', 'Ministry of Rural Development') => const [
      'org_structure',
      'special_focus_zone',
      'social_category',
      'assistance_needed',
    ],
    ('category', 'SC / ST & Minority') ||
    (
      'ministry',
      'Ministry of Social Justice',
    ) => const ['social_category', 'special_focus_zone', 'assistance_needed'],
    (
      'category',
      'Green Energy & Environment' || 'Renewable & Energy Efficiency',
    ) =>
      const ['business_nature', 'scheme_goal', 'assistance_needed'],
    ('category', 'Health & Healthcare') => const [
      'social_category',
      'business_nature',
      'assistance_needed',
    ],
    ('category', 'Education & Fellowship') ||
    (
      'ministry',
      'Ministry of Education',
    ) => const ['education_level', 'social_category', 'digital_literacy_level'],
    ('category', 'Infrastructure & Logistics') => const [
      'business_age',
      'cluster_membership',
      'special_focus_zone',
      'scheme_goal',
    ],
    ('category', 'Social Welfare & Support') ||
    (
      'ministry',
      'Ministry of Housing',
    ) => const ['general_gender', 'social_category', 'special_focus_zone'],
    ('category', 'Business & MSME') ||
    ('ministry', 'Ministry of MSME') => const [
      'business_nature',
      'general_gender',
      'scheme_goal',
      'business_age',
      'assistance_needed',
    ],
    _ => const [
      'business_nature',
      'scheme_goal',
      'business_age',
      'assistance_needed',
    ],
  };
  final byId = {for (final field in definition.allFields) field.id: field};
  return ids.map((id) => byId[id]).whereType<QuestionnaireField>().toList();
}
