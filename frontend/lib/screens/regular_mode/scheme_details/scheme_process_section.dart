import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_size.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// Content section for the step-by-step scheme application process timeline:
/// a numbered circle per step, joined by a line that runs the step's height.
class SchemeProcessContent extends StatelessWidget {
  final List<String> steps;

  /// Some of these steps did not come from an official source.
  final bool showUnconfirmedNotice;

  /// Official page for the notice to link to; empty when there is none to trust.
  final String officialUrl;
  final ValueChanged<String>? onOpenUrl;

  const SchemeProcessContent({
    super.key,
    required this.steps,
    this.showUnconfirmedNotice = false,
    this.officialUrl = '',
    this.onOpenUrl,
  });

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
        if (showUnconfirmedNotice)
          _UnconfirmedNotice(url: officialUrl, onOpenUrl: onOpenUrl),
      ],
    );
  }
}

/// Last line of the section: the source notes say some details are unconfirmed.
class _UnconfirmedNotice extends StatelessWidget {
  const _UnconfirmedNotice({required this.url, required this.onOpenUrl});

  final String url;
  final ValueChanged<String>? onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final open = onOpenUrl;
    if (url.isEmpty || open == null) {
      return Text(
        context.l10n.processUnconfirmedNoLink,
        style: context.text.bodySmall.copyWith(color: AppColors.textSecondary),
      );
    }
    return Semantics(
      link: true,
      button: false,
      child: InkWell(
        onTap: () => open(url),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.open_in_new,
                size: AppSize.iconSm,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.processUnconfirmedLink,
                  style: context.text.label.copyWith(
                    color: AppColors.primary,
                    decoration: context.linkDecoration,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
