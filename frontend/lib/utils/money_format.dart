import 'package:intl/intl.dart';

/// Formats a rupee amount with Indian digit grouping (spec_phase3.md §0.2,
/// D4). Example: `formatInr(1234567.891)` -> `"₹ 12,34,567.89"`.
String formatInr(num v, {int decimals = 2}) => NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹ ',
  decimalDigits: decimals,
).format(v);
