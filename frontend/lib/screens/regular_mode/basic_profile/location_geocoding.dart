import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/permission_helper.dart';
import '../../../widgets/common/app_toast.dart';

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

      final addressParts = <String>[];
      if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
        addressParts.add(place.subThoroughfare!);
      }
      if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
        addressParts.add(place.thoroughfare!);
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressParts.add(place.subLocality!);
      }
      if (addressParts.isNotEmpty) {
        addressController.text = addressParts.join(', ');
      } else if ((place.street ?? '').isNotEmpty) {
        addressController.text = place.street!;
      }

      cityController.text = place.locality ?? place.subLocality ?? '';
      districtController.text =
          place.subAdministrativeArea ?? place.locality ?? '';
      stateController.text = place.administrativeArea ?? '';
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
