import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Content section for the step-by-step scheme application process timeline:
/// a numbered circle per step, joined by a line that runs the step's height.
class SchemeProcessContent extends StatelessWidget {
  final List<String> steps;

  const SchemeProcessContent({super.key, required this.steps});

  /// Diameter of each step number's circle.
  static const double markerSize = 28;

  bool _isLast(int index) => index == steps.length - 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < steps.length; index++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints.tightFor(width: markerSize),
                  child: Column(
                    children: [
                      Container(
                        constraints: const BoxConstraints.tightFor(
                          width: markerSize,
                          height: markerSize,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${index + 1}",
                          style: context.text.label.copyWith(
                            color: AppColors.primaryStrong,
                          ),
                        ),
                      ),
                      if (!_isLast(index))
                        const Expanded(
                          child: VerticalDivider(
                            width: AppSize.borderWidth * 2,
                            thickness: AppSize.borderWidth * 2,
                            color: AppColors.primaryTint,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: AppSpacing.xs,
                      bottom: _isLast(index) ? AppSpacing.none : AppSpacing.lg,
                    ),
                    child: Text(
                      steps[index],
                      style: context.text.body.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
