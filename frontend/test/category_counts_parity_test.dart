// getCategoryCounts() was rewritten from 8 sequential getSchemesByCategory()
// calls (each rebuilding canonicalText from scratch across the whole
// catalog) into a single pass testing all 8 predicates per scheme. This
// pins that the bulk counts exactly match calling getSchemesByCategory()
// per category one at a time -- i.e. the refactor changed performance, not
// behavior, and the Browse Categories tile count can never drift from what
// tapping the tile actually shows.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/scheme_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const categories = [
    "MSME",
    "Startup",
    "Women Entrepreneurs",
    "Business Loans & Credit",
    "SHG & Artisan",
    "Technology",
    "Manufacturing",
    "Export & Trade Promotion",
  ];

  test('bulk getCategoryCounts() matches per-category getSchemesByCategory() '
      'exactly, for every fixed category', () async {
    final bulk = await SchemeRepository.instance.getCategoryCounts(
      UserProfile(),
    );

    for (final cat in categories) {
      final perCategory = await SchemeRepository.instance
          .getSchemesByCategory(cat);
      expect(bulk[cat], perCategory.length, reason: cat);
    }
  });

  test('every fixed category has a nonzero, sub-catalog count', () async {
    final bulk = await SchemeRepository.instance.getCategoryCounts(
      UserProfile(),
    );
    final all = await SchemeRepository.instance.getAllSchemes();

    for (final cat in categories) {
      expect(bulk[cat], greaterThan(0), reason: cat);
      expect(bulk[cat], lessThan(all.length), reason: cat);
    }
  });
}
