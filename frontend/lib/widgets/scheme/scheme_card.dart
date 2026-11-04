import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/l10n.dart';
import '../../models/scheme_model.dart';
import '../../models/localized_scheme.dart';
import '../../services/recommendation/recommendation_engine.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/centralized_translator.dart';
import '../../utils/emblem_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_size.dart';
import '../../utils/app_radius.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text.dart';
import '../../utils/chip_list.dart';
import '../../utils/share_text.dart';
import '../common/auto_translated_text.dart';

class SchemeCard extends StatefulWidget {
  final Scheme scheme;
  final RecommendationResult result;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTap;
  final bool showActions;
  final bool showMatchPercentage;

  /// The scheme was searched for by name but does not apply to this user (or
  /// is hidden by the active filters); shown with a distinct outlined pill.
  final bool notApplicable;

  /// With [notApplicable]: hidden only by the Filter sheet, not by the
  /// user's eligibility, so the pill says so (test report BUG-09).
  final bool filterMismatch;

  const SchemeCard({
    super.key,
    required this.scheme,
    required this.result,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onTap,
    this.showActions = true,
    this.showMatchPercentage = true,
    this.notApplicable = false,
    this.filterMismatch = false,
  });

  @override
  State<SchemeCard> createState() => _SchemeCardState();
}

/// Outlined amber pill with an icon: deliberately unlike the filled, coloured
/// tag chips so "this does not apply to you" reads at a glance.
class _NotApplicablePill extends StatelessWidget {
  const _NotApplicablePill({required this.filterMismatch});

  final bool filterMismatch;

