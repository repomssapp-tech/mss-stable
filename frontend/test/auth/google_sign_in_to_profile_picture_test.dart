// The whole path of a Google sign-in to the picture on the profile, with a fake
// backend: the one-time code from the redirect is exchanged, the session is
// restored the way a cold start restores it, and the profile screen shows the
// Google picture, the name initial, or a custom photo as it should.
//
// The Google account page itself (the browser) cannot be driven from a test;
// everything after the redirect is.
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/services/account/app_session.dart';
import 'package:frontend/services/account/rest_auth_service.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/widgets/common/name_initial_avatar.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _googlePicture = 'https://lh3.googleusercontent.com/a/real-photo=s96-c';

/// Runs the part of a sign-in that follows the redirect: exchange a code with
/// a backend that answers with [pictureUrl], then restore the session from
/// storage as app start does.
Future<AuthUser> _signIn({String? pictureUrl}) async {
  await TokenStorage.instance.savePkceVerifier(
    'verifier_1234567890123456789012345678901234567890',
  );
  final backend = MockClient((request) async {
    expect(request.url.path, '/v1/auth/exchange');
    return http.Response(
      jsonEncode({
        'access_token': 'access',
        'refresh_token': 'refresh',
        'token_type': 'Bearer',
        'expires_in': 900,
        'user': {
          'id': 'user-1',
          'email': 'roger@example.com',
          'name': 'Roger Christopher',
          'picture_url': pictureUrl,
        },
      }),
      200,
    );
  });
  final service = RestAuthService(
    apiClient: ApiClient(
      baseUrl: 'https://mssapi.msmeschemes.org/v1',
      httpClient: backend,
    ),
  );
  final user = await service.exchangeCode('one_time_code');
  await AppSession.instance.hydrate(storage: TokenStorage.instance);
  return user;
}

Widget _profileApp(AppProvider provider) =>
    ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('hi'), Locale('ta')],
        home: ProfileScreen(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSession.instance.resetForTest();
  });

  test(
    'the Google picture survives the code exchange and a session restore',
    () async {
      final user = await _signIn(pictureUrl: _googlePicture);
      expect(user.pictureUrl, _googlePicture);

      // A cold start: the user comes back from storage, not from the exchange.
      expect(AppSession.instance.isSignedIn, isTrue);
      expect(AppSession.instance.currentUser?.pictureUrl, _googlePicture);
      expect(AppProvider().effectiveProfilePhoto, _googlePicture);
    },
  );

  test("Google's generated default avatar is not shown as a photo", () async {
    await _signIn(
      pictureUrl: 'https://lh3.googleusercontent.com/a/default-user=s96-c',
    );
    expect(AppProvider().effectiveProfilePhoto, isEmpty);
  });

  test('an account with no picture falls back to the name initial', () async {
    await _signIn(pictureUrl: null);
    expect(AppProvider().effectiveProfilePhoto, isEmpty);
  });

  test('a picture over plain http is not loaded', () async {
    await _signIn(pictureUrl: 'http://lh3.googleusercontent.com/a/photo');
    expect(AppProvider().effectiveProfilePhoto, isEmpty);
  });

  testWidgets('the profile screen shows the Google picture after sign-in', (
    tester,
  ) async {
    await _signIn(pictureUrl: _googlePicture);
    final provider = AppProvider();
    await tester.pumpWidget(_profileApp(provider));
    await tester.pump();

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, _googlePicture);
    // While it loads, and if it fails, the name initial shows, never a blank.
    expect(image.placeholder, isNotNull);
    expect(image.errorWidget, isNotNull);

    // A signed-in provider starts timers; stop them so the test can end.
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });

  testWidgets('the profile screen shows the initial when there is no picture', (
    tester,
  ) async {
    await _signIn(pictureUrl: null);
    final provider = AppProvider();
    await tester.pumpWidget(_profileApp(provider));
    await tester.pump();

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byType(NameInitialAvatar), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });
}
