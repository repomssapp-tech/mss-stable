import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/splash_screen.dart';

void main() {
  test(
    'signed-in users never return to Google login for incomplete profiles',
    () {
      expect(
        resolveStartupDestination(
          hasSession: true,
          hasCachedLanguage: true,
          profileCompleted: false,
        ),
        StartupDestination.navigationMode,
      );
    },
  );

  test('signed-in users with completed profiles continue to the app', () {
    expect(
      resolveStartupDestination(
        hasSession: true,
        hasCachedLanguage: true,
        profileCompleted: true,
      ),
      StartupDestination.home,
    );
  });

  test('signed-out users follow language then login onboarding', () {
    expect(
      resolveStartupDestination(
        hasSession: false,
        hasCachedLanguage: false,
        profileCompleted: false,
      ),
      StartupDestination.language,
    );
    expect(
      resolveStartupDestination(
        hasSession: false,
        hasCachedLanguage: true,
        profileCompleted: false,
      ),
      StartupDestination.login,
    );
  });
}
