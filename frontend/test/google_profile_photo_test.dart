import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/services/account/google_identity.dart';
import 'package:frontend/services/account/rest_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/widgets/common/name_initial_avatar.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Google Profile Photo Extraction & Precedence', () {
    test('extractGooglePhoto returns the account picture, trimmed', () {
      const withPicture = AuthUser(
        id: 'u1',
        email: 'a@example.com',
        name: 'Praveen Kanna',
        pictureUrl: ' https://lh3.googleusercontent.com/avatar1 ',
      );
      expect(
        extractGooglePhoto(withPicture),
        'https://lh3.googleusercontent.com/avatar1',
      );

      const withoutPicture = AuthUser(
        id: 'u2',
        email: 'b@example.com',
        name: 'B',
      );
      expect(extractGooglePhoto(withoutPicture), isEmpty);
      expect(extractGooglePhoto(null), isEmpty);
    });

    test('extractGoogleName returns the account name, trimmed', () {
      const user = AuthUser(
        id: 'u1',
        email: 'a@example.com',
        name: '  Praveen Kanna ',
      );
      expect(extractGoogleName(user), 'Praveen Kanna');
      expect(extractGoogleName(null), isEmpty);
    });

    test('effectiveProfilePhoto and hasCustomPhoto behavior', () async {
      final provider = AppProvider();

      // Case 1: Initial empty profile
      expect(provider.hasCustomPhoto, isFalse);

      // Case 2: Custom file photo
      final tempFile = File('${Directory.systemTemp.path}/test_avatar.jpg');
      await tempFile.writeAsString('fake_image_content');
      addTearDown(() async {
        if (await tempFile.exists()) await tempFile.delete();
      });

      await provider.updateProfilePhoto(tempFile.path);
      expect(provider.profile.profilePhoto, tempFile.path);
      expect(provider.effectiveProfilePhoto, tempFile.path);
      expect(provider.hasCustomPhoto, isTrue);

      // Case 3: Calling updateProfilePhoto('') resets custom photo
      await provider.updateProfilePhoto('');
      // Without a signed-in account in a unit test, it resets to empty
      expect(provider.hasCustomPhoto, isFalse);
    });
  });

  group('ProfileScreen widget photo rendering', () {
    Widget buildTestApp(AppProvider provider) {
      return ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ta')],
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets(
      'ProfileScreen renders network image when effectiveProfilePhoto is HTTP URL',
      (WidgetTester tester) async {
        final provider = AppProvider();
        // Set a remote Google avatar URL directly on the profile
        await provider.updateProfilePhoto(
          'https://lh3.googleusercontent.com/test_google_avatar',
        );

        await tester.pumpWidget(buildTestApp(provider));
        await tester.pump();

        // Verify that CachedNetworkImage is rendered with the expected URL
        final imageWidgets = tester.widgetList<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        final hasNetworkImage = imageWidgets.any(
          (img) =>
              img.imageUrl ==
              'https://lh3.googleusercontent.com/test_google_avatar',
        );

        expect(hasNetworkImage, isTrue);
      },
    );

    testWidgets(
      'ProfileScreen shows the name-initial avatar when there is no photo',
      (WidgetTester tester) async {
        // #145: no stock illustration and no Google letter avatar; the
        // profile name's initial is drawn instead.
        final provider = AppProvider();
        await provider.updateProfilePhoto('');

        await tester.pumpWidget(buildTestApp(provider));
        await tester.pump();

        expect(find.byType(NameInitialAvatar), findsWidgets);
      },
    );
  });
}
