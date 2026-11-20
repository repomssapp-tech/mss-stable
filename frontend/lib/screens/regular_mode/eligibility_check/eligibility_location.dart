import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/account/eligibility_answers_store.dart';

/// Where the phone is, and the place name geocoding gave for it.
class DetectedPlace {
  const DetectedPlace({
    required this.location,
    required this.state,
    required this.district,
    this.city = '',
  });
  final QuestionnaireLocation location;
  final String state;
  final String district;
  final String city;
}

/// Asks for the location permission if needed, reads the position and looks up
/// the state and district. Null when the user said no, location is off, or
/// anything failed (the caller then asks the user to type the place).
Future<DetectedPlace?> detectPlace() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final p = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 8),
    );
    final location = QuestionnaireLocation(
      p.latitude,
      p.longitude,
      p.accuracy.round(),
    );
    var state = '';
    var district = '';
    var city = '';
    try {
      final marks = await placemarkFromCoordinates(p.latitude, p.longitude);
      if (marks.isNotEmpty) {
        final m = marks.first;
        state = (m.administrativeArea ?? '').trim();
        district = (m.subAdministrativeArea ?? m.locality ?? '')
            .replaceAll(RegExp(r' District$', caseSensitive: false), '')
            .trim();
        city = (m.locality ?? '').trim();
      }
    } catch (e) {
      // The coordinates are still useful; the user types the place.
      debugPrint('[EligibilityLocation] geocoding failed: $e');
    }
    return DetectedPlace(
      location: location,
      state: state,
      district: district,
      city: city,
    );
  } catch (e) {
    debugPrint('[EligibilityLocation] failed: $e');
    return null;
  }
}
