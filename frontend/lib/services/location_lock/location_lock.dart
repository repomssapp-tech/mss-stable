import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../config/edition.dart';
import '../../models/scheme_filter.dart';
import '../../models/scheme_model.dart';
import '../recommendation/indian_states.dart';
import 'location_lock_config.dart';

/// Where the phone's GPS put the user at the last successful check, and the
/// address the reverse geocoder gave for it. The app's schemes, state lists,
/// languages and profile state are all tied to [stateCode].
@immutable
class LocationLock {
  const LocationLock({
    required this.stateCode,
    required this.latitude,
    required this.longitude,
    required this.verifiedAt,
    this.address = '',
    this.city = '',
    this.district = '',
    this.pincode = '',
  });

  /// ISO 3166-2 code, e.g. `IN-MH`.
  final String stateCode;
  final double latitude;
  final double longitude;
  final DateTime verifiedAt;
  final String address;
  final String city;
  final String district;
  final String pincode;

  /// English catalog name, e.g. "Maharashtra".
  String get stateName => IndianStates.nameForCode(stateCode) ?? stateCode;

  Map<String, dynamic> toJson() => {
    'stateCode': stateCode,
    'lat': latitude,
    'lng': longitude,
    'verifiedAt': verifiedAt.toUtc().toIso8601String(),
    'address': address,
    'city': city,
    'district': district,
    'pincode': pincode,
  };

  static LocationLock? fromJson(Object? json) {
    if (json is! Map) return null;
    final code = json['stateCode'];
    final lat = json['lat'];
    final lng = json['lng'];
    final at = DateTime.tryParse('${json['verifiedAt']}');
    if (code is! String || lat is! num || lng is! num || at == null) {
      return null;
    }
    if (IndianStates.nameForCode(code) == null) return null;
    return LocationLock(
      stateCode: code,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      verifiedAt: at,
      address: '${json['address'] ?? ''}',
      city: '${json['city'] ?? ''}',
      district: '${json['district'] ?? ''}',
      pincode: '${json['pincode'] ?? ''}',
    );
  }

  String encode() => jsonEncode(toJson());

  static LocationLock? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }
}

/// The app-wide view of the current lock. Everything that filters by state
/// reads it from here, so tests can set it without GPS.
class LocationScope {
  LocationScope._();

  /// The verified lock, or null before the first check (or when the lock is
  /// off in this build).
  static final ValueNotifier<LocationLock?> current = ValueNotifier(null);

  /// Whether filtering applies right now: the GPS lock (dev build) or a
  /// state edition (Tamil Nadu, Maharashtra).
  static bool get active =>
      (debugEnabledOverride ?? (kLocationLockEnabled || kEditionHasState)) &&
      current.value != null;

  /// A state edition is tied to its state from the first frame, with no GPS
  /// check: the state is fixed in [current] and never changes. Does nothing
  /// in the Central edition. Call before the app provider is created.
  static void applyEdition([EditionConfig edition = kEdition]) {
    final code = edition.stateCode;
    if (code == null) return;
    current.value = LocationLock(
      stateCode: code,
      latitude: 0,
      longitude: 0,
      verifiedAt: DateTime.now(),
    );
  }

  /// Tests turn the lock on without a `--dart-define`.
  @visibleForTesting
  static bool? debugEnabledOverride;

  /// The locked state's English name, or null when not [active].
  static String? get stateName => active ? current.value!.stateName : null;

  /// Languages offered in [stateCode], primary first. English is always the
  /// primary language; the state's own language (and Hindi in Hindi-using
  /// states) come after it.
  static List<String> languagesForState(String stateCode) =>
      switch (stateCode) {
        'IN-MH' => const ['en', 'hi', 'mr'],
        'IN-TN' || 'IN-PY' => const ['en', 'ta'],
        _ => const ['en', 'hi'],
      };

  /// The languages the user may pick now; null when the lock is not active
  /// (every app language is allowed).
  static List<String>? get allowedLanguages =>
      active ? languagesForState(current.value!.stateCode) : null;

  /// [lang] when the lock allows it, otherwise English.
  static String clampLanguage(String lang) {
    final allowed = allowedLanguages;
    if (allowed == null || allowed.contains(lang)) return lang;
    return 'en';
  }

  /// Central (nationwide) schemes and the locked state's own schemes.
  /// A scheme limited to other states, or whose coverage is unknown, is
  /// left out.
  static bool allowsScheme(Scheme s) {
    final state = stateName;
    if (state == null) return true;
    return schemeAppliesInState(s, state);
  }

  /// [states] (English names) cut down to the locked state; unchanged when
  /// not [active].
  static List<String> restrictStates(List<String> states) {
    final state = stateName;
    if (state == null) return states;
    final code = current.value!.stateCode;
    final kept = [
      for (final s in states)
        if (IndianStates.code(s) == code) s,
    ];
    return kept.isEmpty ? [state] : kept;
  }
}
