import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/utils/money_format.dart';

void main() {
  test('formats with Indian digit grouping and two decimals by default', () {
    expect(formatInr(1234567.891), '₹ 12,34,567.89');
  });

  test('respects a custom decimals count', () {
    expect(formatInr(1234567, decimals: 0), '₹ 12,34,567');
  });

  test('formats small amounts without extra grouping separators', () {
    expect(formatInr(500), '₹ 500.00');
  });
}
