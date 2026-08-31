import 'package:geocoding/geocoding.dart';

/// Structured result from parsing a geocoded Placemark into app form fields.
class ParsedAddress {
  final String doorStreet;
  final String area;
  final String district;
  final String state;
  final String pincode;

  const ParsedAddress({
    this.doorStreet = '',
    this.area = '',
    this.district = '',
    this.state = '',
    this.pincode = '',
  });

  @override
  String toString() =>
      'ParsedAddress(doorStreet: $doorStreet, area: $area, district: $district, state: $state, pincode: $pincode)';
}

/// Helper for robustly parsing reverse-geocoded Placemark data across India.
class LocationHelper {
  LocationHelper._();

  static String _clean(String? s) => (s ?? '').trim();

  static bool _isPlusCode(String s) =>
      s.contains('+') || RegExp(r'^[0-9A-Z]{4,8}\+[0-9A-Z]{2,4}$').hasMatch(s);

  /// Converts a [Placemark] into clean, unambiguous fields for the location profile form.
  static ParsedAddress parsePlacemark(Placemark place) {
    final subLocality = _clean(place.subLocality);
    final locality = _clean(place.locality);
    final subAdmin = _clean(place.subAdministrativeArea);
    final admin = _clean(place.administrativeArea);
    final postalCode = _clean(place.postalCode);
    final name = _clean(place.name);
    final street = _clean(place.thoroughfare ?? place.street);
    final subThoroughfare = _clean(place.subThoroughfare);

    // 1. Resolve Area / Locality:
    // If subLocality is present, it is the area.
    // If subLocality is empty, but locality is present (e.g. Kuthambakkam), locality is the area.
    // Otherwise fallback to name (if not a plus code).
    String resolvedArea = '';
    if (subLocality.isNotEmpty) {
      resolvedArea = subLocality;
    } else if (locality.isNotEmpty) {
      resolvedArea = locality;
    } else if (name.isNotEmpty && !_isPlusCode(name)) {
      resolvedArea = name;
    }

    // 2. Resolve City / District:
    // If subAdministrativeArea (District) is available, use it.
    // If locality is distinct from area, include/use locality.
    String resolvedDistrict = '';
    if (subAdmin.isNotEmpty) {
      if (locality.isNotEmpty && locality != subAdmin && locality != resolvedArea) {
        resolvedDistrict = '$locality, $subAdmin';
      } else {
        resolvedDistrict = subAdmin;
      }
    } else {
      if (locality.isNotEmpty && locality != resolvedArea) {
        resolvedDistrict = locality;
      }
    }

    // 3. Resolve Door No / Street:
    String resolvedDoorStreet = '';
    if (subThoroughfare.isNotEmpty && street.isNotEmpty) {
      resolvedDoorStreet = '$subThoroughfare, $street';
    } else if (street.isNotEmpty &&
        street != resolvedArea &&
        street != resolvedDistrict &&
        street != name) {
      resolvedDoorStreet = street;
    } else if (name.isNotEmpty &&
        name != resolvedArea &&
        name != resolvedDistrict &&
        name != locality &&
        !_isPlusCode(name)) {
      resolvedDoorStreet = name;
    }

    return ParsedAddress(
      doorStreet: resolvedDoorStreet,
      area: resolvedArea,
      district: resolvedDistrict,
      state: admin,
      pincode: postalCode,
    );
  }
}
