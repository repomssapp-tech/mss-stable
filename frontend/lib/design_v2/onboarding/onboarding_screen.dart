// Ported from the v2 design (MSS mobile app onboarding). Layout values are
// the designer's 360pt canvas, scaled by [designScale].
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../highlight_text.dart';
import '../mss_design.dart';
import '../mss_widgets.dart';

/// First-launch onboarding: four swipeable pages (Meet MSS, One Simple
/// Solution, Know What You Qualify For, Just Ask Saarthi). Shown once, right
/// after the splash screen; [onDone] continues to language / sign-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onDone,
    this.schemeCount = 400,
  });

  final VoidCallback onDone;

  /// Shown on page 1 as "{count}+ Verified Schemes".
  final int schemeCount;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();

  void _next() => _controller.nextPage(
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeOutCubic,
  );
  void _skip() => _controller.animateToPage(
    3,
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOutCubic,
  );
  void _finish() => widget.onDone();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode every page's art up front, so swiping never waits on an image.
    for (final a in MssAssets.onboarding) {
      precacheImage(AssetImage(a), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignTextScale(
      child: Scaffold(
        body: PageView(
          controller: _controller,
          children: [
            _MeetMssPage(
              onNext: _next,
              onSkip: _skip,
              count: widget.schemeCount,
            ),
            _OneSolutionPage(onNext: _next, onSkip: _skip),
            _EligibilityPage(onNext: _next, onSkip: _skip),
            _SaarthiPage(onGetStarted: _finish),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 01 · Meet MSS (Orange) ─────────────────────────
class _MeetMssPage extends StatelessWidget {
  const _MeetMssPage({
    required this.onNext,
    required this.onSkip,
    required this.count,
  });
  final VoidCallback onNext, onSkip;
  final int count;

  @override
  Widget build(BuildContext context) {
    final s = designScale(context);
    final l10n = context.l10n;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const MssBackground(
          asset: MssAssets.bgOrange,
          fallback: Color(0xFFFFE7CC),
        ),
        Positioned(
          top: 58 * s,
          left: 28 * s,
          child: StepCounter(step: 1, s: s),
        ),
        Positioned(
          top: 54 * s,
          right: 22 * s,
          child: SkipButton(onTap: onSkip, s: s),
        ),
        Positioned(
          top: 96 * s,
          left: 18 * s,
          right: 18 * s,
          height: 300 * s,
          child: GlassPanel(s: s),
        ),
        Positioned(
          top: 120 * s,
          left: 40 * s,
          right: 40 * s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HighlightText(
                l10n.onbP1Title,
                highlight: pop(33, FontWeight.w800, MssColors.saffronDeep, s),
                style: pop(
                  33,
                  FontWeight.w800,
                  MssColors.ashokaBlue,
                  s,
                  height: 1.12,
                ),
              ),
              SizedBox(height: 14 * s),
              Text(
                l10n.onbP1Body,
                style: pop(
                  13.5,
                  FontWeight.w500,
                  MssColors.ashokaBlue,
                  s,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 14 * s),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14 * s,
                  vertical: 8 * s,
                ),
                decoration: BoxDecoration(
                  color: MssColors.ashokaBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8 * s,
                      height: 8 * s,
                      decoration: const BoxDecoration(
                        color: MssColors.saffron,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    Flexible(
                      child: Text(
                        l10n.onbP1Badge(count),
                        style: pop(13, FontWeight.w700, Colors.white, s),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: -40 * s,
          bottom: -4 * s,
          width: 250 * s,
          child: const Character(asset: MssAssets.charStudentPhone),
        ),
        Positioned(
          left: 28 * s,
          top: 420 * s,
          child: FloatChip(label: l10n.onbChipMsme, s: s, degrees: -4),
        ),
        Positioned(
          left: 104 * s,
          top: 462 * s,
          child: FloatChip(
            label: l10n.onbChipStartup,
            s: s,
            degrees: 3,
            bg: MssColors.ashokaBlue,
            fg: Colors.white,
          ),
        ),
        Positioned(
          left: 22 * s,
          top: 510 * s,
          child: FloatChip(
            label: l10n.onbChipLoans,
            s: s,
            degrees: 2,
            fg: MssColors.green,
          ),
        ),
        Positioned(
          left: 92 * s,
          top: 552 * s,
          child: FloatChip(
            label: l10n.onbChipSubsidy,
            s: s,
            degrees: -3,
            bg: MssColors.saffron,
          ),
        ),
        Positioned(
          left: 0,
          bottom: 70 * s,
          child: EdgeTabButton(
            s: s,
            tabColor: MssColors.saffron,
            button: PillButton(label: l10n.onbNext, onTap: onNext, s: s),
          ),
        ),
        Positioned(
          left: 26 * s,
          bottom: 32 * s,
          child: PageDots(active: 0, s: s),
        ),
      ],
    );
  }
}

// ───────────────────── 02 · One Simple Solution (Green) ─────────────────────
class _OneSolutionPage extends StatelessWidget {
  const _OneSolutionPage({required this.onNext, required this.onSkip});
  final VoidCallback onNext, onSkip;

  @override
  Widget build(BuildContext context) {
    final s = designScale(context);
    final l10n = context.l10n;
    const chipShadow = Color(0x26003C00);
    const chipPad = EdgeInsets.symmetric(horizontal: 12, vertical: 7);
    FloatChip chip(
      String l,
      double deg, {
      Color bg = Colors.white,
      Color fg = MssColors.ashokaBlue,
    }) => FloatChip(
      label: l,
      s: s,
      degrees: deg,
      bg: bg,
      fg: fg,
      fontSize: 12,
      weight: FontWeight.w600,
      padding: chipPad,
      radius: 12,
      shadow: chipShadow,
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const MssBackground(
          asset: MssAssets.bgGreen,
          fallback: Color(0xFFE3F3D8),
        ),
        Positioned(
          top: 58 * s,
          left: 28 * s,
          child: StepCounter(step: 2, s: s),
        ),
        Positioned(
          top: 54 * s,
          right: 22 * s,
          child: SkipButton(onTap: onSkip, s: s),
        ),
        Positioned(
          top: 96 * s,
          left: 18 * s,
          right: 18 * s,
          height: 284 * s,
          child: GlassPanel(s: s),
        ),
        Positioned(
          top: 118 * s,
          left: 40 * s,
          right: 40 * s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HighlightText(
                l10n.onbP2Title,
                highlight: pop(29, FontWeight.w800, MssColors.green, s),
                style: pop(
                  29,
                  FontWeight.w800,
                  MssColors.ashokaBlue,
                  s,
                  height: 1.14,
                ),
              ),
              SizedBox(height: 12 * s),
              Text(
                l10n.onbP2Body,
                style: pop(
                  13,
                  FontWeight.w500,
                  MssColors.ashokaBlue,
                  s,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 12 * s),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * s,
                  vertical: 6 * s,
                ),
                decoration: BoxDecoration(
                  color: MssColors.green,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.onbP2Badge,
                  style: pop(12.5, FontWeight.w700, Colors.white, s),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: -14 * s,
          bottom: -4 * s,
          width: 168 * s,
          child: const Character(asset: MssAssets.charFarmer),
        ),
        Positioned(
          right: -30 * s,
          bottom: -4 * s,
          width: 172 * s,
          child: const Character(asset: MssAssets.charWomanPink),
        ),
        Positioned(
          left: 58 * s,
          top: 384 * s,
          child: chip(l10n.onbChipEligibility, -6),
        ),
        Positioned(
          left: 226 * s,
          top: 380 * s,
          child: chip(l10n.onbChipIncome, 5, bg: MssColors.saffron),
        ),
        Positioned(
          left: 30 * s,
          top: 452 * s,
          child: chip(l10n.onbChipDocuments, 4),
        ),
        Positioned(
          left: 254 * s,
          top: 446 * s,
          child: chip(l10n.onbChipLoans, -4, fg: MssColors.green),
        ),
        Positioned(
          left: 146 * s,
          top: 502 * s,
          child: chip(
            l10n.onbChipSubsidies,
            3,
            bg: MssColors.ashokaBlue,
            fg: Colors.white,
          ),
        ),
        // Converged MSS card
        Positioned(
          left: 124 * s,
          top: 414 * s,
          width: 112 * s,
          height: 72 * s,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18 * s),
              border: Border.all(color: MssColors.green, width: 4 * s),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x40003C00),
                  blurRadius: 30 * s,
                  offset: Offset(0, 14 * s),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  MssAssets.logo,
                  width: 34 * s,
                  height: 34 * s,
                  cacheWidth: 120,
                ),
                SizedBox(width: 6 * s),
                Text(
                  'MSS',
                  style: pop(18, FontWeight.w800, MssColors.ashokaBlue, s),
                ), // i18n-ok: brand name
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 70 * s,
          child: Center(
            child: PillButton(
              label: l10n.onbNext,
              onTap: onNext,
              s: s,
              bg: MssColors.green,
              halo: Colors.white.withValues(alpha: .7),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32 * s,
          child: Center(child: PageDots(active: 1, s: s)),
        ),
      ],
    );
  }
}

// ─────────────────── 03 · Know Your Eligibility (White) ───────────────────
class _EligibilityPage extends StatelessWidget {
  const _EligibilityPage({required this.onNext, required this.onSkip});
  final VoidCallback onNext, onSkip;

  @override
  Widget build(BuildContext context) {
    final s = designScale(context);
    final l10n = context.l10n;
    Widget check(String label) => Padding(
      padding: EdgeInsets.only(bottom: 6 * s),
      child: Row(
        children: [
          Container(
            width: 18 * s,
            height: 18 * s,
            decoration: const BoxDecoration(
              color: MssColors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 12 * s, color: Colors.white),
          ),
          SizedBox(width: 8 * s),
          Flexible(
            child: Text(
              label,
              style: pop(12, FontWeight.w600, MssColors.ashokaBlue, s),
            ),
          ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const MssBackground(
          asset: MssAssets.bgWhite,
          fallback: Color(0xFFFDF8F0),
        ),
        Positioned(
          top: 58 * s,
          left: 28 * s,
          child: StepCounter(step: 3, s: s),
        ),
        Positioned(
          top: 54 * s,
          right: 22 * s,
          child: SkipButton(onTap: onSkip, s: s, bg: const Color(0x14000080)),
        ),
        Positioned(
          top: 96 * s,
          left: 18 * s,
          right: 18 * s,
          height: 236 * s,
          child: GlassPanel(
            s: s,
            opacity: .7,
            borderColor: const Color(0x0F000080),
          ),
        ),
        Positioned(
          top: 118 * s,
          left: 40 * s,
          right: 40 * s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HighlightText(
                l10n.onbP3Title,
                highlight: pop(32, FontWeight.w800, MssColors.saffronDeep, s),
                style: pop(
                  32,
                  FontWeight.w800,
                  MssColors.ashokaBlue,
                  s,
                  height: 1.12,
                ),
              ),
              SizedBox(height: 12 * s),
              Text(
                l10n.onbP3Body,
                style: pop(
                  13,
                  FontWeight.w500,
                  MssColors.ashokaBlue,
                  s,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: -46 * s,
          top: 494 * s,
          width: 222 * s,
          child: const Character(asset: MssAssets.charGirlStudent),
        ),
        // Eligibility card
        Positioned(
          right: 16 * s,
          top: 340 * s,
          width: 170 * s,
          child: Container(
            padding: EdgeInsets.all(14 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22 * s),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x2E000050),
                  blurRadius: 40 * s,
                  offset: Offset(0, 18 * s),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onbP3Matches,
                  style: pop(14, FontWeight.w700, MssColors.ashokaBlue, s),
                ),
                SizedBox(height: 8 * s),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 9 * s,
                    vertical: 7 * s,
                  ),
                  decoration: BoxDecoration(
                    color: MssColors.green.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10 * s),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 14 * s,
                        color: MssColors.green,
                      ),
                      SizedBox(width: 4 * s),
                      Expanded(
                        child: Text(
                          l10n.onbP3Found(12),
                          style: pop(11.5, FontWeight.w700, MssColors.green, s),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8 * s),
                  child: Container(
                    height: 1,
                    color: MssColors.ashokaBlue.withValues(alpha: .08),
                  ),
                ),
                Text(
                  'PMEGP',
                  style: pop(16, FontWeight.w800, MssColors.ashokaBlue, s),
                ), // i18n-ok: scheme acronym
                SizedBox(height: 2 * s),
                Text(
                  l10n.onbP3MayBeEligible,
                  style: pop(11.5, FontWeight.w600, MssColors.eligibleAmber, s),
                ),
                SizedBox(height: 8 * s),
                check(l10n.onbP3Age),
                check(l10n.onbChipIncome),
                check(l10n.onbP3Occupation),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16 * s,
          top: 574 * s,
          width: 170 * s,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(12 * s),
            ),
            child: Text(
              l10n.onbP3Footer,
              textAlign: TextAlign.right,
              style: pop(
                13,
                FontWeight.w700,
                MssColors.saffronText,
                s,
                height: 1.4,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 70 * s,
          child: EdgeTabButton(
            s: s,
            fromRight: true,
            tabColor: MssColors.ashokaBlue,
            button: PillButton(
              label: l10n.onbNext,
              onTap: onNext,
              s: s,
              bg: MssColors.saffron,
              fg: MssColors.ashokaBlue,
              weight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          right: 26 * s,
          bottom: 32 * s,
          child: PageDots(active: 2, s: s, inactiveOpacity: .25),
        ),
      ],
    );
  }
}

// ───────────────────── 04 · Meet Saarthi (Tricolor) ─────────────────────
class _SaarthiPage extends StatelessWidget {
  const _SaarthiPage({required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final s = designScale(context);
    final l10n = context.l10n;
    Widget lang(String t, TextStyle style, Color bg, {bool outline = false}) =>
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: outline
                ? Border.all(color: MssColors.ashokaBlue.withValues(alpha: .15))
                : null,
          ),
          child: Text(t, style: style),
        );
    Widget bar(double h, Color c) => Container(
      margin: EdgeInsets.symmetric(horizontal: 2 * s),
      width: 4 * s,
      height: h * s,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2 * s),
      ),
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const MssBackground(
          asset: MssAssets.bgTricolor,
          fallback: MssColors.cream,
        ),
        Positioned(
          top: 56 * s,
          left: 18 * s,
          right: 18 * s,
          height: 216 * s,
          child: GlassPanel(s: s, opacity: .75),
        ),
        Positioned(
          top: 74 * s,
          left: 36 * s,
          right: 36 * s,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: HighlightText(
                      l10n.onbP4Title,
                      highlight: pop(
                        34,
                        FontWeight.w800,
                        MssColors.saffronDeep,
                        s,
                      ),
                      style: pop(
                        34,
                        FontWeight.w800,
                        MssColors.ashokaBlue,
                        s,
                        height: 1.1,
                      ),
                    ),
                  ),
                  StepCounter(step: 4, s: s),
                ],
              ),
              SizedBox(height: 10 * s),
              Text(
                l10n.onbP4Body,
                style: pop(
                  13,
                  FontWeight.w500,
                  MssColors.ashokaBlue,
                  s,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 14 * s),
              Wrap(
                spacing: 6 * s,
                runSpacing: 6 * s,
                children: [
                  lang(
                    'தமிழ்', // i18n-ok: language name in its own script
                    tamil(12, FontWeight.w600, Colors.white, s),
                    MssColors.ashokaBlue,
                  ),
                  lang(
                    'हिन्दी', // i18n-ok
                    deva(12, FontWeight.w600, MssColors.ashokaBlue, s),
                    MssColors.saffronLight,
                  ),
                  lang(
                    'English', // i18n-ok
                    pop(12, FontWeight.w600, MssColors.ashokaBlue, s),
                    Colors.white,
                    outline: true,
                  ),
                  lang(
                    'मराठी', // i18n-ok
                    deva(12, FontWeight.w600, MssColors.greenDeep, s),
                    MssColors.greenLight,
                  ),
                ],
              ),
            ],
          ),
        ),
        // User speech bubble
        Positioned(
          left: 22 * s,
          top: 290 * s,
          child: Container(
            constraints: BoxConstraints(maxWidth: 240 * s),
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 10 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18 * s),
                topRight: Radius.circular(18 * s),
                bottomRight: Radius.circular(18 * s),
                bottomLeft: Radius.circular(4 * s),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1F000050),
                  blurRadius: 22 * s,
                  offset: Offset(0, 8 * s),
                ),
              ],
            ),
            child: Text(
              '“எனக்கு என்ன திட்டங்கள் கிடைக்கும்?”', // i18n-ok: sample Tamil question
              style: tamil(
                13,
                FontWeight.w600,
                MssColors.ashokaBlue,
                s,
                height: 1.5,
              ),
            ),
          ),
        ),
        // Saarthi reply
        Positioned(
          right: 22 * s,
          top: 356 * s,
          child: Container(
            constraints: BoxConstraints(maxWidth: 240 * s),
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 10 * s),
            decoration: BoxDecoration(
              color: MssColors.ashokaBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18 * s),
                topRight: Radius.circular(18 * s),
                bottomLeft: Radius.circular(18 * s),
                bottomRight: Radius.circular(4 * s),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x33000050),
                  blurRadius: 22 * s,
                  offset: Offset(0, 8 * s),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onbP4SaarthiLabel,
                  style: pop(12, FontWeight.w700, const Color(0xFFFFB766), s),
                ),
                SizedBox(height: 2 * s),
                Text(
                  '“உங்களுக்கு 8 திட்டங்கள் பொருந்தலாம்.”', // i18n-ok: sample Tamil reply
                  style: tamil(
                    13,
                    FontWeight.w600,
                    Colors.white,
                    s,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -30 * s,
          bottom: -4 * s,
          width: 236 * s,
          child: const Character(asset: MssAssets.charSaarthiGuide),
        ),
        // Mic + voice wave
        Positioned(
          left: 34 * s,
          top: 458 * s,
          child: Row(
            children: [
              Container(
                width: 72 * s,
                height: 72 * s,
                decoration: BoxDecoration(
                  color: MssColors.ashokaBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .6),
                      spreadRadius: 20 * s,
                    ),
                    BoxShadow(
                      color: const Color(0xFFD6D6EC),
                      spreadRadius: 10 * s,
                    ),
                  ],
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 34 * s,
                  ),
                ),
              ),
              SizedBox(width: 24 * s),
              bar(14, MssColors.ashokaBlue),
              bar(28, MssColors.saffron),
              bar(40, MssColors.ashokaBlue),
              bar(22, MssColors.green),
              bar(34, MssColors.ashokaBlue),
            ],
          ),
        ),
        Positioned(
          left: 22 * s,
          top: 578 * s,
          width: 160 * s,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 8 * s),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .88),
              borderRadius: BorderRadius.circular(12 * s),
            ),
            child: Text(
              l10n.onbP4Footer,
              style: pop(
                13,
                FontWeight.w700,
                MssColors.ashokaBlue,
                s,
                height: 1.4,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 70 * s,
          child: EdgeTabButton(
            s: s,
            shadow: true,
            tabColor: Colors.white.withValues(alpha: .92),
            button: PillButton(
              label: l10n.onbGetStarted,
              onTap: onGetStarted,
              s: s,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        Positioned(
          left: 26 * s,
          bottom: 32 * s,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: PageDots(active: 3, s: s, inactiveOpacity: .25),
          ),
        ),
      ],
    );
  }
}
