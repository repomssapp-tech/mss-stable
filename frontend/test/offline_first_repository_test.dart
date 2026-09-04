// Offline-first regression suite for SchemeRepository.
//
// Proves the 11 methods the 2026-09-04 offline-first plan targets work
// correctly reading only from the local MssCatalogBundle. As of Phase 6,
// SchemeRepository no longer holds an MssApiClient/http.Client at all, so a
// network call from these methods isn't just avoided -- it's structurally
// impossible. This suite is now a functional regression check rather than a
// network-interception proof.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/scheme_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repo = SchemeRepository.instance;

  group('SchemeRepository offline-only scheme discovery', () {
    test('getTotalSchemeCount', () async {
      final count = await repo.getTotalSchemeCount();
      expect(count, greaterThan(0));
    });

    test('getTopRecommendedSchemes', () async {
      final result = await repo.getTopRecommendedSchemes(UserProfile(), limit: 5);
      expect(result, isNotEmpty);
    });

    test('getCategoryCounts', () async {
      final counts = await repo.getCategoryCounts(UserProfile());
      expect(counts, isNotEmpty);
      expect(counts.values.every((v) => v >= 0), isTrue);
    });

    test('searchSchemes', () async {
      final results = await repo.searchSchemes('loan');
      expect(results, isNotEmpty);
    });

    test('searchSchemeMatches', () async {
      final results = await repo.searchSchemeMatches('loan');
      expect(results, isNotEmpty);
    });

    test('getSchemesByCategory', () async {
      final results = await repo.getSchemesByCategory('MSME');
      expect(results, isNotEmpty);
    });

    test('getSchemesByMinistry', () async {
      // Must not throw; content depends on catalog data, not asserted here.
      await repo.getSchemesByMinistry('Ministry of MSME');
    });

    test('getSchemesByState', () async {
      final results = await repo.getSchemesByState('Tamil Nadu');
      expect(results, isNotEmpty);
    });

    test('getSchemeById', () async {
      final matches = await repo.searchSchemes('loan');
      final scheme = await repo.getSchemeById(matches.first.id);
      expect(scheme, isNotNull);
      expect(scheme!.id, matches.first.id);
    });

    test('getRecommendedSchemes', () async {
      final results = await repo.getRecommendedSchemes(UserProfile());
      expect(results, isNotEmpty);
    });

    test('getSavedSchemes', () async {
      final matches = await repo.searchSchemes('loan');
      final saved = await repo.getSavedSchemes([matches.first.id]);
      expect(saved, isNotEmpty);
    });
  });
}
