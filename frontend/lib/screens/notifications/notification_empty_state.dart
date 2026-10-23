import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.notifNoMatchingAlerts,
              style: AppGoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
