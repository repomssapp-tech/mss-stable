import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../screens/regular_mode/basic_profile/location_geocoding.dart'
    show addressFromPlacemark, firstFilled;
import '../recommendation/indian_states.dart';
import 'location_lock.dart';

/// Why a location check did not produce a lock.
enum LocationCheckFailure {
  /// Location (GPS) is switched off on the phone.
  serviceOff,

  /// The user has not allowed location yet, or said no this time.
  permissionDenied,

  /// The user said "don't ask again": only system Settings can change it.
  permissionDeniedForever,

  /// "Approximate location" was allowed instead of "Precise".
  approximateOnly,

  /// The position came from a mock-location app (fake GPS).
  mockLocation,

  /// A VPN is connected.
  vpn,

  /// The position jumped further than anyone can travel since the last check.
  impossibleJump,

  /// The fix is not accurate enough to tell which state the phone is in.
  lowAccuracy,

  /// No fix came within the time limit.
  noFix,

  /// The position is outside India.
  outsideIndia,

  /// The address lookup failed (usually no internet on the first check).
  lookupFailed,
}

/// The result of [LocationLockService.verify]: a lock or a failure.
class LocationCheckResult {
  const LocationCheckResult.ok(LocationLock this.lock) : failure = null;
  const LocationCheckResult.failed(LocationCheckFailure this.failure)
    : lock = null;

  final LocationLock? lock;
  final LocationCheckFailure? failure;

  bool get isOk => lock != null;
}

