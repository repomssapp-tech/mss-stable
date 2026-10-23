import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/updates/app_release.dart';
import 'package:frontend/services/updates/app_update_service.dart';
import 'package:frontend/utils/app_version.dart';
import 'package:frontend/widgets/common/app_update_prompt.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _apk = Uri.parse(
  'https://github.com/Roger-Chris/MSS_App/releases/download/app-v1.4.9%2B17/MSS-1.4.9+17.apk',
);

final _release = AppRelease(
  version: const AppVersion(1, 4, 9, 17),
  pageUrl: Uri.parse(
    'https://github.com/Roger-Chris/MSS_App/releases/tag/app-v1.4.9%2B17',
  ),
  apkUrl: _apk,
);

AppUpdateService _service({void Function()? onRequest}) => AppUpdateService(
  client: MockClient((_) async {
    onRequest?.call();
    return http.Response(
      jsonEncode([
        {
          'tag_name': 'app-v1.4.9+17',
          'html_url': _release.pageUrl.toString(),
          'draft': false,
          'prerelease': false,
          'assets': [
            {'name': 'MSS-1.4.9+17.apk', 'browser_download_url': '$_apk'},
          ],
        },
      ]),
      200,
    );
  }),
  installedVersion: () async => const AppVersion(1, 4, 8, 16),
);

Widget _app(
  String lang, {
  Widget? child,
  void Function(BuildContext)? onBuild,
}) => MaterialApp(
  locale: Locale(lang),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) {
      onBuild?.call(context);
      return Scaffold(body: child ?? const SizedBox.shrink());
    },
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppUpdateWatcher.resetForTest();
  });

  for (final lang in ['en', 'hi', 'ta']) {
    group('update notice ($lang)', () {
      final l10n = lookupAppLocalizations(Locale(lang));

      Future<BuildContext> pumpHost(WidgetTester tester) async {
        late BuildContext host;
        await tester.pumpWidget(_app(lang, onBuild: (c) => host = c));
        return host;
      }

      testWidgets('shows the localized notice; Later remembers the build', (
        tester,
      ) async {
        final opened = <Uri>[];
        final host = await pumpHost(tester);
        unawaited(
          showAppUpdateNotice(
            host,
            release: _release,
            service: _service(),
            open: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.updateAvailableTitle), findsOneWidget);
        expect(find.text(l10n.updateAvailableMessage('1.4.9')), findsOneWidget);
        expect(find.text(l10n.updateActionUpdate), findsOneWidget);
        expect(find.text(l10n.updateActionLater), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text(l10n.updateActionLater));
        await tester.pumpAndSettle();

        expect(find.text(l10n.updateAvailableTitle), findsNothing);
        expect(opened, isEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(AppUpdateService.dismissedBuildKey), 17);
      });

      testWidgets('Update opens the APK and does not dismiss the build', (
        tester,
      ) async {
        final opened = <Uri>[];
        final host = await pumpHost(tester);
        unawaited(
          showAppUpdateNotice(
            host,
            release: _release,
            service: _service(),
            open: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(l10n.updateActionUpdate));
        await tester.pumpAndSettle();

        expect(opened, [_apk]);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(AppUpdateService.dismissedBuildKey), isNull);
      });

      testWidgets('a link that cannot be opened shows a localized error', (
        tester,
      ) async {
        final host = await pumpHost(tester);
        unawaited(
          openUpdateLink(
            host,
            AppUpdateService.latestReleasePage,
            open: (_) async => false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(l10n.updateOpenFailed), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      });
    });
  }

  testWidgets('AppUpdateWatcher offers a newer build once per app session', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    var requests = 0;
    final service = _service(onRequest: () => requests++);

    await tester.pumpWidget(
      _app(
        'en',
        child: AppUpdateWatcher(
          service: service,
          open: (_) async => true,
          child: const Text('shell'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('shell'), findsOneWidget);
    expect(find.text(l10n.updateAvailableTitle), findsOneWidget);
    expect(requests, 1);

    await tester.tap(find.text(l10n.updateActionUpdate));
    await tester.pumpAndSettle();

    // A resume in the same session does not offer it again.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(l10n.updateAvailableTitle), findsNothing);
  });

  testWidgets('AppUpdateWatcher stays silent when the check fails', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final service = AppUpdateService(
      client: MockClient((_) async => http.Response('', 403)),
      installedVersion: () async => const AppVersion(1, 4, 8, 16),
    );
    await tester.pumpWidget(
      _app(
        'en',
        child: AppUpdateWatcher(service: service, child: const Text('shell')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('shell'), findsOneWidget);
    expect(find.text(l10n.updateAvailableTitle), findsNothing);
  });
}
