// The permissions screen after sign-in: every row says why, "Allow all"
// asks for each missing permission, Continue / Not now always leaves, and
// the screen is shown once per install.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/screens/permissions/app_permissions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePlatform extends AppPermissionsPlatform {
  _FakePlatform({this.grantOnRequest = true});

  final bool grantOnRequest;
  final Set<AppPermission> granted = {};
  final List<AppPermission> requested = [];

  @override
  Future<bool> isGranted(AppPermission p) async => granted.contains(p);

  @override
  Future<bool> request(AppPermission p) async {
    requested.add(p);
    if (grantOnRequest) granted.add(p);
    return grantOnRequest;
  }
}

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  for (final code in ['en', 'ta', 'hi']) {
    testWidgets('Allow all asks for each permission, then Continue ($code)', (
      tester,
    ) async {
      final platform = _FakePlatform()..granted.add(AppPermission.microphone);
      var done = 0;
      await tester.pumpWidget(
        _app(
          AppPermissionsScreen(platform: platform, onDone: (_) => done++),
          locale: Locale(code),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(Locale(code));
      expect(find.text(l10n.permNotificationsTitle), findsOneWidget);
      expect(find.text(l10n.permInstallTitle), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(l10n.permAllowAll));
      await tester.pumpAndSettle();
      // The microphone was already allowed, so it is not asked again.
      expect(platform.requested, [
        AppPermission.notifications,
        AppPermission.installUpdates,
        AppPermission.photos,
      ]);
      await tester.tap(find.text(l10n.permContinue));
      expect(done, 1);
    });
  }

  testWidgets('Not now leaves without granting anything', (tester) async {
    final platform = _FakePlatform(grantOnRequest: false);
    var done = 0;
    await tester.pumpWidget(
      _app(AppPermissionsScreen(platform: platform, onDone: (_) => done++)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    expect(done, 1);
    expect(platform.requested, isEmpty);
  });

  test('the screen is shown once per install', () async {
    SharedPreferences.setMockInitialValues({});
    const store = AppPermissionsStore();
    expect(await store.isAsked(), isFalse);
    await store.markAsked();
    expect(await store.isAsked(), isTrue);
  });
}
