// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Calculate actual scheme counts from repository', () async {
    final repo = SchemeRepository.instance;

    final categories = [
      'Business & MSME',
      'Startup',
      'Finance',
      'Skill Development',
      'Artisan',
      'Digital India',
      'Women Entrepreneurs',
      'Student Startups',
      'Startup & Incubation',
      'Loans & Credit Support',
      'Women Entrepreneurship',
    ];

    print('=== Category Counts from SchemeRepository ===');
    for (final c in categories) {
      final list = await repo.getSchemesByCategory(c);
      print('  $c: ${list.length}');
      expect(list, isNotNull);
    }

    print('\n=== Ministry Counts from SchemeRepository ===');
    for (final m in [
      'Ministry of MSME',
      'Ministry of Education',
      'Ministry of Finance',
      'Ministry of Agriculture',
      'Ministry of Rural Development',
      'Ministry of Skill Development',
    ]) {
      final list = await repo.getSchemesByMinistry(m);
      print('  $m: ${list.length}');
      expect(list, isNotNull);
    }

    print('\n=== State Counts from SchemeRepository ===');
    for (final s in [
      'Tamil Nadu',
      'Maharashtra',
      'Uttar Pradesh',
      'Karnataka',
      'Gujarat',
    ]) {
      final list = await repo.getSchemesByState(s);
      print('  $s: ${list.length}');
      expect(list, isNotNull);
    }
  });
}
