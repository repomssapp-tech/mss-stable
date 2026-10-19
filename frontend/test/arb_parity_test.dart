import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String value) =>
    RegExp(r'\{(\w+)').allMatches(value).map((m) => m.group(1)!).toSet();

void main() {
  final en = _load('en');
  final ta = _load('ta');
  final hi = _load('hi');

  test('en, ta and hi define exactly the same message keys', () {
    expect(_keys(ta).difference(_keys(en)), isEmpty, reason: 'extra in ta');
    expect(_keys(hi).difference(_keys(en)), isEmpty, reason: 'extra in hi');
    expect(_keys(en).difference(_keys(ta)), isEmpty, reason: 'missing in ta');
    expect(_keys(en).difference(_keys(hi)), isEmpty, reason: 'missing in hi');
  });

  test('ta and hi keep the same interpolation placeholders as en', () {
    final mismatches = <String>[];
    for (final key in _keys(en)) {
      final expected = _placeholders(en[key] as String);
      for (final entry in {'ta': ta, 'hi': hi}.entries) {
        final actual = _placeholders(entry.value[key] as String);
        if (!expected.containsAll(actual) || !actual.containsAll(expected)) {
          mismatches.add('${entry.key}:$key');
        }
      }
    }
    expect(mismatches, isEmpty);
  });

  test('no ta or hi value is empty', () {
    for (final entry in {'ta': ta, 'hi': hi}.entries) {
      final empty = _keys(
        en,
      ).where((k) => (entry.value[k] as String).trim().isEmpty).toList();
      expect(empty, isEmpty, reason: '${entry.key} has empty values');
    }
  });

  test('Hindi UI strings added for the localization sprint use Devanagari', () {
    const sprintKeys = [
      'hintAgeExample',
      'hintAddressExample',
      'hintCityExample',
      'legalPrivacyNoticeLink',
      'legalTermsOfUseLink',
      'shareSchemeDetailsTooltip',
      'legalConsentPrefix',
      'legalConsentMid',
      'legalConsentSuffix',
    ];
    final devanagari = RegExp(r'[ऀ-ॿ]');
    final tamil = RegExp(r'[஀-௿]');
    for (final key in sprintKeys) {
      expect(hi[key], matches(devanagari), reason: 'hi:$key');
      expect(ta[key], matches(tamil), reason: 'ta:$key');
    }
  });
}
