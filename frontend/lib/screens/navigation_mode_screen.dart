import 'package:flutter/material.dart';
import '../utils/app_radius.dart';
import '../utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'companion_mode/saarthi_welcome_screen.dart';
import 'regular_mode/language_selection_screen.dart';
import 'regular_mode/basic_profile_screen.dart';
import '../providers/app_state_provider.dart';
import '../main.dart';
import '../l10n/l10n.dart';
import '../utils/app_size.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text.dart';

enum NavigationMode { regular, companion }

class NavigationModeScreen extends StatefulWidget {
  final Function(NavigationMode)? onContinue;

  const NavigationModeScreen({super.key, this.onContinue});

  @override
  State<NavigationModeScreen> createState() => _NavigationModeScreenState();
}

class _NavigationModeScreenState extends State<NavigationModeScreen> {
  NavigationMode _selectedMode = NavigationMode.regular;

  // Constants for design consistency
  static const double kPaddingSide = 24.0;
  static const double kCardRadius = 28.0;
  static const Color kPrimaryBlue = AppColors.primary;
  static const Color kSlate800 = AppColors.textPrimary;
  static const Color kSlate500 = AppColors.textMuted;
  static const Color kBorderGrey = AppColors.border;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image Layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background/Login_bg.webp', // Using webp asset from the project
              fit: BoxFit.cover,
            ),
          ),

          // 2. Foreground Layer (Responsive scroll layout)
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Back Button (Top Left)
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.md,
                                  top: AppSpacing.sm,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: kSlate800,
                                    size: 24,
                                  ),
                                  tooltip: context.l10n.back,
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const LanguageSelectionScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Middle Content
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: kPaddingSide,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // App Logo
                                  Image.asset(
                                    'assets/images/Logo/Logo.webp',
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Header Text Group
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: context.text.titleMedium
                                              .copyWith(color: kSlate800),
                                          children: [
                                            TextSpan(
                                              text: context
                                                  .l10n
                                                  .navChooseYourPrefix,
                                            ),
                                            TextSpan(
                                              text: context
                                                  .l10n
                                                  .navExperienceSuffix,
                                              style: const TextStyle(
                                                color: kPrimaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        context.l10n.navSelectStyleSubtitle,
                                        textAlign: TextAlign.center,
                                        style: context.text.body.copyWith(
                                          color: kSlate500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Option Cards Group
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      NavigationOptionCard(
                                        mode: NavigationMode.regular,
                                        isSelected:
                                            _selectedMode ==
                                            NavigationMode.regular,
                                        title: context
                                            .l10n
                                            .navRegularNavigationTitle,
                                        subtitle:
                                            context.l10n.navModeRegularSubtitle,
                                        icon: Icons.explore_rounded,
                                        iconColor: kPrimaryBlue,
                                        iconBgColor: AppColors.primarySoft,
                                        chips: [
                                          ChipInfo(
                                            Icons.bolt,
                                            context.l10n.navChipFastSimple,
                                          ),
                                          ChipInfo(
                                            Icons.phone_android,
                                            context.l10n.navChipTraditionalUi,
                                          ),
                                          ChipInfo(
                                            Icons.touch_app,
                                            context.l10n.navChipSelfPaced,
                                          ),
                                          ChipInfo(
                                            Icons.auto_awesome,
                                            context.l10n.navChipAiAnytime,
                                          ),
                                        ],
                                        onTap: () {
                                          setState(() {
                                            _selectedMode =
                                                NavigationMode.regular;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      NavigationOptionCard(
                                        mode: NavigationMode.companion,
                                        isSelected:
                                            _selectedMode ==
                                            NavigationMode.companion,
                                        title: context.l10n.navAiCompanionTitle,
                                        subtitle: context
                                            .l10n
                                            .navModeCompanionSubtitle,
                                        icon: Icons.support_agent_rounded,
                                        iconColor: AppColors.primary,
                                        iconBgColor: AppColors.primarySoft,
                                        chips: [
                                          ChipInfo(
                                            Icons.mic,
                                            context.l10n.navChipVoiceFirst,
                                          ),
                                          ChipInfo(
                                            Icons.person,
                                            context.l10n.navChipPersonalized,
                                          ),
                                          ChipInfo(
                                            Icons.lightbulb_outline,
                                            context.l10n.navChipSmartRecs,
                                          ),
                                          ChipInfo(
                                            Icons.co_present,
                                            context.l10n.navChipExplainsScreens,
                                          ),
                                        ],
                                        onTap: () {
                                          setState(() {
                                            _selectedMode =
                                                NavigationMode.companion;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Info Card
                                  InfoCard(
                                    title: context.l10n.navSwitchAnytimeTitle,
                                    description:
                                        context.l10n.navSwitchAnytimeDesc,
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Bottom Navigation Bar Area for Sticky Button
                            Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg,
                                top: AppSpacing.sm,
                              ),
                              alignment: Alignment.center,
                              child: PrimaryButton(
                                width: screenWidth * 0.78,
                                onPressed: () async {
                                  final provider = Provider.of<AppProvider>(
                                    context,
                                    listen: false,
                                  );
                                  await provider.changeNavigationMode(
                                    _selectedMode == NavigationMode.companion
                                        ? 'companion'
                                        : 'regular',
                                  );
                                  if (!context.mounted) return;

                                  if (widget.onContinue != null) {
                                    widget.onContinue!(_selectedMode);
                                  } else {
                                    if (provider.profile.profileCompleted) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const MainTabsContainer(),
                                        ),
                                      );
                                    } else if (_selectedMode ==
                                        NavigationMode.companion) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SaarthiWelcomeScreen(),
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const BasicProfileScreen(),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationOptionCard extends StatelessWidget {
  final NavigationMode mode;
  final bool isSelected;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final List<ChipInfo> chips;
  final VoidCallback onTap;

  const NavigationOptionCard({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final activeBg = AppColors.primarySoft;

    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ), // Reduced card padding
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(
            _NavigationModeScreenState.kCardRadius,
          ), // Radius 28
          border: Border.all(
            color: isSelected
                ? activeColor
                : _NavigationModeScreenState.kBorderGrey,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content layout (Row)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Illustration / Icon on the left (Slightly smaller padding)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24, // Slightly smaller
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Middle Text & Chips Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: context.text.titleSmall.copyWith(
                          // Tighter font sizing
                          color: _NavigationModeScreenState.kSlate800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.hairline),
                      Text(
                        subtitle,
                        style: context.text.bodySmall.copyWith(
                          // Tighter font sizing
                          color: _NavigationModeScreenState.kSlate500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm), // Tighter spacing
                      // Vertical Layout for Feature Chips
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < chips.length; i++) ...[
                            if (i > 0)
                              const SizedBox(
                                height: AppSpacing.xs,
                              ), // Reduced chip spacing
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.hairline,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : iconBgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              // Readable at every language: a long label
                              // (Tamil) wraps to a second line instead of
                              // being scaled down to an unreadable size.
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    chips[i].icon,
                                    color: iconColor,
                                    size: AppSize.iconSm,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      chips[i].label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.label.copyWith(
                                        color: iconColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
            ),

            // Radio Button in top right corner
            Positioned(
              top: 0,
              right: 0,
              child: isSelected
                  ? Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.hairline),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    )
                  : Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderStrong,
                          width: 1.5,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String description;

  const InfoCard({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ), // More compact padding
      decoration: BoxDecoration(
        color: AppColors.primarySoft, // Blue tinted background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: context.text.button.copyWith(
                    // Slightly more compact
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: context.text.bodySmall.copyWith(
                    // Slightly more compact
                    color: AppColors.primaryStrong,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final double width;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.width,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 58, // Height is exactly 58 as specified
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), // Large radius
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(context.l10n.navContinueButton)),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.arrow_forward_rounded, size: AppSize.icon),
          ],
        ),
      ),
    );
  }
}

class ChipInfo {
  final IconData icon;
  final String label;

  const ChipInfo(this.icon, this.label);
}
