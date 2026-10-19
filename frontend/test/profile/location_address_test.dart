import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/regular_mode/basic_profile/location_geocoding.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  test('firstFilled skips null and blank values', () {
    expect(firstFilled([null, '', '  ', 'Chennai', 'Adyar']), 'Chennai');
    expect(firstFilled([null, '']), '');
  });

  group('addressFromPlacemark', () {
    test('a plus code is never used as the address', () {
      final address = addressFromPlacemark(
        const Placemark(
          street: '22QV+VVC',
          name: '22QV+VVC',
          subLocality: 'Kuthambakkam',
          locality: 'Chennai',
        ),
      );
      expect(address, 'Kuthambakkam, Chennai');
      expect(address, isNot(contains('+')));
    });

    test('a plus code in front of a street name is dropped', () {
      expect(
        addressFromPlacemark(
          const Placemark(street: '22QV+VVC, Poonamallee Road', locality: 'Chennai'),
        ),
        'Poonamallee Road, Chennai',
      );
    });

    test('street parts come first and repeats are removed', () {
      expect(
        addressFromPlacemark(
          const Placemark(
            subThoroughfare: '12',
            thoroughfare: 'Anna Salai',
            subLocality: 'Teynampet',
            locality: 'Teynampet',
          ),
        ),
        '12, Anna Salai, Teynampet',
      );
    });

    test('nothing usable gives an empty address', () {
      expect(addressFromPlacemark(const Placemark(name: '22QV+VVC')), '');
    });
  });
}
