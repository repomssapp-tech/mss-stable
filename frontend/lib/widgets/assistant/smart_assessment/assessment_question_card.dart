import 'package:flutter/material.dart';
import '../../../utils/app_spacing.dart';
import '../question_node.dart';
import '../../../utils/app_text.dart';

class AssessmentQuestionCard extends StatelessWidget {
  final String currentQuestionId;
  final QuestionNode rawNode;
  final LocalizedQuestionNode localizedNode;
  final String? selectedAnswer;
  final Color themeColor;
  final bool isTamil;
  final void Function(
    String selectedLocalizedOption,
    LocalizedQuestionNode localizedNode,
  )
  onOptionSelected;

  const AssessmentQuestionCard({
    super.key,
    required this.currentQuestionId,
    required this.rawNode,
    required this.localizedNode,
    required this.selectedAnswer,
    required this.themeColor,
    required this.isTamil,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey<String>(currentQuestionId),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedNode.questionText,
            style: AppGoogleFonts.poppins(
              fontSize: isTamil ? 13.8 : 15.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              height: isTamil ? 1.35 : 1.25,
            ),
          ),
          if (localizedNode.subtitleText != null &&
              localizedNode.subtitleText!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.tight),
            Text(
              localizedNode.subtitleText!,
              style: AppGoogleFonts.inter(
                fontSize: isTamil ? 10.5 : 11.5,
                color: const Color(0xFF64748B),
                height: isTamil ? 1.35 : 1.25,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // Options list
          ...List.generate(localizedNode.options.length, (index) {
            final optionLocalized = localizedNode.options[index];
            final rawOption = rawNode.options[index];
            final isSelected = selectedAnswer == rawOption;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    onOptionSelected(optionLocalized, localizedNode),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.lg,
                  ),
                  alignment: Alignment.centerLeft,
                  backgroundColor: isSelected
                      ? themeColor.withValues(alpha: 0.06)
                      : Colors.white,
                  side: BorderSide(
                    color: isSelected ? themeColor : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  optionLocalized,
                  maxLines: 3,
                  overflow: TextOverflow.visible,
                  style: AppGoogleFonts.inter(
                    fontSize: isTamil ? 11.5 : 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? themeColor : const Color(0xFF334155),
                    height: isTamil ? 1.35 : 1.25,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
