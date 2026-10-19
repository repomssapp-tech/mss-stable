import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/regular_mode/basic_profile/step2_location_form.dart';

/// The server only completes onboarding with a six-digit pincode, so the
/// location step must not let an empty or malformed one through.
void main() {
  test('only exactly six digits are a valid pincode', () {
    expect(Step2LocationForm.isValidPincode('600001'), isTrue);
    expect(Step2LocationForm.isValidPincode(' 600001 '), isTrue);
    expect(Step2LocationForm.isValidPincode(''), isFalse);
    expect(Step2LocationForm.isValidPincode('60001'), isFalse);
    expect(Step2LocationForm.isValidPincode('6000011'), isFalse);
    expect(Step2LocationForm.isValidPincode('60000a'), isFalse);
  });
}
