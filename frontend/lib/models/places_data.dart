import 'dart:convert';

import 'package:flutter/services.dart';

/// States, districts, talukas and cities of India (assets/questionnaire/places.json) from the
/// Local Government Directory (LGD), Government of India, snapshot 2026-11-19 (built by
/// repo-web-new/tools/build_places.py). Place names are in English.
class PlacesData {
  const PlacesData(this._states);
  final Map<String, dynamic> _states;

  static const empty = PlacesData({});

  factory PlacesData.parse(String source) => PlacesData(
    (jsonDecode(source) as Map<String, dynamic>)['states']
        as Map<String, dynamic>,
  );

  static Future<PlacesData> load([AssetBundle? bundle]) async {
    try {
      return PlacesData.parse(
        await (bundle ?? rootBundle).loadString(
          'assets/questionnaire/places.json',
        ),
      );
    } catch (_) {
      return empty;
    }
  }

  List<dynamic> _districts(String? stateKey) =>
      (_states[stateKey]?['districts'] as List?) ?? const [];

  List<String> districts(String? stateKey) => [
    for (final d in _districts(stateKey)) (d as Map)['name'] as String,
  ];

  List<String> talukas(String? stateKey, String? district) {
    final want = (district ?? '').trim().toLowerCase();
    for (final d in _districts(stateKey)) {
      final m = d as Map;
      if ((m['name'] as String).toLowerCase() == want) {
        return [for (final t in (m['talukas'] as List)) t as String];
      }
    }
    return const [];
  }

  List<String> cities(String? stateKey) => [
    for (final c in (_states[stateKey]?['cities'] as List?) ?? const [])
      c as String,
  ];

  /// The list's spelling of [name], or null.
  static String? match(List<String> list, String? name) {
    final want = (name ?? '').trim().toLowerCase();
    if (want.isEmpty) return null;
    for (final x in list) {
      if (x.toLowerCase() == want) return x;
    }
    return null;
  }
}
