import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../l10n/l10n.dart';
import '../../../services/recommendation/indian_states.dart';
import '../../../utils/permission_helper.dart';
import '../../../widgets/common/app_toast.dart';

// Open Location Code ("plus code"), e.g. `22QV+VVC` or `7JWV22QV+VVC`: the
// geocoder returns one instead of a street name for places without one.
final RegExp _plusCode = RegExp(
  r'^[23456789CFGHJMPQRVWX]{2,8}\+[23456789CFGHJMPQRVWX]{0,3}$',
  caseSensitive: false,
);

/// The first of [values] that is not null or blank, or `''`. The geocoder
/// returns empty strings (not null) for parts it does not know.
String firstFilled(List<String?> values) {
  for (final value in values) {
    final text = (value ?? '').trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

/// A readable address from [place]: street parts, then the neighbourhood and
/// town, never a plus code, with repeated parts and the state/country left out.
String addressFromPlacemark(Placemark place) {
  final parts = <String>[];
  void add(String? raw) {
    for (final piece in (raw ?? '').split(',')) {
      final part = piece.trim();
      if (part.isEmpty || _plusCode.hasMatch(part)) continue;
      if (parts.any((p) => p.toLowerCase() == part.toLowerCase())) continue;
      parts.add(part);
    }
  }

  add(place.subThoroughfare);
  add(place.thoroughfare);
  if (parts.isEmpty) add(place.street);
  add(place.subLocality);
  if (parts.isEmpty) add(place.name);
  add(place.locality);
  return parts.join(', ');
}

/// Fetches the device's current location and reverse-geocodes it into
/// address/city/district/state, writing the result straight into the given
/// controllers. Used by Step 2 of [BasicProfileScreen]'s "use my location"
/// action. Mirrors the exact permission/service-check flow the screen
/// previously inlined; behavior is unchanged, only relocated.
Future<void> fetchAndGeocodeLocation({
  required BuildContext context,
  required TextEditingController addressController,
  required TextEditingController cityController,
  required TextEditingController districtController,
  required TextEditingController stateController,
  required TextEditingController pincodeController,
  required bool Function() isMounted,
  required void Function(bool loading) setLoading,
}) async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
  }

  if (permission == LocationPermission.deniedForever) {
    if (isMounted()) {
      // ignore: use_build_context_synchronously
      await showLocationServiceOffDialog(context);
    }
    return;
  }

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    if (isMounted()) {
      // ignore: use_build_context_synchronously
      await showLocationServiceOffDialog(context);
    }
    return;
  }

  setLoading(true);

  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;

      final address = addressFromPlacemark(place);
      if (address.isNotEmpty) addressController.text = address;

      cityController.text = firstFilled([place.locality, place.subLocality]);
      districtController.text = firstFilled([
        place.subAdministrativeArea,
        place.locality,
      ]);
      // The State field is a picker over English catalog names.
      stateController.text = IndianStates.canonical(
        place.administrativeArea ?? '',
      );
      final postal = (place.postalCode ?? '').replaceAll(RegExp(r'\D'), '');
      if (postal.length == 6) pincodeController.text = postal;
    }
  } catch (e) {
    if (isMounted()) {
      // ignore: use_build_context_synchronously
      AppToast.showError(context, context.l10n.profileErrLocationFetchFailed);
    }
  } finally {
    setLoading(false);
  }
}
