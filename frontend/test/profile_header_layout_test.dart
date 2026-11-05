import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/profile/profile_banner_card.dart';
import 'package:frontend/screens/profile/profile_user_info_card.dart';
import 'package:frontend/utils/app_size.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:frontend/widgets/common/name_initial_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final language in ['en', 'ta']) {
    for (final width in [320.0, 360.0]) {
      testWidgets('Profile header stays aligned at $width dp in $language', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final provider = AppProvider();
        addTearDown(provider.dispose);
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  ProfileBannerCard(provider: provider),
                  ProfileUserInfoCard(provider: provider),
                ],
              ),
            ),
          ),
        );
        final banner = find.byType(ProfileBannerCard);
        final l10n = AppLocalizations.of(tester.element(banner))!;
        final name = find
            .descendant(of: banner, matching: find.text('-'))
            .first;
        final avatar = find.byType(NameInitialAvatar);
        final photoTarget = find.bySemanticsLabel(l10n.changeProfilePhoto);
        expect(
          tester.getTopLeft(avatar).dy,
          closeTo(tester.getTopLeft(name).dy, 2),
        );
        expect(
          tester.getSize(photoTarget).width,
          greaterThanOrEqualTo(AppSize.tapTarget),
        );

        final heading = find.text(l10n.userInformation);
        final editButton = find.widgetWithText(TextButton, l10n.editProfile);
        expect(tester.getTopLeft(heading).dy, tester.getTopLeft(editButton).dy);
        expect(
          tester.getTopLeft(editButton).dx,
          greaterThan(tester.getTopLeft(heading).dx),
        );
        expect(
          tester.getSize(editButton).height,
          greaterThanOrEqualTo(AppSize.tapTarget),
        );

        final camera = find.byIcon(Icons.camera_alt_outlined);
        expect(
          find.ancestor(of: camera, matching: find.byType(ClipOval)),
          findsNothing,
        );
        for (final target in [camera, avatar]) {
          await tester.tap(target, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(find.text(l10n.profilePhotoTitle), findsOneWidget);
          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
