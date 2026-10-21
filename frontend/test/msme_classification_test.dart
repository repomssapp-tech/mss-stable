import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/msme_classification.dart';

/// 2025 MSME limits (issue #124): investment / turnover in ₹ crore.
void main() {
  MsmeTier c(double inv, double turn) =>
      classifyMsme(investmentCr: inv, turnoverCr: turn);

  test('values from the QA report now classify correctly', () {
    expect(c(2, 8), MsmeTier.micro); // was "Small" with the 2020 limits
    expect(c(100, 400), MsmeTier.medium); // was "Large"
  });

  test('tier boundaries are inclusive', () {
    expect(c(2.5, 10), MsmeTier.micro);
    expect(c(25, 100), MsmeTier.small);
    expect(c(125, 500), MsmeTier.medium);
    expect(c(125.01, 500), MsmeTier.large);
  });

  test('both limits must hold', () {
    expect(c(1, 11), MsmeTier.small); // turnover pushes it out of Micro
    expect(c(30, 50), MsmeTier.medium); // investment pushes it out of Small
  });

  test('summary shows the 2025 limits', () {
    final s = msmeLimitsSummary();
    expect(s, contains('≤2.5cr / ≤10cr'));
    expect(s, contains('≤25cr / ≤100cr'));
    expect(s, contains('≤125cr / ≤500cr'));
  });
}
