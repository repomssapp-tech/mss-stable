import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mss_app/widgets/scheme_card.dart';
import 'package:mss_app/models/scheme_model.dart';
import 'package:mss_app/engine/recommendation_engine.dart';
import 'package:mss_app/providers/app_state_provider.dart';

void main() {
  testWidgets('Inspect SchemeCard Semantics', (tester) async {
    final handle = tester.ensureSemantics();
    final scheme = Scheme(
      id: 'scheme-1',
      name: 'Test Scheme Name',
      nameTa: 'சோதனை திட்டம்',
      category: 'MSME',
      briefDescription: 'Brief description',
      briefDescriptionTa: 'சுருக்கமான விளக்கம்',
    );
    final result = RecommendationResult(
      score: 0.95,
      percentage: 95,
      eligible: true,
      matchCategory: 'High Match',
      reasons: [],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: SchemeCard(
              scheme: scheme,
              result: result,
              isBookmarked: false,
              onBookmarkToggle: () {},
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    debugPrint('=== SEMANTICS TREE ===');
    debugPrint(tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode?.toStringDeep());
    handle.dispose();
  });
}
