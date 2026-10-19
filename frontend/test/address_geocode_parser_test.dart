import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:frontend/utils/location_helper.dart';

void main() {
  group('LocationHelper.parsePlacemark Address Geocode Parser Tests', () {
    test(
      'Correctly places Kuthambakkam into Area/Locality instead of District',
      () {
        final placemark = Placemark(
          name: 'Kuthambakkam',
          subLocality: '',
          locality: 'Kuthambakkam',
          subAdministrativeArea: 'Tiruvallur',
          administrativeArea: 'Tamil Nadu',
          postalCode: '600124',
        );

        final parsed = LocationHelper.parsePlacemark(placemark);

        expect(parsed.area, 'Kuthambakkam');
        expect(parsed.district, 'Tiruvallur');
        expect(parsed.state, 'Tamil Nadu');
        expect(parsed.pincode, '600124');
      },
    );

    test(
      'When subAdministrativeArea is empty, locality becomes Area and does not duplicate to District',
      () {
        final placemark = Placemark(
          name: 'Kuthambakkam',
          subLocality: '',
          locality: 'Kuthambakkam',
          subAdministrativeArea: '',
          administrativeArea: 'Tamil Nadu',
          postalCode: '600124',
        );

        final parsed = LocationHelper.parsePlacemark(placemark);

        expect(parsed.area, 'Kuthambakkam');
        expect(parsed.district, isNot('Kuthambakkam'));
        expect(parsed.state, 'Tamil Nadu');
        expect(parsed.pincode, '600124');
      },
    );

    test(
      'Metro area with distinct SubLocality (Anna Nagar) and Locality (Chennai)',
      () {
        final placemark = Placemark(
          name: '12',
          street: '2nd Avenue',
          subThoroughfare: '12',
          thoroughfare: '2nd Avenue',
          subLocality: 'Anna Nagar West',
          locality: 'Chennai',
          subAdministrativeArea: 'Chennai',
          administrativeArea: 'Tamil Nadu',
          postalCode: '600040',
        );

        final parsed = LocationHelper.parsePlacemark(placemark);

        expect(parsed.doorStreet, '12, 2nd Avenue');
        expect(parsed.area, 'Anna Nagar West');
        expect(parsed.district, 'Chennai');
        expect(parsed.state, 'Tamil Nadu');
        expect(parsed.pincode, '600040');
      },
    );

    test('SubLocality + Locality + District are all distinct', () {
      final placemark = Placemark(
        subLocality: 'Madipakkam',
        locality: 'Chennai',
        subAdministrativeArea: 'Chengalpattu',
        administrativeArea: 'Tamil Nadu',
        postalCode: '600091',
      );

      final parsed = LocationHelper.parsePlacemark(placemark);

      expect(parsed.area, 'Madipakkam');
      expect(parsed.district, 'Chennai, Chengalpattu');
      expect(parsed.state, 'Tamil Nadu');
      expect(parsed.pincode, '600091');
    });

    test('Handles nulls and plus codes gracefully without crashing', () {
      final placemark = Placemark(
        name: '7M52+XX',
        subLocality: null,
        locality: null,
        subAdministrativeArea: null,
        administrativeArea: 'Karnataka',
        postalCode: '560001',
      );

      final parsed = LocationHelper.parsePlacemark(placemark);

      expect(parsed.area, '');
      expect(parsed.district, '');
      expect(parsed.state, 'Karnataka');
      expect(parsed.pincode, '560001');
    });
  });
}
