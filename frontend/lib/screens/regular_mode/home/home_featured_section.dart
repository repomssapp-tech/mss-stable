import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../widgets/common/auto_translated_text.dart';
import '../../../models/scheme_filter.dart';
import '../../../models/scheme_model.dart';
import '../../../providers/app_state_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../scheme_details_screen.dart';
import 'guest_state_schemes.dart';
import 'home_promo_carousel_section.dart';

/// One Featured slide: a scheme the user qualifies for, or one newly added to
/// the catalog that applies where they are.
@visibleForTesting
class FeaturedSlide {
  const FeaturedSlide.best(this.scheme, this.matchPercent) : isNew = false;
  const FeaturedSlide.added(this.scheme) : isNew = true, matchPercent = null;

  final Scheme scheme;
  final bool isNew;
  final int? matchPercent;
}

/// Picks the Featured slides: the user's top [perKind] matches (score > 0),
/// then the [perKind] most recently added schemes that apply in [state] and
/// are not already shown. Either list may be short or empty.
@visibleForTesting
List<FeaturedSlide> pickFeaturedSlides({
  required List<MapEntry<Scheme, int>> ranked,
  required List<Scheme> all,
  required String state,
  int perKind = 3,
}) {
  final best = [
    for (final e in ranked.take(perKind)) FeaturedSlide.best(e.key, e.value),
  ];
  final shown = {for (final s in best) s.scheme.id};
  final fresh =
      all
          .where(
            (s) =>
                s.addedOn.isNotEmpty &&
                !shown.contains(s.id) &&
                (state.isEmpty || schemeAppliesInState(s, state)),
          )
          .toList()
        ..sort((a, b) => b.addedOn.compareTo(a.addedOn));
  return [...best, for (final s in fresh.take(perKind)) FeaturedSlide.added(s)];
}

/// Home's Featured carousel: full-width cards of the schemes the user
/// qualifies for best and the newest schemes for their state. It moves only
/// when swiped, so slow readers and longer Tamil names are never cut off
/// mid-read. Without any (no profile yet, catalog still loading) it shows the
/// promo cards instead.
class HomeFeaturedSection extends StatefulWidget {
  const HomeFeaturedSection({super.key});

  /// Card height at the default text size; it grows with the text scale.
  static const double cardHeight = 168;

  @override
  State<HomeFeaturedSection> createState() => _HomeFeaturedSectionState();
}

class _HomeFeaturedSectionState extends State<HomeFeaturedSection> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    // A guest has no profile match, so no "Best for you" slides: only the
    // newest schemes for their state.
    final guest = provider.isGuest;
    final slides = pickFeaturedSlides(
      ranked: [
        if (!guest)
          for (final e in provider.recommendedSchemes)
            if (e.value.score > 0) MapEntry(e.key, e.value.percentage),
      ],
      all: provider.allSchemes,
      state: guest
          ? guestStateFor(
              profileState: provider.profile.state,
              language: provider.selectedLanguage,
            )
          : provider.profile.state,
    );
    if (slides.isEmpty) return const HomePromoCarouselSection();
    if (_index >= slides.length) _index = 0;

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final still = MediaQuery.disableAnimationsOf(context);

    return Column(
      children: [
        SizedBox(
          // spacing-ok: card height, not spacing
          height: HomeFeaturedSection.cardHeight * textScale.clamp(1.0, 1.6),
          child: PageView.builder(
            controller: _pages,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _FeaturedCard(
              slide: slides[i],
              language: provider.selectedLanguage,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: still
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                width: i == _index ? AppSpacing.md : AppSpacing.tight,
                height: AppSpacing.tight,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.hairline,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.pillAll,
                  color: i == _index ? AppColors.primary : AppColors.border,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.slide, required this.language});

  final FeaturedSlide slide;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final local = slide.scheme.toLocalized(language);
    final added = DateTime.tryParse(slide.scheme.addedOn);
    final detail = slide.isNew
        ? (added == null
              ? null
              : l10n.homeFeaturedAddedOn(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(added),
                ))
        : l10n.matchPercentageFormat(slide.matchPercent ?? 0);
    final badge = slide.isNew
        ? l10n.homeFeaturedNewlyAdded
        : l10n.homeFeaturedBestForYou;
    final badgeColor = slide.isNew ? AppColors.success : AppColors.primary;
    final badgeBg = slide.isNew ? AppColors.successSoft : AppColors.primarySoft;
    final banner = slide.isNew
        ? 'assets/images/Background/new scheme banner.webp'
        : 'assets/images/Background/suggestion banner.webp';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Semantics(
        button: true,
        label: '$badge. ${local.name}',
        excludeSemantics: true,
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgAll,
              image: DecorationImage(
                image: ResizeImage(AssetImage(banner), width: 1080),
                fit: BoxFit.cover,
                // The art sits on the right; keep it in view on tall cards.
                alignment: Alignment.centerRight,
              ),
            ),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SchemeDetailsScreen(
                    scheme: slide.scheme,
                    analyticsEntryPoint: 'home',
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              badge,
                              style: context.text.label.copyWith(
                                color: badgeColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AutoTranslatedText(
                            local.name,
                            language: language,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.cardTitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (detail != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // The banner art sits on the right; keep the text clear.
                    const SizedBox(width: 112), // spacing-ok: banner art width
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
