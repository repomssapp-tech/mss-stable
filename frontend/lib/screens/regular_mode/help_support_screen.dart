import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/common/standard_page_header.dart';
import 'help_support/help_support_sections.dart';

export 'help_support/help_support_data.dart';
export 'help_support/help_faq_bottom_sheets.dart';
export 'help_support/help_report_issue_bottom_sheet.dart';
export 'help_support/help_feedback_bottom_sheet.dart';
export 'help_support/help_support_sections.dart';

class HelpSupportScreen extends StatelessWidget {
  final String initialMode; // 'faq', 'contact', 'both'
  const HelpSupportScreen({super.key, this.initialMode = 'both'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: StandardPageHeader(
        title: HelpHeaderSection.titleFor(context, initialMode),
        backgroundColor: AppConstants.backgroundColor,
      ),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: AppSpacing.xs,
            bottom: AppSpacing.lg,
          ),
          children: [
            HelpHeaderSection(initialMode: initialMode),
            const SizedBox(height: AppSpacing.xl),
            if (initialMode == 'both' || initialMode == 'faq')
              const HelpFaqSection(),
            if (initialMode == 'both' || initialMode == 'contact')
              const HelpContactSection(),
            if (initialMode == 'both' || initialMode == 'contact')
              const HelpFeedbackSection(),
            if (initialMode == 'both' || initialMode == 'contact')
              const HelpStillNeedHelpBanner(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
