import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../services/account/account_pending_deletion.dart';
import '../../utils/app_colors.dart';
import 'custom_confirm_dialog.dart';

String _date(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);

/// Tells the user the account is deleted and that its data is kept for 30 days
/// (until [purgeAfter]), during which signing in again reactivates it. A null
/// [purgeAfter] means the server deleted the account at once.
Future<void> showAccountDeletedDialog(
  BuildContext context,
  DateTime? purgeAfter,
) {
  return CustomConfirmDialog.show(
    context,
    icon: Icons.check_circle_outline_rounded,
    iconColor: AppColors.success,
    iconBgColor: AppColors.successSoft,
    title: context.l10n.accountDeletedTitle,
    message: purgeAfter == null
        ? context.l10n.accountDeletedNowMsg
        : context.l10n.accountDeletedMsg(_date(context, purgeAfter)),
    confirmLabel: context.l10n.ok,
    confirmColor: AppColors.primary,
    onConfirm: () {},
    showCancel: false,
  );
}

/// Asks whether to reactivate an account deleted within the last 30 days.
/// Completes with true only when the user taps Reactivate.
Future<bool> confirmAccountRestore(
  BuildContext context,
  AccountPendingDeletion pending,
) async {
  var agreed = false;
  final purgeAfter = pending.purgeAfter;
  await CustomConfirmDialog.show(
    context,
    icon: Icons.restore_rounded,
    iconColor: AppColors.primary,
    iconBgColor: AppColors.primarySoft,
    title: context.l10n.accountRestoreTitle,
    message: context.l10n.accountRestoreMsg(
      purgeAfter == null ? '—' : _date(context, purgeAfter),
    ),
    cancelLabel: context.l10n.accountRestoreCancel,
    confirmLabel: context.l10n.accountRestoreConfirm,
    confirmColor: AppColors.primary,
    onConfirm: () => agreed = true,
  );
  return agreed;
}
