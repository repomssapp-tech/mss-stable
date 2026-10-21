/// MSME classification limits (Ministry of MSME notification, effective
/// 1 April 2025). Investment in plant & machinery / equipment and annual
/// turnover, both in ₹ crore. A unit must satisfy BOTH limits of a tier.
///
/// Single source of truth for the Udyam classifier sheet and the smart
/// assessment, so the two cannot drift apart again (see issue #124).
library;

enum MsmeTier { micro, small, medium, large }

class MsmeLimits {
  final double investmentCr;
  final double turnoverCr;
  const MsmeLimits(this.investmentCr, this.turnoverCr);
}

const MsmeLimits kMicroLimits = MsmeLimits(2.5, 10);
const MsmeLimits kSmallLimits = MsmeLimits(25, 100);
const MsmeLimits kMediumLimits = MsmeLimits(125, 500);

/// Classifies a unit. Both values must be >= 0 (callers validate input).
MsmeTier classifyMsme({
  required double investmentCr,
  required double turnoverCr,
}) {
  bool within(MsmeLimits l) =>
      investmentCr <= l.investmentCr && turnoverCr <= l.turnoverCr;
  if (within(kMicroLimits)) return MsmeTier.micro;
  if (within(kSmallLimits)) return MsmeTier.small;
  if (within(kMediumLimits)) return MsmeTier.medium;
  return MsmeTier.large;
}

/// `2.5` -> "2.5", `10.0` -> "10".
String formatCrore(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

/// Human-readable summary of the current limits, e.g. for the result footer.
String msmeLimitsSummary() =>
    'Limits (2025): Micro (≤${formatCrore(kMicroLimits.investmentCr)}cr / ≤${formatCrore(kMicroLimits.turnoverCr)}cr) | '
    'Small (≤${formatCrore(kSmallLimits.investmentCr)}cr / ≤${formatCrore(kSmallLimits.turnoverCr)}cr) | '
    'Medium (≤${formatCrore(kMediumLimits.investmentCr)}cr / ≤${formatCrore(kMediumLimits.turnoverCr)}cr)';
