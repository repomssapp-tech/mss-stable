import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  // H7: in the real catalog bundle, id and schemeCode always differ (e.g.
  // id "SCH000001" vs schemeCode "TN001"), confirmed by decompressing
  // assets/catalog/catalog_bundle.json.gz directly. This scheme mirrors
  // that shape.
  const scheme = Scheme(
    id: 'SCH000001',
    name: 'Tamil Nadu MSME Growth Scheme',
    schemeCode: 'TN001',
    category: 'MSME',
    state: 'Tamil Nadu',
    overview: 'Support scheme for micro enterprises in Tamil Nadu.',
  );

  group('Bookmark key unification (H7)', () {
    test(
      'loadSchemes normalizes a pre-existing schemeCode-keyed bookmark to id',
      () async {
        final provider = AppProvider();
        provider.setAllSchemesForTesting([scheme]);

        // Simulate a bookmark saved the old way, by schemeCode.
        provider.toggleBookmark(scheme.schemeCode);
        expect(provider.bookmarkedIds, equals([scheme.schemeCode]));

        await provider.loadSchemes();

        expect(provider.bookmarkedIds, equals([scheme.id]));
        expect(provider.bookmarkedIds, isNot(contains(scheme.schemeCode)));
        expect(
          provider.bookmarkedSchemes.map((s) => s.id),
          contains(scheme.id),
        );
      },
    );
  });
}
