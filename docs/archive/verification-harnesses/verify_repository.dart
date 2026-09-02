// Verification harness for SchemeRepository Phase 4 integration.
//
// Tests online-first routing, offline fallback, retryable error handling,
// non-retryable 404 handling, and method signatures.
//
// Run:  flutter test ../test/flutter_models/verify_repository.dart

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../frontend/lib/models/user_profile.dart';
import '../../frontend/lib/services/mss_api_client.dart';
import '../../frontend/lib/services/scheme_repository.dart';

int _checks = 0;
int _failures = 0;

void check(bool condition, String label) {
  _checks++;
  if (condition) {
    print('  PASS  $label');
  } else {
    _failures++;
    print('  FAIL  $label');
  }
}

void main() {
  test('SchemeRepository Phase 4 online-first and offline fallback verification', () async {
    print('\n=== 1. Testing Offline Fallback (Server Unavailable / Network Exception) ===');
    // Client that throws a network exception (simulating server down / no network)
    final offlineClient = MockClient((request) async {
      throw http.ClientException('Failed to connect to MSS API server');
    });
    final repoOffline = SchemeRepository.withApiClient(MssApiClient(client: offlineClient));

    final totalCountOffline = await repoOffline.getTotalSchemeCount();
    check(totalCountOffline == 219, 'getTotalSchemeCount falls back to offline catalog (count: $totalCountOffline)');

    final searchOffline = await repoOffline.searchSchemes('subvention loan');
    check(searchOffline.isNotEmpty, 'searchSchemes falls back to offline search (${searchOffline.length} results)');

    final matchesOffline = await repoOffline.searchSchemeMatches('startup');
    check(matchesOffline.isNotEmpty, 'searchSchemeMatches falls back offline (${matchesOffline.length} matches)');

    final categoryOffline = await repoOffline.getSchemesByCategory('MSME');
    check(categoryOffline.isNotEmpty, 'getSchemesByCategory falls back offline (${categoryOffline.length} schemes)');

    final ministryOffline = await repoOffline.getSchemesByMinistry('micro');
    check(ministryOffline.isNotEmpty, 'getSchemesByMinistry falls back offline (${ministryOffline.length} schemes)');

    final stateOffline = await repoOffline.getSchemesByState('Tamil Nadu');
    check(stateOffline.isNotEmpty, 'getSchemesByState falls back offline (${stateOffline.length} schemes)');

    final detailOffline = await repoOffline.getSchemeById('SCH000021');
    check(detailOffline != null && detailOffline.id == 'SCH000021', 'getSchemeById falls back offline (scheme: ${detailOffline?.id})');

    final recommendedOffline = await repoOffline.getRecommendedSchemes(UserProfile(state: 'Tamil Nadu', gender: 'Female'));
    check(recommendedOffline.isNotEmpty, 'getRecommendedSchemes falls back offline (${recommendedOffline.length} schemes)');

    final topRecOffline = await repoOffline.getTopRecommendedSchemes(UserProfile(state: 'Tamil Nadu'), limit: 3);
    check(topRecOffline.length <= 3, 'getTopRecommendedSchemes respects limit offline (length: ${topRecOffline.length})');

    final savedOffline = await repoOffline.getSavedSchemes(['SCH000021', 'SCH000080']);
    check(savedOffline.length == 2, 'getSavedSchemes resolves bookmarked IDs (${savedOffline.length} schemes)');

    final countsOffline = await repoOffline.getCategoryCounts(UserProfile());
    check(countsOffline.containsKey('MSME') && countsOffline['MSME']! > 0, 'getCategoryCounts returns map of category counts (${countsOffline['MSME']} MSME schemes)');

    final hintOffline = await repoOffline.getDynamicSearchHint();
    check(hintOffline.isNotEmpty, 'getDynamicSearchHint returns prompt ("$hintOffline")');

    print('\n=== 2. Testing Online API Client Routing (Mocked Successful API Server) ===');
    final onlineClient = MockClient((request) async {
      final uri = request.url.toString();
      if (uri.contains('/v1/search')) {
        return http.Response('''{
          "contract": "search_response",
          "data": {
            "query": {"text": "loan"},
            "results": [
              {
                "schemeId": "SCH000080",
                "name": "Online API Result Scheme",
                "matchScore": 9.85,
                "status": "active",
                "explanation": {"summary": "Matched via online API endpoint"},
                "nextActions": [{"action": "apply_online", "label": "Apply", "url": "https://online.gov.in"}]
              }
            ]
          }
        }''', 200, headers: {'content-type': 'application/json'});
      }
      if (uri.contains('/v1/schemes/SCH000080')) {
        return http.Response('''{
          "schemeId": "SCH000080",
          "name": "Online Scheme Detail SCH000080",
          "schemeStatus": "active",
          "nextActions": [{"action": "apply_online", "label": "Apply", "url": "https://online.gov.in"}]
        }''', 200, headers: {'content-type': 'application/json'});
      }
      if (uri.contains('/v1/meta')) {
        return http.Response('''{
          "catalogVersion": "v3.0.0",
          "entityCounts": {"scheme": 217}
        }''', 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('{}', 200);
    });

    final repoOnline = SchemeRepository.withApiClient(MssApiClient(client: onlineClient));

    final onlineSearch = await repoOnline.searchSchemes('loan');
    check(onlineSearch.isNotEmpty && onlineSearch.first.name == 'Online API Result Scheme',
        'searchSchemes uses online API response (${onlineSearch.first.name})');
    check(onlineSearch.first.matchScore == 9.85, 'online matchScore attached (${onlineSearch.first.matchScore})');

    final onlineDetail = await repoOnline.getSchemeById('SCH000080');
    check(onlineDetail != null && onlineDetail.name.contains('SCH000080'),
        'getSchemeById uses online API response (${onlineDetail?.name})');

    final onlineMetaCount = await repoOnline.getTotalSchemeCount();
    check(onlineMetaCount == 217, 'getTotalSchemeCount uses online /v1/meta endpoint ($onlineMetaCount)');

    print('\n=== 3. Testing Non-Retryable Error (404 UNKNOWN_SCHEME Does NOT Fallback) ===');
    final nonRetryableClient = MockClient((request) async {
      return http.Response('''{
        "contract": "error",
        "error": {
          "code": "UNKNOWN_SCHEME",
          "message": "Scheme invalid_non_existent not found"
        }
      }''', 404, headers: {'content-type': 'application/json'});
    });

    final repoNonRetryable = SchemeRepository.withApiClient(MssApiClient(client: nonRetryableClient));
    final notFoundResult = await repoNonRetryable.getSchemeById('invalid_non_existent');
    check(notFoundResult == null, '404 UNKNOWN_SCHEME correctly returns null without falling back to local bundle');

    print('\n${'=' * 60}');
    print('$_checks checks, $_failures failure(s)');
    print('=' * 60);

    expect(_failures, equals(0), reason: 'Repository verification failed');
  });
}
