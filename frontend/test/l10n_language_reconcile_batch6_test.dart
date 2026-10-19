// WS1 Batch 6 — AppProvider guards an explicit language switch against a
// stale server profile row / realtime echo carrying the old language.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/providers/app_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'a stale server value that contradicts the explicit choice is ignored',
    () {
      final p = AppProvider();
      p.debugMarkLanguagePending('ta');

      // Realtime echo still shows the pre-switch language -> keep the choice.
      expect(p.debugReconcileServerLanguage('en'), 'ta');
      expect(p.debugReconcileServerLanguage('en'), 'ta');
    },
  );

  test(
    'once the server confirms the new value, later server values are trusted',
    () {
      final p = AppProvider();
      p.debugMarkLanguagePending('ta');

      // Server catches up -> pending clears.
      expect(p.debugReconcileServerLanguage('ta'), 'ta');

      // A subsequent genuine change on another device now applies.
      expect(p.debugReconcileServerLanguage('en'), 'en');
    },
  );

  test('with no explicit pending switch the server value passes through', () {
    final p = AppProvider();
    expect(p.debugReconcileServerLanguage('ta'), 'ta');
    expect(p.debugReconcileServerLanguage('en'), 'en');
  });
}
