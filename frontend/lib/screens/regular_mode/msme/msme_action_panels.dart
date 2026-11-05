import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_spacing.dart';
import '../search_results_screen.dart';
import '../../../utils/app_text.dart';

class SchemesInteractivePanel extends StatelessWidget {
  final Color iconColor;

  const SchemesInteractivePanel({super.key, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.msmeInteractiveToolsActions,
              style: context.text.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.msmeInteractiveToolsDesc,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      provider.updateTabIndex(1); // Navigate to search
                      Navigator.of(context).pop(); // Dismiss detail
                    },
                    child: Text(
                      context.l10n.msmeSearchSchemes,
                      textAlign: TextAlign.center,
                      style: context.text.button,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      provider.updateTabIndex(4); // Navigate to profile
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      context.l10n.completeProfileTitle,
                      textAlign: TextAlign.center,
                      style: context.text.button,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FinanceInteractivePanel extends StatelessWidget {
  final Color iconColor;

  const FinanceInteractivePanel({super.key, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.msmeFundingHeading,
              style: context.text.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.msmeFundingDescription,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchResultsScreen(
                        title: 'Loan',
                        type: 'category',
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.currency_rupee, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      // Wraps and centres instead of shrinking: a one-line
                      // fit squeezed long Tamil labels to an unreadable size.
                      child: Text(
                        context.l10n.msmeSearchFunding,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.button,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CsrInteractivePanel extends StatelessWidget {
  final Color iconColor;

  const CsrInteractivePanel({super.key, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.msmeClustersHeading,
              style: context.text.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.msmeClustersDescription,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchResultsScreen(
                        title: 'Cluster',
                        type: 'category',
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hub, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      // Wraps and centres instead of shrinking: a one-line
                      // fit squeezed long Tamil labels to an unreadable size.
                      child: Text(
                        context.l10n.msmeSearchClusters,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.button,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UdyamInteractivePanel extends StatefulWidget {
  final Color iconColor;
  final Color themeColor;

  const UdyamInteractivePanel({
    super.key,
    required this.iconColor,
    required this.themeColor,
  });

  @override
  State<UdyamInteractivePanel> createState() => _UdyamInteractivePanelState();
}

class _UdyamInteractivePanelState extends State<UdyamInteractivePanel> {
  int _udyamStepIndex = 0;

  List<Map<String, String>> _udyamSteps(AppLocalizations l10n) => [
    {
      'title': l10n.msmeUdyamStep1Title,
      'desc': l10n.msmeUdyamStep1Desc,
      'action': l10n.msmeUdyamStep1Action,
    },
    {
      'title': l10n.msmeUdyamStep2Title,
      'desc': l10n.msmeUdyamStep2Desc,
      'action': l10n.msmeUdyamStep2Action,
    },
    {
      'title': l10n.msmeUdyamStep3Title,
      'desc': l10n.msmeUdyamStep3Desc,
      'action': l10n.msmeUdyamStep3Action,
    },
    {
      'title': l10n.msmeUdyamStep4Title,
      'desc': l10n.msmeUdyamStep4Desc,
      'action': l10n.msmeUdyamStep4Action,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = _udyamSteps(l10n);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.msmeUdyamFlowTitle,
              style: context.text.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Step Selector Pills (Step 1, Step 2, Step 3, Step 4)
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(steps.length, (idx) {
                  final isSelected = idx == _udyamStepIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _udyamStepIndex = idx;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.iconColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          l10n.msmeStepNumber(idx + 1),
                          style: context.text.label.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Step Details Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.themeColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[_udyamStepIndex]['title']!,
                    style: context.text.cardTitle.copyWith(
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    steps[_udyamStepIndex]['desc']!,
                    style: context.text.bodySmall.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.tight),
                      Expanded(
                        child: Text(
                          steps[_udyamStepIndex]['action']!,
                          style: context.text.label.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Button to official Udyam portal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text(
                  l10n.msmeUdyamGoToPortal,
                  textAlign: TextAlign.center,
                  style: context.text.button,
                ),
                onPressed: () async {
                  final Uri url = Uri.parse(
                    'https://www.udyamregistration.gov.in/',
                  );
                  try {
                    final launched = await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched) {
                      await launchUrl(url, mode: LaunchMode.platformDefault);
                    }
                  } catch (_) {
                    try {
                      await launchUrl(url, mode: LaunchMode.platformDefault);
                    } catch (e) {
                      debugPrint('Could not launch Udyam URL: $e');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
