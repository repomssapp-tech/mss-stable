// Regression tests for the UI findings in issue #145.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/notifications/notification_cards.dart';
import 'package:frontend/screens/regular_mode/basic_profile/step2_location_form.dart';
import 'package:frontend/screens/regular_mode/home/home_updates_section.dart';
import 'package:frontend/screens/regular_mode/sarvam_chat_screen.dart';
import 'package:frontend/screens/regular_mode/search_screen.dart';
import 'package:frontend/services/recommendation/indian_states.dart';
import 'package:frontend/utils/app_text.dart';
import 'package:frontend/widgets/scheme/filter_panel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(
  AppProvider provider,
  Widget home, {
  Locale locale = const Locale('en'),
}) => ChangeNotifierProvider.value(
  value: provider,
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Filter sheet counts on the idle Search tab', () {
    final catalog = [
      const Scheme(id: 'N1', name: 'Nationwide one', appliesNationally: true),
      const Scheme(id: 'N2', name: 'Nationwide two', appliesNationally: true),
      const Scheme(
        id: 'T1',
        name: 'Tamil Nadu only',
        state: 'Tamil Nadu',
        appliesNationally: false,
        stateCodes: ['IN-TN'],
      ),
      const Scheme(
        id: 'K1',
        name: 'Karnataka only',
        state: 'Karnataka',
        appliesNationally: false,
        stateCodes: ['IN-KA'],
      ),
    ];

    testWidgets('count the whole catalog before any search has run', (
      tester,
    ) async {
      final provider = AppProvider()..setAllSchemesForTesting(catalog);
      final key = GlobalKey<SearchScreenState>();
      await tester.pumpWidget(
        _app(provider, Scaffold(body: SearchScreen(key: key))),
      );
      await tester.pump();

      key.currentState!.openFilterBottomSheet();
      await tester.pumpAndSettle();

      expect(find.byType(FilterPanel), findsOneWidget);
      // Was "Show 0 schemes" with every chip at 0: the idle tab passed its
      // empty results placeholder as the sheet's base list.
      expect(find.text('Show 4 schemes'), findsOneWidget);
    });

    testWidgets('coverage chips count structured coverage', (tester) async {
      final provider = AppProvider()..setAllSchemesForTesting(catalog);
      provider.updateProfile(
        provider.profile.copyWith(state: 'Tamil Nadu'),
        requireCloudSync: false,
      );
      await tester.pumpWidget(
        _app(
          provider,
          Builder(
            builder: (c) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: c,
                  isScrollControlled: true,
                  builder: (_) => const FilterPanel(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      Finder chip(String label) =>
          find.ancestor(of: find.text(label), matching: find.byType(Row));
      String countIn(String label) => tester
          .widgetList<Text>(
            find.descendant(of: chip(label).first, matching: find.byType(Text)),
          )
          .map((t) => t.data)
          .firstWhere((d) => d != null && int.tryParse(d) != null)!;

      expect(countIn('Nationwide'), '2');
      expect(countIn('Tamil Nadu'), '1'); // not the Karnataka scheme
    });
  });

  group('Onboarding state picker', () {
    test('state names normalise and display per language', () {
      expect(IndianStates.names, contains('Tamil Nadu'));
      expect(IndianStates.names.length, 36);
      expect(IndianStates.displayName('Tamil Nadu', 'ta'), 'தமிழ்நாடு');
      expect(IndianStates.displayName('Odisha', 'hi'), 'ओडिशा');
      expect(IndianStates.displayName('Odisha', 'ta'), 'ஒடிசா');
      expect(IndianStates.displayName('Kerala', 'en'), 'Kerala');
      expect(Step2LocationForm.isKnownState('தமிழ்நாடு'), isTrue);
      expect(Step2LocationForm.isKnownState('Tamil Naduu'), isFalse);
      expect(Step2LocationForm.isKnownState(''), isFalse);
    });

    testWidgets('the state is picked from a list, not typed', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final state = TextEditingController();
      addTearDown(state.dispose);
      var changes = 0;
      await tester.pumpWidget(
        _app(
          AppProvider(),
          Scaffold(
            body: SingleChildScrollView(
              child: Step2LocationForm(
                addressController: TextEditingController(),
                cityController: TextEditingController(),
                districtController: TextEditingController(),
                stateController: state,
                pincodeController: TextEditingController(),
                isLoadingLocation: false,
                hasSubmitted: true,
                onFetchLocation: null,
                onChanged: () => changes++,
              ),
            ),
          ),
        ),
      );

      // Address, city and pincode stay text fields; state and district are
      // picked from lists.
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Please select your state'), findsOneWidget);

      await tester.tap(find.text('Select your state'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'tamil');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tamil Nadu'));
      await tester.pumpAndSettle();

      expect(state.text, 'Tamil Nadu');
      expect(changes, 1);
    });
  });

  testWidgets('Home "latest updates" shows no made-up update when there are '
      'no notifications', (tester) async {
    await tester.pumpWidget(
      _app(
        AppProvider(),
        Scaffold(body: HomeLatestUpdatesCard(provider: AppProvider())),
      ),
    );
    expect(
      find.text('New scheme updates and reminders will show up here.'),
      findsOneWidget,
    );
    expect(find.textContaining('Fisheries'), findsNothing);
    expect(find.text('2 days ago'), findsNothing);
  });

  testWidgets('a notification card announces its selection state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    Future<void> pumpCard({required bool selected}) => tester.pumpWidget(
      _app(
        AppProvider(),
        Scaffold(
          body: NotificationTile(
            item: const {'id': 'n1', 'title': 'A scheme', 'read': false},
            isSelectionMode: true,
            isSelected: selected,
            onTap: () {},
          ),
        ),
      ),
    );

    await pumpCard(selected: true);
    expect(
      tester.getSemantics(find.byType(NotificationSelectionSemantics)),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    await pumpCard(selected: false);
    expect(
      tester.getSemantics(find.byType(NotificationSelectionSemantics)),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    handle.dispose();
  });

  test('chat bubbles use the bundled Indic fallback and line height', () {
    final ta = chatBubbleTextStyle('வணக்கம்', const Locale('en'));
    expect(ta.fontFamilyFallback, AppFonts.fallback);
    expect(ta.height, AppTextStyles.ta.body.height);
    final hi = chatBubbleTextStyle('नमस्ते', const Locale('en'));
    expect(hi.height, AppTextStyles.hi.body.height);
    final en = chatBubbleTextStyle('Hello', const Locale('en'));
    expect(en.height, AppTextStyles.en.body.height);
    expect(en.fontFamilyFallback, AppFonts.fallback);
  });

  testWidgets('the disabled Google button says why it is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AppProvider(), const LoginScreen()));
    await tester.pump();

    const notice =
        'Please review the Terms of Use and Privacy Policy before continuing.';
    // Visible next to the button while it is disabled.
    expect(find.text(notice), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    // ...and repeated as a toast when the disabled button is tapped.
    expect(find.text(notice), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 10));
  });
}
