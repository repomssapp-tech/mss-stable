import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_extras.dart';
import 'package:frontend/utils/msme_classification.dart';

/// Fixes from the 1.2.1 / 1.3.0 QA test reports that are plain logic.
void main() {
  group('Udyam classifier accepts 0 (BUG-12)', () {
    test('a new unit with no investment or turnover yet is Micro', () {
      expect(classifyMsme(investmentCr: 0, turnoverCr: 0), MsmeTier.micro);
      expect(classifyMsme(investmentCr: 0, turnoverCr: 50), MsmeTier.small);
    });

    test('crore values print without a trailing .0', () {
      expect(formatCrore(10), '10');
      expect(formatCrore(2.5), '2.5');
    });
  });

  group('status note', () {
    SchemeExtras withNote(String note) => SchemeExtras.fromEntity({
      'identity': {'id': 'X-1', 'entityType': 'scheme', 'code': 'X-1'},
      'source': {'id': 'X-1', 'how_to_apply': {}},
      'localization': {
        'en': {'statusNote': note},
        'ta': {'statusNote': '$note (ta)'},
      },
    });

    test('the generated catalogue metadata line is hidden', () {
      for (final note in [
        'Catalogue status active; verification verified (high).',
        'Catalogue status active; verification partially_verified (medium).',
        'Catalogue status closed; verification verified (high)',
      ]) {
        expect(withNote(note).statusNote('en'), isEmpty, reason: note);
        expect(withNote(note).statusNote('ta'), isEmpty, reason: note);
      }
    });

    test('a real note is still shown', () {
      const note = 'Applications reopen in April after the budget.';
      expect(withNote(note).statusNote('en'), note);
      expect(withNote(note).statusNote('ta'), '$note (ta)');
    });
  });
}