  static String label(BuildContext context, {required bool filterMismatch}) =>
      filterMismatch
      ? context.l10n.schemeNotMatchingFilters
      : context.l10n.schemeNotApplicable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: AppColors.warningText, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.block_rounded,
            size: AppSpacing.md,
            color: AppColors.warningText,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label(context, filterMismatch: filterMismatch),
              style: context.text.label.copyWith(color: AppColors.warningText),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemeCardState extends State<SchemeCard> {
  // toLocalized() plus the tag/subtitle derivation is expensive in Tamil mode
  // (dozens of translator calls, several list maps). This widget rebuilds
  // whenever its parent results list rebuilds -- i.e. on every AppProvider
  // notifyListeners() -- so cache the derived values and only recompute them
  // when the source scheme or the active language actually changes.
  String? _lang;
  LocalizedScheme? _loc;

  /// (shown text, English key). The key drives chip colour and order so
  /// both stay the same in every language (test report L10N-09 / NEW-07).
  List<(String, String)>? _tags;
  String? _subtitle;

  @override
  void didUpdateWidget(covariant SchemeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.scheme, widget.scheme)) {
      _lang = null; // invalidate; build() recomputes for the new scheme
    }
  }

  void _recomputeDerived(String lang) {
    final loc = widget.scheme.toLocalized(lang);
    final en = lang == 'en' ? loc : widget.scheme.toLocalized('en');

    final rawTags = List<(String, String)>.from(_getOtherTags(loc, en))
      ..sort((a, b) => a.$2.length.compareTo(b.$2.length));
    // Generic labels (level, state, category) follow the active language;
    // English leaves them unchanged.
    final tags = [
      for (final (shown, key) in rawTags)
        (CentralizedTranslator.instance.localizeTagFor(lang, shown), key),
    ];

    final department = loc.sponsoringBody.isNotEmpty
        ? loc.sponsoringBody
        : loc.issuingBody;
    final level = loc.state.isNotEmpty && loc.state != 'All India'
        ? loc.state
        : loc.governmentLevel;
    final subtitle = [
      if (department.isNotEmpty) department,
      if (level.isNotEmpty) level,
    ].join(' • ');

    _lang = lang;
    _loc = loc;
    _tags = tags;
    _subtitle = subtitle;
  }

  List<(String, String)> _getOtherTags(
    LocalizedScheme locScheme,
    LocalizedScheme en,
  ) {
    final List<(String, String)> list = [];

    // Pairs each shown chip with its English original when both split into
    // the same number of chips; otherwise the shown text is its own key.
    void addPaired(List<String> shown, List<String> english) {
      final paired = shown.length == english.length;
      for (var i = 0; i < shown.length; i++) {
        list.add((shown[i], paired ? english[i] : shown[i]));
      }
    }

    // Commas inside brackets stay in one chip (see splitChipList).
    void addSplit(String value, String enValue) =>
        addPaired(splitChipList(value), splitChipList(enValue));

    addSplit(locScheme.category, en.category);
    addSplit(locScheme.schemeType, en.schemeType);
    addSplit(locScheme.sector, en.sector);
    if (list.isEmpty) addPaired(locScheme.glanceChips, en.glanceChips);

    final Set<String> seen = {};
    final List<(String, String)> uniqueList = [];

    final sponsoringLower = locScheme.sponsoringBody.toLowerCase();
    final govLevelLower = locScheme.governmentLevel.toLowerCase();
    final stateLower = locScheme.state.toLowerCase();

    for (final tag in list) {
      final lower = tag.$1.toLowerCase();
      final isSubtitleTerm =
          sponsoringLower.contains(lower) ||
          govLevelLower.contains(lower) ||
          stateLower.contains(lower);
      if (!seen.contains(lower) && !isSubtitleTerm) {
        seen.add(lower);
        uniqueList.add(tag);
      }
    }

    return uniqueList.take(3).toList();
  }

  Widget _buildSchemeLogo(
    BuildContext context,
    Scheme scheme, {
    double size = 48,
  }) {
    final emblemAsset = EmblemHelper.getEmblemAsset(
      governmentLevel: scheme.governmentLevel,
      state: scheme.state,
      schemeCode: scheme.schemeCode,
      sponsoringBody: scheme.sponsoringBody,
      name: scheme.name,
    );

    // Emblem source WebPs are ~900-1024px square but render at `size` dp.
    // Cap the decode to the physical pixels actually shown so a scrolling
    // results list doesn't hold a multi-MB bitmap per card.
    final int decodePx = (size * MediaQuery.devicePixelRatioOf(context))
        .round();

    return Image.asset(
      emblemAsset,
      fit: BoxFit.contain,
      width: size,
      height: size,
      cacheWidth: decodePx,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/States assets/Indian emblem.webp',
          fit: BoxFit.contain,
          width: size,
          height: size,
          cacheWidth: decodePx,
        );
      },
    );
  }

  /// One meaning, one colour, the same on every screen (see [styleForTag]),
  /// instead of a per-card palette with hash-picked hues.
  Map<String, Color> _getTagColors(String tag, String category) {
    final style = styleForTag(tag);
    return {'text': style.text, 'bg': style.background};
  }

  @override
  Widget build(BuildContext context) {
    // Only the active language drives this card's content. Listening to the
    // whole AppProvider rebuilt (and re-localized) every visible card on any
    // notifyListeners(); bookmark/profile state arrives via widget props.
    final lang = context.select<AppProvider, String>((p) => p.selectedLanguage);
    if (_lang != lang) _recomputeDerived(lang);

    final locScheme = _loc!;
    final tags = _tags!;
    final subtitleText = _subtitle!;

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // The pill is read first by TalkBack (test report NEW-09).
      child: Semantics(
        label: widget.notApplicable
            ? _NotApplicablePill.label(
                context,
                filterMismatch: widget.filterMismatch,
              )
            : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: the emblem of who runs the scheme, in a circle.
                  Container(
                    width: AppSize.avatar,
                    height: AppSize.avatar,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                        width: AppSize.borderWidth,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    // The square emblem is drawn at 80% so its bottom text
                    // ("Government of India") stays inside the circle (UI-05).
                    child: ClipOval(
                      child: Center(
                        child: _buildSchemeLogo(
                          context,
                          widget.scheme,
                          size: AppSize.avatar * 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Middle Content Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title, then the match badge on its own line, so a
                        // long name or a Tamil badge never squeezes the other.
                        AutoTranslatedText(
                          locScheme.name,
                          language: lang,
                          style: context.text.cardTitle.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.showMatchPercentage) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.hairline,
                            ),
                            decoration: BoxDecoration(
                              color: AppTagStyle.level.background,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              context.l10n.matchPercentageFormat(
                                widget.result.percentage,
                              ),
                              style: context.text.label.copyWith(
                                color: AppTagStyle.level.text,
                              ),
                            ),
                          ),
                        ],
                        if (subtitleText.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitleText,
                            style: context.text.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),

                        // Tags Row
                        Wrap(
                          spacing: AppSpacing.tight,
                          runSpacing: AppSpacing.tight,
                          children: [
                            if (widget.notApplicable)
                              _NotApplicablePill(
                                filterMismatch: widget.filterMismatch,
                              ),
                            ...tags.map((tag) {
                              final (shown, key) = tag;
                              final colors = _getTagColors(
                                key,
                                widget.scheme.category,
                              );
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: colors['bg'],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  shown,
                                  style: context.text.label.copyWith(
                                    color: colors['text'],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Far Right Actions Column
                  if (widget.showActions) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: widget.onBookmarkToggle,
                          tooltip: widget.isBookmarked
                              ? context.l10n.removeSavedTooltip
                              : context.l10n.saveSchemeTooltip,
                          icon: Icon(
                            widget.isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: AppColors.primary,
                            size: AppSize.icon,
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.shareSchemeDetailsTooltip,
                          onPressed: () async {
                            final destination =
                                widget.scheme.applicationUrl.isNotEmpty
                                ? widget.scheme.applicationUrl
                                : widget.scheme.officialWebsite;
                            await shareText(
                              context,
                              destination.isNotEmpty
                                  ? '${locScheme.name}\n$destination'
                                  : locScheme.name,
                              copiedMessage: context.l10n.schemeCopiedToast,
                            );
                          },
                          icon: const Icon(
                            Icons.share_outlined,
                            color: AppColors.iconMuted,
                            size: AppSize.icon,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
