import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';

enum ToastType { success, info, warning, error }

/// A unified, sleek Material 3 Toast and Banner notification system.
/// Replaces raw debugging SnackBar popups with polished, floating notifications.
///
/// On a plain page the toast is a floating SnackBar, which the Scaffold keeps
/// clear of its bottom navigation bar and buttons. A SnackBar is drawn by the
/// app's ScaffoldMessenger *under* modal routes, though, so when the caller
/// sits in a bottom sheet or dialog (or under one) the toast is drawn in the
/// root [Overlay] instead, above every route. Before, a warning raised from
/// inside a sheet (the feedback sheet's "too short" message) appeared behind
/// it.
class AppToast {
  AppToast._();

  /// The overlay toast on screen, if any. A new toast replaces it (and any
  /// SnackBar toast), so toasts never stack.
  static _ToastHandle? _current;

  /// Shows a success toast with a green accent and checkmark icon.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.success, duration, actionLabel, onAction);
  }

  /// Shows an informational toast with a blue accent and info icon.
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.info, duration, actionLabel, onAction);
  }

  /// Shows a warning toast with an amber accent and warning icon.
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.warning, duration, actionLabel, onAction);
  }

  /// Shows a user-friendly error toast with a soft red accent and alert icon.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(context, message, ToastType.error, duration, actionLabel, onAction);
  }

  /// Removes the overlay toast on screen, if any, without animation.
  static void hide() {
    _current?.remove();
    _current = null;
  }

  static void _show(
    BuildContext context,
    String message,
    ToastType type,
    Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  ) {
    final hasAction = actionLabel != null && onAction != null;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);

    // A sheet or dialog route, or a page with another route on top of it:
    // a SnackBar would be hidden behind that route.
    final route = ModalRoute.of(context);
    final covered = route != null && (route is PopupRoute || !route.isCurrent);

    hide();
    messenger?.hideCurrentSnackBar();

    if (overlay != null && (covered || messenger == null)) {
      _showInOverlay(
        context,
        overlay,
        message,
        type,
        hasAction ? const Duration(seconds: 5) : duration,
        hasAction ? actionLabel : null,
        onAction,
      );
    } else if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          elevation: 3,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          padding: EdgeInsets.zero,
          duration: hasAction ? const Duration(seconds: 5) : duration,
          content: Semantics(
            liveRegion: true,
            child: _ToastCard(
              message: message,
              type: type,
              actionLabel: hasAction ? actionLabel : null,
              onAction: onAction,
            ),
          ),
        ),
      );
    }
  }

  static void _showInOverlay(
    BuildContext context,
    OverlayState overlay,
    String message,
    ToastType type,
    Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  ) {
    // Screen-reader users need longer to reach the message or its action.
    final accessible = MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
    final shownFor = accessible ? duration * 2 : duration;

    late final _ToastHandle handle;
    final entry = OverlayEntry(
      builder: (_) => _OverlayToast(
        message: message,
        type: type,
        duration: shownFor,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          handle.remove();
          if (identical(_current, handle)) _current = null;
        },
      ),
    );
    handle = _ToastHandle(entry);
    _current = handle;
    overlay.insert(entry);

    // TalkBack reads the toast's live region; VoiceOver needs an explicit
    // announcement.
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      final view = View.maybeOf(context);
      if (view != null) {
        SemanticsService.sendAnnouncement(
          view,
          message,
          Directionality.maybeOf(context) ?? TextDirection.ltr,
        );
      }
    }
  }
}

/// One inserted overlay entry, removed at most once. (Removing from an overlay
/// that has already been torn down is a no-op in [OverlayEntry.remove].)
class _ToastHandle {
  _ToastHandle(this._entry);

  final OverlayEntry _entry;
  bool _removed = false;

  void remove() {
    if (_removed) return;
    _removed = true;
    _entry
      ..remove()
      ..dispose();
  }
}

/// The toast in the root overlay: bottom-anchored above the keyboard and
/// system bars, fades/slides in, leaves after [duration] or when swiped away.
class _OverlayToast extends StatefulWidget {
  const _OverlayToast({
    required this.message,
    required this.type,
    required this.duration,
    required this.actionLabel,
    required this.onAction,
    required this.onDismissed,
  });

  final String message;
  final ToastType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_OverlayToast> createState() => _OverlayToastState();
}

class _OverlayToastState extends State<_OverlayToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse().orCancel.catchError((_) {});
    if (mounted) widget.onDismissed();
  }

  void _runAction() {
    widget.onAction?.call();
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final inset = media.viewInsets.bottom > media.viewPadding.bottom
        ? media.viewInsets.bottom
        : media.viewPadding.bottom;

    // Positioned, so only the toast's own box is hit-testable: taps beside it
    // still reach the sheet or page underneath.
    return Positioned(
      left: AppSpacing.lg + media.viewPadding.left,
      right: AppSpacing.lg + media.viewPadding.right,
      bottom: AppSpacing.md + inset,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(_curve),
          child: Dismissible(
            key: const ValueKey('app-toast'),
            onDismissed: (_) {
              _timer?.cancel();
              widget.onDismissed();
            },
            child: Semantics(
              container: true,
              liveRegion: true,
              child: Material(
                type: MaterialType.transparency,
                child: _ToastCard(
                  message: widget.message,
                  type: widget.type,
                  actionLabel: widget.actionLabel,
                  onAction: _runAction,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The toast's card: accent colours and icon per [ToastType], the message and
/// an optional action.
class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.message,
    required this.type,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final ToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  // A toast action keeps a full tap-target height inside the toast row.
  static final _cta = TextButton.styleFrom(minimumSize: _min); // style-ok
  static const _min = Size(0, AppSize.tapTarget);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        bgColor = AppColors.successSoft;
        borderColor = AppColors.success;
        iconColor = AppColors.success;
        textColor = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.info:
        bgColor = AppColors.primarySoft;
        borderColor = AppColors.primaryBorder;
        iconColor = AppColors.primary;
        textColor = AppColors.primaryDeep;
        icon = Icons.info_rounded;
        break;
      case ToastType.warning:
        bgColor = AppColors.warningSoft;
        borderColor = AppColors.warning;
        iconColor = AppColors.warning;
        textColor = AppColors.warningOnSoft;
        icon = Icons.warning_amber_rounded;
        break;
      case ToastType.error:
        bgColor = AppColors.dangerSoft;
        borderColor = AppColors.dangerBorder;
        iconColor = AppColors.danger;
        textColor = AppColors.dangerStrong;
        icon = Icons.error_outline_rounded;
        break;
    }

    final label = actionLabel;
    final hasAction = label != null && onAction != null;
    Widget action() => TextButton(
      onPressed: onAction,
      style: _cta,
      child: Text(label!, maxLines: 2),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: AppSize.iconSm),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  // B2 (batch-1 review): a toast must never hide its
                  // message. 4 lines fits every message in this app at
                  // <= 140 chars; longer than that is genuinely
                  // unbounded caller input, so it still gets an
                  // ellipsis rather than pushing the toast off-screen.
                  maxLines: 4,
                  overflow: message.length <= 140
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: context.text.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (hasAction && message.length <= 40) action(),
            ],
          ),
          // Long messages get the action on its own row so the message
          // keeps its full width instead of fighting the button for space.
          if (hasAction && message.length > 40)
            Align(alignment: Alignment.centerRight, child: action()),
        ],
      ),
    );
  }
}
