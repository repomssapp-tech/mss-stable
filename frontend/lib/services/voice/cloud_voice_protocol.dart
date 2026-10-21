import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/user_profile.dart';
import '../../models/scheme_model.dart';
import 'voice_language.dart';

@visibleForTesting
const cloudProfileContextTopic = 'in-schemes.profile.v1';

@visibleForTesting
const cloudSchemeResultsAttribute = 'in.schemes.results.v1';

@immutable
class CloudSchemeResult {
  const CloudSchemeResult({
    required this.id,
    required this.code,
    required this.name,
    this.matchConfidence,
    this.isVerified = false,
    this.sourceConfidence = '',
  });

  final String id;
  final String code;
  final String name;
  final int? matchConfidence;
  final bool isVerified;
  final String sourceConfidence;
}

List<CloudSchemeResult> parseCloudSchemeResultsAttribute(String? value) {
  if (value == null || value.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(value);
    if (decoded is! Map || decoded['schema'] != 'in-schemes-results-v1') {
      return const [];
    }
    final rawResults = decoded['results'];
    if (rawResults is! List) return const [];
    final results = <CloudSchemeResult>[];
    for (final raw in rawResults.take(5)) {
      if (raw is! Map) continue;
      String text(String key) => (raw[key] as String? ?? '').trim();
      final result = CloudSchemeResult(
        id: text('id'),
        code: text('code'),
        name: text('name'),
        matchConfidence: raw['match_confidence'] is num
            ? (raw['match_confidence'] as num).round().clamp(0, 100)
            : null,
        isVerified: raw['is_verified'] == true,
        sourceConfidence: text('source_confidence'),
      );
      if (result.id.isNotEmpty ||
          result.code.isNotEmpty ||
          result.name.isNotEmpty) {
        results.add(result);
      }
    }
    return results;
  } on FormatException {
    return const [];
  }
}

List<Scheme> matchCloudSchemeResultsToCatalog(
  List<CloudSchemeResult> results,
  List<Scheme> catalog,
) {
  String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final byCode = <String, Scheme>{
    for (final scheme in catalog)
      if (scheme.id.trim().isNotEmpty) normalize(scheme.id): scheme,
    for (final scheme in catalog)
      if (scheme.schemeCode.trim().isNotEmpty)
        normalize(scheme.schemeCode): scheme,
  };
  final byName = <String, Scheme>{
    for (final scheme in catalog)
      if (scheme.name.trim().isNotEmpty) normalize(scheme.name): scheme,
  };
  final matched = <Scheme>[];
  for (final result in results) {
    final scheme =
        byCode[normalize(result.code)] ??
        byCode[normalize(result.id)] ??
        byName[normalize(result.name)];
    if (scheme != null && !matched.any((item) => item.id == scheme.id)) {
      matched.add(scheme);
    }
  }
  return matched;
}

@visibleForTesting
Map<String, dynamic> buildCloudProfileMetadata(
  UserProfile profile, {
  DateTime? now,
  String? languageCode,
}) {
  final facts = <String, dynamic>{};

  void addText(String key, String value) {
    final cleaned = value.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
    if (cleaned.isNotEmpty) {
      facts[key] = cleaned.substring(0, cleaned.length.clamp(0, 80));
    }
  }

  addText('name', profile.name);
  final dob = profile.dob;
  if (dob != null) {
    final today = now ?? DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age -= 1;
    }
    if (age >= 0 && age <= 120) facts['age'] = age;
  }
  addText('gender', profile.gender);
  addText('state', profile.state);
  addText('district', profile.district);
  addText('community', profile.community);
  addText(
    'education',
    profile.qualification.trim().isNotEmpty
        ? profile.qualification
        : profile.educationLevel,
  );
  addText('employment', profile.employmentStatus);
  if (profile.annualIncome > 0) facts['annualIncome'] = profile.annualIncome;
  addText('disability', profile.disability);
  facts['veteran'] = profile.veteran;

  return {
    'schema': 'in-schemes-profile-v1',
    'profile': facts,
    // The agent speaks the language the user picked, not a fixed one.
    if (languageCode != null) 'language': VoiceLanguage.code(languageCode),
  };
}
