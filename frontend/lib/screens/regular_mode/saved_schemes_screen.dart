import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../models/scheme_model.dart';
import '../../models/localized_scheme.dart';
import '../../l10n/l10n.dart';
import '../../services/catalog/centralized_translator.dart';
import 'scheme_details_screen.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_size.dart';
import '../../utils/app_spacing.dart';
import '../../utils/feedback_helper.dart';
import '../../widgets/common/app_icon_button.dart';
import '../../widgets/common/app_tappable.dart';
import '../../widgets/scheme/inactive_scheme_badge.dart';
import '../../utils/app_text.dart';
import '../../widgets/common/auto_translated_text.dart';
import '../../widgets/common/sign_in_required_sheet.dart';

class SavedSchemesScreen extends StatefulWidget {
  const SavedSchemesScreen({super.key});

  @override
  State<SavedSchemesScreen> createState() => _SavedSchemesScreenState();
}

class _SavedSchemesScreenState extends State<SavedSchemesScreen> {
  int _activeTab = 0; // 0 = All Saved, 1 = Recently viewed

  void _selectTab(int index) {
    if (_activeTab == index) return;
    AppFeedback.selection();
    setState(() => _activeTab = index);
  }

  /// Two-segment switch between the saved list and recently viewed.
  Widget _buildTabBar(int savedCount) {
    Widget segment(int index, String label) {
      final selected = _activeTab == index;
      return Expanded(
        child: AppTappable(
          onTap: () => _selectTab(index),
          selected: selected,
          semanticLabel: label,
          borderRadius: AppRadius.mdAll,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: AppRadius.mdAll,
            border: selected
                ? Border.all(color: AppColors.border)
                : Border.all(color: Colors.transparent),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.button.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.lgAll,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            segment(0, context.l10n.allSavedTabFormat(savedCount)),
            const SizedBox(width: AppSpacing.xs),
            segment(1, context.l10n.recentlyViewedTab),
          ],
        ),
      ),
    );
  }

  void _remove(AppProvider provider, Scheme scheme, bool recentTab) {
    if (recentTab) {
      provider.removeFromRecentlyViewed(scheme.id);
    } else {
      provider.toggleBookmark(scheme.id);
    }
  }

  /// "Central" / "State" in the app language; any other level as the
  /// catalog's own tag translation.
  String _levelLabel(String level) {
    switch (level.trim().toLowerCase()) {
      case 'central':
        return context.l10n.filterCentral;
      case 'state':
        return context.l10n.filterState;
    }
    return CentralizedTranslator.instance.localizeTag(level);
  }

  IconData _iconFor(Scheme scheme) {
    final category = scheme.category.toLowerCase();
    if (category.contains('guarantee') || category.contains('cgtmse')) {
      return Icons.shield_outlined;
    }
    if (category.contains('loan') ||
        category.contains('business') ||
        category.contains('finance') ||
        category.contains('msme')) {
      return Icons.currency_rupee_rounded;
    }
    return Icons.description_outlined;
  }

  Widget _buildSchemeCard(
    BuildContext context,
    Scheme scheme,
    AppProvider provider, {
    required bool recentTab,
  }) {
    final locScheme = scheme.toLocalized(provider.selectedLanguage);
    final meta = [
      if (locScheme.governmentLevel.isNotEmpty)
        _levelLabel(locScheme.governmentLevel),
      if (locScheme.schemeType.isNotEmpty)
        locScheme.schemeType
      else if (locScheme.category.isNotEmpty)
        locScheme.category,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border, width: AppSize.borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppFeedback.light();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchemeDetailsScreen(
                  scheme: scheme,
                  analyticsEntryPoint: 'saved',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: AppSpacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                  width: AppSize.avatarSm,
                  height: AppSize.avatarSm,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _iconFor(scheme),
                    color: AppColors.primary,
                    size: AppSize.icon,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoTranslatedText(
                          locScheme.name,
                          language: provider.selectedLanguage,
                          style: context.text.cardTitle.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.hairline),
                          Text(
                            meta,
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        // A saved scheme the catalog has since closed stays
                        // in the list (the user saved it) but says so.
                        if (!scheme.isActive) ...[
                          const SizedBox(height: AppSpacing.xs),
                          const InactiveSchemeBadge(),
                        ],
                        if (locScheme.overview.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            locScheme.overview,
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (recentTab)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.iconMuted,
                      size: AppSize.icon,
                    ),
                    onSelected: (value) {
                      if (value == 'remove') {
                        _remove(provider, scheme, recentTab);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(context.l10n.savedRemoveFromRecentTooltip),
                      ),
                    ],
                  )
                else
                  AppIconButton(
                    icon: Icons.bookmark_rounded,
                    color: AppColors.primary,
                    semanticLabel: context.l10n.removeSaved,
                    onPressed: () => _remove(provider, scheme, recentTab),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppProvider provider, {
    required String title,
    required String description,
    bool signIn = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: AppSize.avatarLg,
                    height: AppSize.avatarLg,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_border_rounded,
                      color: AppColors.iconMuted,
                      size: AppSize.iconLg,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.text.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: context.text.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // A guest cannot save: the way forward is signing in.
                  if (signIn)
                    ElevatedButton(
                      key: const ValueKey('saved-guest-sign-in'),
                      onPressed: () => openSignIn(context),
                      child: Text(context.l10n.guestSignInAction),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => provider.updateTabIndex(2),
                      child: Text(context.l10n.navDiscover),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final bookmarks = provider.bookmarkedSchemes;
    final recentlyViewed = provider.recentlyViewedSchemes;

    final List<Scheme> displaySchemes = _activeTab == 0
        ? bookmarks
        : recentlyViewed;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.savedTitle,
                      style: context.text.headline.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.hairline),
                    Text(
                      bookmarks.isNotEmpty
                          ? context.l10n.savedSubtitleCountFormat(
                              bookmarks.length,
                            )
                          : provider.isGuest
                          ? context.l10n.guestSavedSignInDesc
                          : context.l10n.noSavedSchemesDesc,
                      style: context.text.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildTabBar(bookmarks.length),
            Expanded(
              child: displaySchemes.isEmpty
                  ? _buildEmptyState(
                      context,
                      provider,
                      title: _activeTab == 0
                          ? context.l10n.noSavedSchemes
                          : context.l10n.savedRecentlyViewedEmptyTitle,
                      description: _activeTab != 0
                          ? context.l10n.savedRecentlyViewedEmptyDesc
                          : provider.isGuest
                          ? context.l10n.guestSavedSignInDesc
                          : context.l10n.noSavedSchemesDesc,
                      signIn: _activeTab == 0 && provider.isGuest,
                    )
                  : ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      // Same 16dp inset as the title and the tab bar, in both
                      // tabs (the cards used to run edge to edge).
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: displaySchemes.length,
                      itemBuilder: (context, index) {
                        return _buildSchemeCard(
                          context,
                          displaySchemes[index],
                          provider,
                          recentTab: _activeTab == 1,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
