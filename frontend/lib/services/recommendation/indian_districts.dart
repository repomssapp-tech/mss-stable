import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'indian_states.dart';

/// Official district list per state / union territory, from the Government of
/// India Local Government Directory (LGD), bundled in
/// `assets/data/districts_lgd.json` (issue #145 item 2.1: District used to be
/// free text). Keyed by the ISO state codes [IndianStates] uses (`IN-TN`).
class IndianDistricts {
  IndianDistricts._();

  static const String assetPath = 'assets/data/districts_lgd.json';

  static Future<Map<String, List<String>>>? _loading;

  @visibleForTesting
  static void resetForTest() => _loading = null;

  static Future<Map<String, List<String>>> _load() => _loading ??= () async {
    try {
      final raw = jsonDecode(await rootBundle.loadString(assetPath));
      final states = (raw is Map ? raw['states'] : null);
      if (states is! Map) return const <String, List<String>>{};
      return {
        for (final e in states.entries)
          if (e.value is List)
            e.key.toString(): [
              for (final d in e.value as List)
                if (d is Map && d['name'] is String) d['name'] as String,
            ],
      };
    } catch (e) {
      debugPrint('[IndianDistricts] could not load $assetPath: $e');
      return const <String, List<String>>{};
    }
  }();

  /// Districts of [state] (a name in any supported language, or a code such
  /// as `tn` / `IN-TN`), alphabetical. Empty when the state is unknown.
  static Future<List<String>> forState(String state) async {
    final code = IndianStates.code(state);
    if (code == null) return const [];
    return (await _load())[code] ?? const [];
  }

  /// True when [district] is one of [state]'s districts (case-insensitive).
  static Future<bool> isDistrictOf(String district, String state) async {
    final d = district.trim().toLowerCase();
    if (d.isEmpty) return false;
    return (await forState(state)).any((x) => x.toLowerCase() == d);
  }
}
