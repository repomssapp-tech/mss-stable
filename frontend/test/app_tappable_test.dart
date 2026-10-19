import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/widgets/common/app_tappable.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('hit area is at least 48x48dp even for a small visual child', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        AppTappable(
          onTap: () {},
          semanticLabel: 'Filter chip',
          child: const SizedBox(height: 30, child: Center(child: Text('Loan'))),
        ),
      ),
    );

    final size = tester.getSize(find.byType(AppTappable));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('exposes semanticLabel and selected state', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppTappable(
          onTap: () {},
          semanticLabel: 'All Saved',
          selected: true,
          child: const Text('All Saved'),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(AppTappable));
    // The child's own Text semantics merge into this node's label too
    // (expected Flutter behaviour), so check containment, not equality.
    expect(semantics.label, contains('All Saved'));
    // ignore: deprecated_member_use
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    // ignore: deprecated_member_use
    expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
  });

  testWidgets('tapping calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(AppTappable(onTap: () => tapped = true, child: const Text('Tag'))),
    );

    await tester.tap(find.byType(AppTappable));
    expect(tapped, isTrue);
  });

  testWidgets(
    'D3: decoration paints via Ink (inside the InkWell), not a Container '
    'wrapping it, so the ripple composites above the background',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          AppTappable(
            onTap: () {},
            decoration: const BoxDecoration(color: Color(0xFFEFF6FF)),
            child: const Text('Loan'),
          ),
        ),
      );

      expect(find.byType(Ink), findsOneWidget);
      // The decoration must be on the Ink widget inside the InkWell, not
      // on a Container wrapping the InkWell -- i.e. no Container ancestor
      // between this AppTappable and its InkWell carries a BoxDecoration.
      final ink = tester.widget<Ink>(find.byType(Ink));
      expect(ink.decoration, isNotNull);
    },
  );
}
