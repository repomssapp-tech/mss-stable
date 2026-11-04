import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/services/account/session_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionCacheService - Eligibility Results', () {
    test(
      'saves and retrieves saved eligibility results and timestamp',
      () async {
        final cache = SessionCacheService.instance;
        expect(await cache.getSavedEligibilityResults(), isNull);
        expect(await cache.getLastEligibilitySavedAt(), isNull);

        final testIds = ['scheme-101', 'scheme-202'];
        final testTime = DateTime(2026, 9, 8, 10, 30);
        await cache.saveSavedEligibilityResults(testIds, testTime);

        final retrievedIds = await cache.getSavedEligibilityResults();
        final retrievedTime = await cache.getLastEligibilitySavedAt();

        expect(retrievedIds, equals(testIds));
        expect(retrievedTime, equals(testTime));

        // Test clear
        await cache.clearSavedEligibilityResults();
        expect(await cache.getSavedEligibilityResults(), isNull);
        expect(await cache.getLastEligibilitySavedAt(), isNull);
      },
    );
  });

  group('AppProvider - Eligibility Persistence', () {
    test(
      'saveEligibilityResults updates in-memory state and notifies listeners',
      () async {
        final provider = AppProvider();
        expect(provider.savedEligibilitySchemeIds, isEmpty);
        expect(provider.hasSavedEligibilityResults, isFalse);

        bool notified = false;
        provider.addListener(() {
          notified = true;
        });

        final testIds = ['scheme-a', 'scheme-b'];
        await provider.saveEligibilityResults(testIds);

        expect(provider.savedEligibilitySchemeIds, equals(testIds));
        expect(provider.hasSavedEligibilityResults, isTrue);
        expect(provider.lastEligibilitySavedAt, isNotNull);
        expect(notified, isTrue);

        // Verify cached in SharedPreferences
        final cachedIds = await SessionCacheService.instance
            .getSavedEligibilityResults();
        expect(cachedIds, equals(testIds));
      },
    );
  });

}