/// Reads the phone's GPS, rejects anything faked (mock-location apps, VPNs,
/// teleport jumps, approximate location) and turns the fix into a
/// [LocationLock] for the state the phone is really in.
///
/// Nothing on the phone can make spoofing impossible (a rooted phone can hide
/// a mock app), but every signal Android and iOS expose is checked.
class LocationLockService {
  LocationLockService({
    FlutterSecureStorage? storage,
    Connectivity? connectivity,
    @visibleForTesting Future<List<String>> Function()? interfaceNames,
    @visibleForTesting DateTime Function()? clock,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _connectivity = connectivity ?? Connectivity(),
       _interfaceNames = interfaceNames ?? _systemInterfaceNames,
       _clock = clock ?? DateTime.now;

  static final LocationLockService instance = LocationLockService();

  static const String _storageKey = 'mss_location_lock_v1';

  /// A fix less accurate than this cannot place the phone in a state.
  static const double maxAccuracyMeters = 1000;

  /// Faster than this between two checks is a fake jump (a fast train or a
  /// flight still clears it; Pokemon-Go style teleports do not).
  static const double maxSpeedKmh = 900;

  final FlutterSecureStorage _storage;
  final Connectivity _connectivity;
  final Future<List<String>> Function() _interfaceNames;
  final DateTime Function() _clock;

  /// Loads the last lock into [LocationScope.current]. Returns it.
  Future<LocationLock?> restore() async {
    try {
      final lock = LocationLock.decode(await _storage.read(key: _storageKey));
      LocationScope.current.value = lock;
      return lock;
    } catch (e) {
      debugPrint('[LocationLock] restore failed: $e');
      return null;
    }
  }

  /// Runs every check and, on success, stores the new lock and publishes it
  /// in [LocationScope.current]. [requestPermission] false only checks, so a
  /// background re-check never pops a permission prompt.
  Future<LocationCheckResult> verify({bool requestPermission = true}) async {
    final previous = LocationScope.current.value;

    if (await _vpnConnected()) {
      return const LocationCheckResult.failed(LocationCheckFailure.vpn);
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationCheckResult.failed(LocationCheckFailure.serviceOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationCheckResult.failed(
        LocationCheckFailure.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      return const LocationCheckResult.failed(
        LocationCheckFailure.permissionDenied,
      );
    }
    if (await Geolocator.getLocationAccuracy() ==
        LocationAccuracyStatus.reduced) {
      return const LocationCheckResult.failed(
        LocationCheckFailure.approximateOnly,
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 25),
      );
    } catch (e) {
      debugPrint('[LocationLock] no fix: $e');
      return const LocationCheckResult.failed(LocationCheckFailure.noFix);
    }

    final failure = assessPosition(position, previous: previous, now: _clock());
    if (failure != null) return LocationCheckResult.failed(failure);

    final lock = await _lookUp(position, previous);
    if (lock == null) {
      return const LocationCheckResult.failed(
        LocationCheckFailure.lookupFailed,
      );
    }
    if (lock.stateCode.isEmpty) {
      return const LocationCheckResult.failed(
        LocationCheckFailure.outsideIndia,
      );
    }

    try {
      await _storage.write(key: _storageKey, value: lock.encode());
    } catch (e) {
      debugPrint('[LocationLock] lock not saved: $e');
    }
    LocationScope.current.value = lock;
    return LocationCheckResult.ok(lock);
  }

  /// The checks that need only the fix itself: mock flag, accuracy and a
  /// speed check against [previous]. Null when the fix passes.
  @visibleForTesting
  static LocationCheckFailure? assessPosition(
    Position position, {
    LocationLock? previous,
    required DateTime now,
  }) {
    if (position.isMocked) return LocationCheckFailure.mockLocation;
    if (position.accuracy <= 0 || position.accuracy > maxAccuracyMeters) {
      return LocationCheckFailure.lowAccuracy;
    }
    if (previous != null) {
      final km =
          Geolocator.distanceBetween(
            previous.latitude,
            previous.longitude,
            position.latitude,
            position.longitude,
          ) /
          1000;
      final hours =
          now.difference(previous.verifiedAt).inSeconds.abs() / 3600.0;
      // Under 50 km is GPS drift or a short trip, whatever the time gap.
      if (km > 50 && km / (hours < 0.01 ? 0.01 : hours) > maxSpeedKmh) {
        return LocationCheckFailure.impossibleJump;
      }
    }
    return null;
  }

  /// Reverse-geocodes [position]. A lock with an empty state code means the
  /// fix is outside India. Offline, a fix within 25 km of [previous] keeps
  /// the previous state; otherwise null.
  Future<LocationLock?> _lookUp(Position position, LocationLock? previous) {
    return _geocode(position).then(
      (place) {
        final now = _clock();
        final country = (place.isoCountryCode ?? '').toUpperCase();
        final code = IndianStates.code(place.administrativeArea ?? '');
        if (country != 'IN' || code == null) {
          return LocationLock(
            stateCode: '',
            latitude: position.latitude,
            longitude: position.longitude,
            verifiedAt: now,
          );
        }
        final postal = (place.postalCode ?? '').replaceAll(RegExp(r'\D'), '');
        return LocationLock(
          stateCode: code,
          latitude: position.latitude,
          longitude: position.longitude,
          verifiedAt: now,
          address: addressFromPlacemark(place),
          city: firstFilled([place.locality, place.subLocality]),
          district: firstFilled([place.subAdministrativeArea, place.locality]),
          pincode: postal.length == 6 ? postal : '',
        );
      },
      onError: (Object e) {
        debugPrint('[LocationLock] address lookup failed: $e');
        if (previous == null) return null;
        final km =
            Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              position.latitude,
              position.longitude,
            ) /
            1000;
        if (km > 25) return null;
        return LocationLock(
          stateCode: previous.stateCode,
          latitude: position.latitude,
          longitude: position.longitude,
          verifiedAt: _clock(),
          address: previous.address,
          city: previous.city,
          district: previous.district,
          pincode: previous.pincode,
        );
      },
    );
  }

  static Future<Placemark> _geocode(Position position) async {
    final places = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    ).timeout(const Duration(seconds: 12));
    if (places.isEmpty) throw StateError('no placemark');
    return places.first;
  }

  Future<bool> _vpnConnected() async {
    try {
      final kinds = await _connectivity.checkConnectivity();
      if (kinds.contains(ConnectivityResult.vpn)) return true;
    } catch (e) {
      debugPrint('[LocationLock] connectivity check failed: $e');
    }
    try {
      return (await _interfaceNames()).any(looksLikeVpnInterface);
    } catch (e) {
      debugPrint('[LocationLock] interface check failed: $e');
      return false;
    }
  }

  static final RegExp _vpnInterface = RegExp(
    r'^(tun|tap|ppp|pptp|l2tp|ipsec|wg|utun|nordlynx|proton|zt)\d*',
    caseSensitive: false,
  );

  /// Whether a network interface name is a VPN tunnel (`tun0`, `wg0`, ...).
  @visibleForTesting
  static bool looksLikeVpnInterface(String name) =>
      _vpnInterface.hasMatch(name.trim());

  static Future<List<String>> _systemInterfaceNames() async {
    // iOS always has utun interfaces for system services, so the tunnel
    // names only mean a VPN on Android; iOS relies on the connectivity check.
    if (kIsWeb || !Platform.isAndroid) return const [];
    final list = await NetworkInterface.list(includeLoopback: false);
    return [for (final i in list) i.name];
  }
}
