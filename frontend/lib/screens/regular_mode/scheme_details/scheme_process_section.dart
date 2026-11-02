import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/responsive.dart';
import '../../../utils/app_text.dart';

/// Content section for the step-by-step scheme application process timeline.
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._steps(context),
        if (showUnconfirmedNotice)
          _UnconfirmedNotice(url: officialUrl, onOpenUrl: onOpenUrl),
      ],
    );
  }

  List<Widget> _steps(BuildContext context) {
    return List.generate(steps.length, (index) {
      final bool isLast = index == steps.length - 1;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: adaptiveSize(context, base: 24, min: 20, max: 24),
                height: adaptiveSize(context, base: 24, min: 20, max: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: FitOneLine(
                  child: Text(
                    "${index + 1}",
                    style: AppGoogleFonts.poppins(
                      color: const Color(0xFF2563EB),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 40, color: const Color(0xFFDBEAFE)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  steps[index],
                  style: AppGoogleFonts.inter(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.hairline),
                Text(
                  context.l10n.processStepSubtitle,
                  style: AppGoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 9.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      );
    });
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
              Icon(Icons.open_in_new, size: 16, color: AppColors.primary),
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
