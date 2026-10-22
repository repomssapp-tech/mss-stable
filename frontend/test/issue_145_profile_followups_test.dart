import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/recommendation/indian_districts.dart';
import 'package:frontend/services/recommendation/indian_states.dart';
import 'package:frontend/widgets/common/name_initial_avatar.dart';

/// #145 follow-ups: LGD district picker data and the name-initial avatar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LGD districts (2.1)', () {
    setUp(IndianDistricts.resetForTest);

    test('bundled list covers every state and union territory', () {
      final raw = jsonDecode(
        File('assets/data/districts_lgd.json').readAsStringSync(),
      );
      final states = (raw['states'] as Map).keys.toSet();
      for (final name in IndianStates.names) {
        expect(states, contains(IndianStates.code(name)), reason: name);
      }
      final total = (raw['states'] as Map).values.fold<int>(
        0,
        (n, v) => n + (v as List).length,
      );
      expect(total, greaterThan(700)); // LGD lists ~780 districts
    });

    test('Tamil Nadu districts resolve by name, code and Tamil name', () async {
      final byName = await IndianDistricts.forState('Tamil Nadu');
      expect(byName, contains('Coimbatore'));
      expect(byName, contains('Chennai'));
      expect(byName.length, 38);
      expect(await IndianDistricts.forState('IN-TN'), byName);
      expect(await IndianDistricts.forState('தமிழ்நாடு'), byName);
    });

    test('district membership is per state and case-insensitive', () async {
      expect(
        await IndianDistricts.isDistrictOf('coimbatore', 'Tamil Nadu'),
        isTrue,
      );
      expect(await IndianDistricts.isDistrictOf('Pune', 'Tamil Nadu'), isFalse);
      expect(await IndianDistricts.isDistrictOf('Pune', 'Maharashtra'), isTrue);
      expect(await IndianDistricts.forState('Atlantis'), isEmpty);
    });
  });

  group('Name-initial avatar', () {
    test('initial comes from the profile name, any script', () {
      expect(NameInitialAvatar.initialOf('varun'), 'V');
      expect(NameInitialAvatar.initialOf('  priya '), 'P');
      expect(NameInitialAvatar.initialOf('தமிழ்'), 'த');
      expect(NameInitialAvatar.initialOf(''), '');
    });

    testWidgets('shows the initial, or a person icon without a name', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Row(
            children: [
              NameInitialAvatar(name: 'Jaya', size: 40),
              NameInitialAvatar(name: '', size: 40),
            ],
          ),
        ),
      );
      expect(find.text('J'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });
  });
}
