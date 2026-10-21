// Guard: the scheme detail screen in Hindi must not fall back to English.
//
// The Hindi path looks text up in assets/catalog/translation_dictionary_hi.json
// (exact, lower-cased match) and shows the original English when nothing
// matches. When a catalog refresh adds new text, this fails with what to add.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/localized_scheme.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';

// Three or more lower-case letters in a row is an ordinary English word;
// acronyms (PMEGP), ids, numbers and URLs do not count.
final _word = RegExp(r'(?<![A-Za-z])[a-z]{3,}');

/// Text that is still English although a Hindi version was asked for.
List<String> _englishLeaks(Scheme s, LocalizedScheme l) {
  final leaks = <String>[];
  void check(String field, String raw, String shown) {
    final t = raw.trim();
    if (t.isEmpty || shown.trim() != t || !_word.hasMatch(t)) return;
    leaks.add('$field: $t');
  }

  void list(String field, List<String> raw, List<String> shown) {
    for (var i = 0; i < raw.length && i < shown.length; i++) {
      check(field, raw[i], shown[i]);
    }
  }

  check('subsidyAmount', s.subsidyAmount, l.subsidyAmount);
  check('targetBeneficiary', s.targetBeneficiary, l.targetBeneficiary);
  check('capitalSubsidy', s.capitalSubsidyDetails, l.capitalSubsidyDetails);
  check('interestSubvention', s.interestSubventionDetails,
      l.interestSubventionDetails);
  check('ageRange', s.eligibilityAgeRange, l.eligibilityAgeRange);
  check('applicationFee', s.applicationFee, l.applicationFee);
  check('timeline', s.intakeTimelineText, l.intakeTimelineText);
  list('requiredDocuments', s.requiredDocuments, l.requiredDocuments);
  list('glanceChips', s.glanceChips, l.glanceChips);
  list('specialCategories', s.specialCategories, l.specialCategories);
  list('allowedBusinessTypes', s.allowedBusinessTypes, l.allowedBusinessTypes);
  for (var i = 0; i < s.documents.length && i < l.documents.length; i++) {
    final a = s.documents[i];
    final b = l.documents[i];
    check('doc.name', a.name, b.name);
    check('doc.description', a.description, b.description);
    check('doc.issuingAuthority', a.issuingAuthority, b.issuingAuthority);
    check('doc.estimatedCost', a.estimatedCost, b.estimatedCost);
    check('doc.remarks', a.remarks, b.remarks);
  }
  for (var i = 0;
      i < s.requiredServices.length && i < l.requiredServices.length;
      i++) {
    final a = s.requiredServices[i];
    final b = l.requiredServices[i];
    check('svc.name', a.name, b.name);
    check('svc.description', a.description, b.description);
    check('svc.department', a.department, b.department);
  }
  return leaks;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Scheme> all;

  setUpAll(() async {
    await CentralizedTranslator.instance.ensureLoaded();
    all = await SchemeRepository.instance.getAllSchemes();
  });

  test('PMEGP details have no English left in Hindi', () {
    final pmegp = all.firstWhere((s) => s.id == 'CEN2026-085');
    final leaks = _englishLeaks(pmegp, pmegp.toLocalized('hi'));
    expect(leaks, isEmpty, reason: 'English in Hindi:\n${leaks.join('\n')}');
  });

  test('Hindi detail text is read from the catalogue record itself', () {
    final pmegp = all.firstWhere((s) => s.id == 'CEN2026-085');
    expect(
      pmegp.documents.where((d) => d.descriptionHi.isNotEmpty),
      isNotEmpty,
      reason: 'requiredDocuments[].description carries {"en": ..., "hi": ...}',
    );
    final shown = pmegp.toLocalized('hi').documents;
    for (var i = 0; i < pmegp.documents.length; i++) {
      final d = pmegp.documents[i];
      if (d.descriptionHi.isNotEmpty) {
        expect(shown[i].description, d.descriptionHi);
      }
    }
  });

  test('English left across the catalogue in Hindi does not grow', () {
    var total = 0;
    for (final s in all) {
      total += _englishLeaks(s, s.toLocalized('hi')).length;
    }
    // Remaining items are one-off document notes and application steps.
    // Lower this number as they get translated; never raise it.
    expect(
      total,
      lessThanOrEqualTo(735),
      reason: 'New untranslated catalogue text in Hindi: $total items. Add the '
          'strings to assets/catalog/translation_dictionary_hi.json phraseMap.',
    );
  });
}
