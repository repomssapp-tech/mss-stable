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

  Map<String, Color> _getTagColors(String tag, String category) {
    final cleanTag = tag.toLowerCase().trim();
    final cleanCat = category.toLowerCase().trim();

    if (cleanTag == cleanCat) {
      if (cleanCat.contains('farmer') ||
          cleanCat.contains('agri') ||
          cleanCat.contains('rural')) {
        return {'text': const Color(0xFF15803D), 'bg': const Color(0xFFDCFCE7)};
      } else if (cleanCat.contains('student') ||
          cleanCat.contains('edu') ||
          cleanCat.contains('scholarship')) {
        return {'text': const Color(0xFF6D28D9), 'bg': const Color(0xFFF5F3FF)};
      } else if (cleanCat.contains('business') ||
          cleanCat.contains('msme') ||
          cleanCat.contains('employment')) {
        return {'text': const Color(0xFF1E3A8A), 'bg': const Color(0xFFDBEAFE)};
      } else if (cleanCat.contains('women') ||
          cleanCat.contains('female') ||
          cleanCat.contains('girl') ||
          cleanCat.contains('child')) {
        return {'text': const Color(0xFFBE185D), 'bg': const Color(0xFFFCE7F3)};
      } else {
        return {'text': const Color(0xFF0F766E), 'bg': const Color(0xFFCCFBF1)};
      }
    }

    if (cleanTag.contains('central') ||
        cleanTag.contains('national') ||
        cleanTag.contains('india')) {
      return {'text': const Color(0xFFC2410C), 'bg': const Color(0xFFFFEDD5)};
    } else if (cleanTag.contains('state') ||
        cleanTag.contains('tamil') ||
        cleanTag.contains('tn')) {
      return {'text': const Color(0xFF7C3AED), 'bg': const Color(0xFFF3E8FF)};
    } else if (cleanTag.contains('loan') || cleanTag.contains('credit')) {
      return {'text': const Color(0xFFB91C1C), 'bg': const Color(0xFFFEE2E2)};
    } else if (cleanTag.contains('subsidy') || cleanTag.contains('grant')) {
      return {'text': const Color(0xFF047857), 'bg': const Color(0xFFD1FAE5)};
    } else if (cleanTag.contains('msme')) {
      return {'text': const Color(0xFF15803D), 'bg': const Color(0xFFE8F5E9)};
    }

    final hash = cleanTag.hashCode;
    final index = hash.abs() % 4;
    if (index == 0) {
      return {'text': const Color(0xFF0369A1), 'bg': const Color(0xFFE0F2FE)};
    } else if (index == 1) {
      return {'text': const Color(0xFF0F766E), 'bg': const Color(0xFFE6FFFA)};
    } else if (index == 2) {
      return {'text': const Color(0xFF6D28D9), 'bg': const Color(0xFFF5F3FF)};
    } else {
      return {'text': const Color(0xFFB45309), 'bg': const Color(0xFFFEF3C7)};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only the active language drives this card's content. Listening to the
    // whole AppProvider rebuilt (and re-localized) every visible card on any
    // notifyListeners(); bookmark/profile state arrives via widget props.
    final lang = context.select<AppProvider, String>((p) => p.selectedLanguage);
    if (_lang != lang) _recomputeDerived(lang);

    final isTa = lang == 'ta';
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
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
                  // Left: Circular Logo Container (72x72)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
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
                          size: 58,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),

                  // Middle Content Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Match Badge Pill & Title block
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AutoTranslatedText(
                                locScheme.name,
                                language: lang,
                                style: AppGoogleFonts.poppins(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                  height: isTa ? 1.35 : 1.25,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.showMatchPercentage) ...[
                              const SizedBox(width: AppSpacing.tight),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.tight,
                                  vertical: AppSpacing.hairline,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  context.l10n.matchPercentageFormat(
                                    widget.result.percentage,
                                  ),
                                  style: AppGoogleFonts.inter(
                                    color: const Color(0xFF2E7D32),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitleText.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitleText,
                            style: AppGoogleFonts.inter(
                              fontSize: isTa ? 10.5 : 11.0,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
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
                                  style: AppGoogleFonts.inter(
                                    fontSize: isTa ? 9.0 : 9.5,
                                    fontWeight: FontWeight.bold,
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
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: widget.onBookmarkToggle,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFDBEAFE),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: const Color(0xFF2563EB),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: () async {
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
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFDBEAFE),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.share_outlined,
                              color: Color(0xFF2563EB),
                              size: 16,
                            ),
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
