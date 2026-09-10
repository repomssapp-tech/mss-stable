// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('list all unique categories and tags across all schemes', () async {
    final schemes = await SchemeRepository.instance.getAllSchemes();
    final categories = <String>{};
    final schemeTypes = <String>{};
    final sectors = <String>{};

    for (final s in schemes) {
      if (s.category.isNotEmpty) categories.add(s.category);
      if (s.schemeType.isNotEmpty) schemeTypes.add(s.schemeType);
      if (s.sector.isNotEmpty) sectors.add(s.sector);
    }

    print('Distinct Categories (${categories.length}):');
    for (final c in categories) {
      print(' - $c');
    }

    print('\nDistinct Scheme Types (${schemeTypes.length}):');
    for (final st in schemeTypes) {
      print(' - $st');
    }

    print('\nDistinct Sectors (${sectors.length}):');
    for (final sec in sectors) {
      print(' - $sec');
    }
  });
}
