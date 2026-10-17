import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/services/beta_gate/beta_config.dart';
import 'package:frontend/services/beta_gate/beta_gate_service.dart';
import 'package:frontend/screens/beta_gate_screen.dart';

class FakeBetaGateService extends BetaGateService {
  final bool shouldSucceed;
  final bool shouldThrow;
  String? lastSubmittedPassword;

  FakeBetaGateService({
    this.shouldSucceed = true,
    this.shouldThrow = false,
  });

  @override
  Future<bool> verifyPassword(String userInput) async {
    lastSubmittedPassword = userInput;
    if (shouldThrow) {
      throw Exception('Network unreachable');
    }
    if (shouldSucceed && userInput == '300708') {
      await BetaGateService.setUnlocked(true, password: '300708');
      return true;
    }
    return false;
  }
}

Widget _buildTestApp({required Widget child}) {
  return ChangeNotifierProvider(
    create: (_) => AppProvider(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-publishable-key',
      );
    } catch (_) {}
  });

  group('BetaGateService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to locked state on fresh launch', () async {
      final isUnlocked = await BetaGateService.hasUnlockedBeta();
      expect(isUnlocked, isFalse);
    });

    test('setUnlocked updates local preference', () async {
      await BetaGateService.setUnlocked(true);
      expect(await BetaGateService.hasUnlockedBeta(), isTrue);

      await BetaGateService.setUnlocked(false);
      expect(await BetaGateService.hasUnlockedBeta(), isFalse);
    });

    test('resetBetaLock clears unlocked flag', () async {
      await BetaGateService.setUnlocked(true);
      expect(await BetaGateService.hasUnlockedBeta(), isTrue);

      await BetaGateService.resetBetaLock();
      expect(await BetaGateService.hasUnlockedBeta(), isFalse);
    });

    test('isBetaModeEnabled flag is false when disabled', () {
      expect(isBetaModeEnabled, isFalse);
    });
  });

  group('BetaGateScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders all required UI components', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: BetaGateScreen(
            service: FakeBetaGateService(),
          ),
        ),
      );

      expect(find.text('Beta Access'), findsOneWidget);
      expect(
        find.text('Enter the beta tester password to continue.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Verify & Enter'), findsOneWidget);
      expect(find.text('Authorized Beta Testers Only'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    });

    testWidgets('toggles password visibility when eye icon is tapped', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: BetaGateScreen(
            service: FakeBetaGateService(),
          ),
        ),
      );

      final textFieldFinder = find.byType(TextField);
      TextField textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.obscureText, isTrue);

      // Tap visibility toggle icon
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();

      textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.obscureText, isFalse);

      // Tap again to obscure
      await tester.tap(find.byIcon(Icons.visibility_off_rounded));
      await tester.pump();

      textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.obscureText, isTrue);
    });

    testWidgets('shows warning SnackBar when entering empty password', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: BetaGateScreen(
            service: FakeBetaGateService(),
          ),
        ),
      );

      await tester.tap(find.text('Verify & Enter'));
      await tester.pump();

      expect(find.text('Please enter the beta password.'), findsOneWidget);
    });

    testWidgets('shows error SnackBar when password is wrong', (tester) async {
      final fakeService = FakeBetaGateService(shouldSucceed: false);

      await tester.pumpWidget(
        _buildTestApp(
          child: BetaGateScreen(
            service: fakeService,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'wrongpass');
      await tester.tap(find.text('Verify & Enter'));
      await tester.pump(); // Start loading
      await tester.pump(const Duration(milliseconds: 100)); // Complete async

      expect(fakeService.lastSubmittedPassword, 'wrongpass');
      expect(find.text('Invalid beta password. Please try again.'), findsOneWidget);
    });

    testWidgets('persists unlock status upon correct password entry', (tester) async {
      final fakeService = FakeBetaGateService(shouldSucceed: true);

      await tester.pumpWidget(
        _buildTestApp(
          child: BetaGateScreen(
            service: fakeService,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '300708');
      await tester.tap(find.text('Verify & Enter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeService.lastSubmittedPassword, '300708');
      expect(await BetaGateService.hasUnlockedBeta(), isTrue);
    });
  });
}
