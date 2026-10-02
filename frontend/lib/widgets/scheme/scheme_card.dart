import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/l10n.dart';
import '../../models/scheme_model.dart';
import '../../models/localized_scheme.dart';
import '../../services/recommendation/recommendation_engine.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/centralized_translator.dart';
import '../../utils/emblem_helper.dart';
import '../common/app_toast.dart';
import '../../utils/app_spacing.dart';

class SchemeCard extends StatefulWidget {
  final Scheme scheme;
  final RecommendationResult result;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTap;
  final bool showActions;
  final bool showMatchPercentage;

  const SchemeCard({
    super.key,
    required this.scheme,
    required this.result,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onTap,
    this.showActions = true,
    this.showMatchPercentage = true,
  });

  @override
  State<SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<SchemeCard> {
  // toLocalized() plus the tag/subtitle derivation is expensive in Tamil mode
  // (dozens of translator calls, several list maps). This widget rebuilds
  // whenever its parent results list rebuilds -- i.e. on every AppProvider
  // notifyListeners() -- so cache the derived values and only recompute them
  // when the source scheme or the active language actually changes.
  String? _lang;
  LocalizedScheme? _loc;
  List<String>? _tags;
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
    final isTa = lang == 'ta';

    final rawTags = List<String>.from(_getOtherTags(loc))
      ..sort((a, b) => a.length.compareTo(b.length));
    final tags = isTa
        ? rawTags
              .map((t) => CentralizedTranslator.instance.translateTag(t))
              .toList()
        : rawTags;

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

  List<String> _getOtherTags(LocalizedScheme locScheme) {
    final List<String> list = [];

    void addSplit(String value) {
      if (value.isNotEmpty) {
        list.addAll(
          value
              .split(',')
              .map((s) => s.trim())
              .where(
                (s) =>
                    s.isNotEmpty &&
                    s.toLowerCase() != 'pending official verification',
              ),
        );
      }
    }

    addSplit(locScheme.category);
    addSplit(locScheme.schemeType);
    addSplit(locScheme.sector);
    if (list.isEmpty) list.addAll(locScheme.glanceChips);

    final Set<String> seen = {};
    final List<String> uniqueList = [];

    final sponsoringLower = locScheme.sponsoringBody.toLowerCase();
    final govLevelLower = locScheme.governmentLevel.toLowerCase();
    final stateLower = locScheme.state.toLowerCase();

    for (final tag in list) {
      final lower = tag.toLowerCase();
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
                  child: ClipOval(
                    child: _buildSchemeLogo(context, widget.scheme, size: 72),
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
                            child: Text(
                              locScheme.name,
                              style: GoogleFonts.poppins(
                                fontSize: isTa ? 13.0 : 14.0,
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
                                style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
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
                        children: tags.map((tag) {
                          final colors = _getTagColors(
                            tag,
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
                              tag,
                              style: GoogleFonts.inter(
                                fontSize: isTa ? 9.0 : 9.5,
                                fontWeight: FontWeight.bold,
                                color: colors['text'],
                              ),
                            ),
                          );
                        }).toList(),
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
                            border: Border.all(color: const Color(0xFFDBEAFE)),
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
                          final shareText = destination.isNotEmpty
                              ? '${locScheme.name}\n$destination'
                              : locScheme.name;
                          await Clipboard.setData(
                            ClipboardData(text: shareText),
                          );
                          if (context.mounted) {
                            AppToast.showSuccess(
                              context,
                              context.l10n.schemeCopiedToast,
                            );
                          }
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFDBEAFE)),
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
    );
  }
}
