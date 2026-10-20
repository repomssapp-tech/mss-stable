// Card chips come from comma-separated catalog fields. A comma inside brackets
// belongs to one phrase and must not cut it into fragments like "services)".
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/chip_list.dart';

void main() {
  test('splits plain comma lists and trims', () {
    expect(splitChipList('Loan, Subsidy ,Grant'), ['Loan', 'Subsidy', 'Grant']);
  });

  test('keeps a bracketed comma list together', () {
    expect(
      splitChipList(
        'Food processing (micro enterprises, trading, services), Manufacturing',
      ),
      ['Food processing (micro enterprises, trading, services)', 'Manufacturing'],
    );
  });

  test('drops empty parts and the pending-verification placeholder', () {
    expect(splitChipList(', ,Pending official verification, Skill,'), ['Skill']);
  });

  test('an unbalanced bracket never swallows the rest', () {
    expect(splitChipList('Loan (partial, Grant'), ['Loan (partial, Grant']);
  });

  test('empty input gives an empty list', () {
    expect(splitChipList(''), isEmpty);
  });
}
