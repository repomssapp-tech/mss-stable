// Saarthi home (redesign): Saarthi's picture, the greeting, the mic and a
// keyboard to start a chat, and the three-item nav bar the Saarthi screens
// share.
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../utils/constants.dart';
import '../highlight_text.dart';
import '../mss_design.dart';
import 'saarthi_kit.dart';
import '../../widgets/onboarding/saarthi_tour.dart';

enum SaarthiNavTab { home, sessions }

class SaarthiVoiceHome extends StatelessWidget {
  const SaarthiVoiceHome({
    super.key,
    required this.userName,
    required this.onStart,
    required this.onType,
    required this.onProfile,
    required this.nav,
  });

  final String userName;
  final VoidCallback onStart;
  final VoidCallback onType;
  final VoidCallback onProfile;
  final Widget nav;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final greeting = AppConstants.getTimeGreeting(l10n);
    return Scaffold(
      key: const Key('sv2-home'),
      backgroundColor: kSaarthiBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Image.asset(
                            MssAssets.logo,
                            width: 44,
                            height: 44,
                            cacheWidth: 132,
                          ),
                        ),
                        const Spacer(),
                        RoundIconButton(
                          key: const Key('saarthi-profile-btn'),
                          icon: Icons.person_outline_rounded,
                          tooltip: l10n.profileTitle,
                          bg: Colors.white,
                          border: true,
                          iconSize: 22,
                          onTap: onProfile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        color: MssColors.cream,
                        shape: BoxShape.circle,
                        // Saffron inner ring, green outer ring, as drawn.
                        boxShadow: const [
                          BoxShadow(color: Color(0x1F138808), spreadRadius: 16),
                          BoxShadow(color: Color(0x40FF9933), spreadRadius: 7),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            left: -37,
                            top: 13,
                            width: 334,
                            child: ExcludeSemantics(
                              child: Image.asset(
                                MssAssets.saarthiNamaste,
                                cacheWidth: 720,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: HighlightText(
                      '$greeting [$userName]',
                      textAlign: TextAlign.center,
                      highlight: pop(
                        28,
                        FontWeight.w800,
                        MssColors.saffronText,
                        1,
                      ),
                      style: pop(28, FontWeight.w800, kInk, 1, height: 1.2),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SaarthiTalkControls(
                    micKey: const Key('saarthi-start-speaking'),
                    typeKey: const Key('saarthi-start-typing'),
                    micTourKey: SaarthiTourTargets.mic,
                    typeTourKey: SaarthiTourTargets.type,
                    micSize: 84,
                    onSpeak: onStart,
                    onType: onType,
                  ),
                ],
              ),
            ),
            nav,
          ],
        ),
      ),
    );
  }
}

/// The big mic, centred, with the small keyboard beside it.
class SaarthiTalkControls extends StatelessWidget {
  const SaarthiTalkControls({
    super.key,
    required this.micKey,
    required this.typeKey,
    required this.onSpeak,
    required this.onType,
    this.micSize = 68,
    this.micTourKey,
    this.typeTourKey,
  });

  final Key micKey;
  final Key typeKey;

  /// Set only on the Saarthi home, where the first-time tour points at them.
  final GlobalKey? micTourKey;
  final GlobalKey? typeTourKey;

  static Widget _tour(GlobalKey? key, Widget child) =>
      key == null ? child : KeyedSubtree(key: key, child: child);
  final VoidCallback onSpeak;
  final VoidCallback onType;
  final double micSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 64),
        _tour(
          micTourKey,
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: kSaffronHalo, spreadRadius: 8)],
            ),
            child: RoundIconButton(
              key: micKey,
              icon: Icons.mic_none_rounded,
              tooltip: l10n.sv2StartTalking,
              bg: kBrand,
              fg: Colors.white,
              size: micSize,
              iconSize: micSize * .42,
              onTap: onSpeak,
            ),
          ),
        ),
        const SizedBox(width: 16),
        _tour(
          typeTourKey,
          RoundIconButton(
            key: typeKey,
            icon: Icons.keyboard_outlined,
            tooltip: l10n.sv2TypeMessage,
            bg: Colors.white,
            border: true,
            size: 48,
            iconSize: 22,
            onTap: onType,
          ),
        ),
      ],
    );
  }
}

/// Floating nav bar: Home, Old sessions, Settings. Icons only, as drawn; each
/// keeps its name for screen readers and on long press.
class SaarthiPillNav extends StatelessWidget {
  const SaarthiPillNav({
    super.key,
    required this.selected,
    required this.onHome,
    required this.onSessions,
    required this.onSettings,
    this.sessionsTourKey,
  });

  /// Set only while the Saarthi home shows, for the first-time tour.
  final GlobalKey? sessionsTourKey;

  final SaarthiNavTab selected;
  final VoidCallback onHome;
  final VoidCallback onSessions;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget item(
      Key key,
      IconData icon,
      String label,
      bool active,
      VoidCallback onTap,
    ) => Expanded(
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          selected: active,
          label: label,
          excludeSemantics: true,
          child: Material(
            key: key,
            color: active ? kBrand : Colors.transparent,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: SizedBox(
                height: 48,
                child: Icon(
                  icon,
                  size: 22,
                  color: active ? Colors.white : kInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 8, 40, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000050),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            item(
              const Key('sv2-nav-home'),
              Icons.home_rounded,
              l10n.navHome,
              selected == SaarthiNavTab.home,
              onHome,
            ),
            if (sessionsTourKey == null)
              item(
                const Key('sv2-nav-sessions'),
                Icons.search_rounded,
                l10n.sv2OldSessions,
                selected == SaarthiNavTab.sessions,
                onSessions,
              )
            else
              Expanded(
                child: KeyedSubtree(
                  key: sessionsTourKey,
                  child: Row(
                    children: [
                      item(
                        const Key('sv2-nav-sessions'),
                        Icons.search_rounded,
                        l10n.sv2OldSessions,
                        selected == SaarthiNavTab.sessions,
                        onSessions,
                      ),
                    ],
                  ),
                ),
              ),
            item(
              const Key('sv2-nav-settings'),
              Icons.settings_outlined,
              l10n.profileSettingsTitle,
              false,
              onSettings,
            ),
          ],
        ),
      ),
    );
  }
}
