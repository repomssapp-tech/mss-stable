import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // 2.2: fonts are now bundled as local assets and runtime fetching is
  // disabled in main(). These checks don't call main(), so they set the
  // same flag directly to prove the config value itself and confirm the
  // bundled families render without throwing/falling back silently.
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'Inter, Poppins and NotoSansTamil render via the bundled local assets '
    'with runtime fetching disabled (no network needed)',
    (tester) async {
      expect(GoogleFonts.config.allowRuntimeFetching, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text(
                  'Sample heading',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                ),
                Text(
                  'Sample body text',
                  style: TextStyle(fontFamily: 'Inter'),
                ),
                Text(
                  'திட்டங்கள் மற்றும் மானியங்கள்',
                  style: TextStyle(
                    fontFamily: 'NotoSansTamil',
                    fontFamilyFallback: ['NotoSansTamil'],
                  ),
                ),
                // The 108 existing GoogleFonts.* call sites (not yet
                // migrated to AppText -- that's Phase 3) must still render
                // without crashing or needing the network.
                Text('Existing call site', style: TextStyle()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Sample heading'), findsOneWidget);
      expect(find.text('Sample body text'), findsOneWidget);
      expect(find.text('திட்டங்கள் மற்றும் மானியங்கள்'), findsOneWidget);
    },
  );

  testWidgets(
    'GoogleFonts.inter() and .poppins() still work with runtime fetching '
    'disabled (resolve via the bundled local "Inter"/"Poppins" families)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Inter via GoogleFonts', style: GoogleFonts.inter()),
                Text('Poppins via GoogleFonts', style: GoogleFonts.poppins()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
