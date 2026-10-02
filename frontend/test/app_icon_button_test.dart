import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/widgets/common/app_icon_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('hit area is at least 48x48dp', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppIconButton(
          icon: Icons.bookmark_border,
          semanticLabel: 'Save scheme',
          onPressed: () {},
        ),
      ),
    );

    final size = tester.getSize(find.byType(AppIconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('exposes the semantic label as a button role', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppIconButton(
          icon: Icons.notifications_none,
          semanticLabel: 'Notifications',
          onPressed: () {},
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(AppIconButton));
    expect(semantics.label, 'Notifications');
    // ignore: deprecated_member_use
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
  });

  testWidgets('tapping calls onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        AppIconButton(
          icon: Icons.close,
          semanticLabel: 'Close',
          onPressed: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(AppIconButton));
    expect(tapped, isTrue);
  });

  testWidgets('disabled (onPressed: null) announces enabled: false and ignores taps', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        AppIconButton(
          icon: Icons.close,
          semanticLabel: 'Close',
          onPressed: null,
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(AppIconButton));
    // ignore: deprecated_member_use
    expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);

    await tester.tap(find.byType(AppIconButton));
    expect(tapped, isFalse);
  });

  testWidgets('badgeCount above 9 shows "9+"', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppIconButton(
          icon: Icons.notifications_none,
          semanticLabel: 'Notifications',
          onPressed: () {},
          badgeCount: 15,
        ),
      ),
    );

    expect(find.text('9+'), findsOneWidget);
  });
}
