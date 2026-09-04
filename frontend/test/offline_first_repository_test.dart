// Offline-first regression suite for SchemeRepository.
//
// Proves the 11 methods the 2026-09-04 offline-first plan targets never
// touch the network: each is exercised against a repository instance wired
// to an MssApiClient backed by an http.Client that throws on any request.
// Since SchemeRepository no longer wraps these calls in try/catch (removed
// as part of the offline-only rewrite), a network attempt would surface as
// an uncaught exception here, failing the test.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/mss_api_client.dart';
import 'package:frontend/services/scheme_repository.dart';

class _ThrowingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw StateError('unexpected network call: ${request.method} ${request.url}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SchemeRepository repo;

  setUpAll(() {
    repo = SchemeRepository.withApiClient(
      MssApiClient(client: _ThrowingHttpClient()),
    );
  });

  group('SchemeRepository is offline-only (no network call reaches MssApiClient)', () {
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
      final all = await repo.getTotalSchemeCount();
      expect(all, greaterThan(0));
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
