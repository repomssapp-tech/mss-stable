import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/widgets/common/app_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(wrap(const AppCard(child: Text('Scheme name'))));

    expect(find.text('Scheme name'), findsOneWidget);
  });

  testWidgets(
    'with onTap, exposes a button semantic label and a 48dp-plus hit area',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          AppCard(
            onTap: () {},
            semanticLabel: 'Open scheme details',
            child: const SizedBox(height: 20, child: Text('Scheme')),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(AppCard));
      // The child's own Text semantics merge into this node's label too
      // (expected Flutter behaviour), so check containment, not equality.
      expect(semantics.label, contains('Open scheme details'));
      // ignore: deprecated_member_use
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);

      final size = tester.getSize(find.byType(AppCard));
      expect(size.height, greaterThanOrEqualTo(48));
    },
  );

  testWidgets('tapping calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(AppCard(onTap: () => tapped = true, child: const Text('Tap me'))),
    );

    await tester.tap(find.byType(AppCard));
    expect(tapped, isTrue);
  });

  testWidgets('without onTap, is not a button', (tester) async {
    await tester.pumpWidget(wrap(const AppCard(child: Text('Static card'))));

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('D3: the AppCard-decorated Container is an ancestor of its own '
      'Material/InkWell, not the other way around -- so the ripple paints '
      'above the background', (tester) async {
    await tester.pumpWidget(
      wrap(AppCard(onTap: () {}, child: const Text('Scheme'))),
    );

    // The Material belonging to this AppCard has a Container ancestor
    // within the AppCard's own subtree (the decorated background), not
    // the reverse -- i.e. the background is painted before the ripple,
    // so the ripple composites visibly on top of it.
    final materialInCard = find.descendant(
      of: find.byType(AppCard),
      matching: find.byType(Material),
    );
    final containerAncestorOfMaterial = find.ancestor(
      of: materialInCard,
      matching: find.byType(Container),
    );
    expect(containerAncestorOfMaterial, findsWidgets);
  });

  testWidgets('D3: margin is outside the tappable InkWell area', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        AppCard(
          onTap: () => tapped = true,
          margin: const EdgeInsets.all(20),
          child: const SizedBox(width: 40, height: 40),
        ),
      ),
    );

    final inkWellRect = tester.getRect(find.byType(InkWell));
    final cardRect = tester.getRect(find.byType(AppCard));
    // The InkWell (tappable area) must be smaller than the full AppCard
    // bounds (which include the margin) -- margin is not part of the ripple
    // or tap area.
    expect(inkWellRect.width, lessThan(cardRect.width));
    expect(inkWellRect.height, lessThan(cardRect.height));

    await tester.tapAt(inkWellRect.center);
    expect(tapped, isTrue);
  });
}
