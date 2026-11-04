// Saarthi Voice settings (v2 design C6), reached from Settings and from the
// conversation room: Saarthi's language and the three voice switches.
// Saarthi's voice itself is chosen per language by the server, so the
// design's male/female and speed controls are not offered.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/app_state_provider.dart';
import '../../services/voice/saarthi_voice_settings.dart';
import '../../services/voice/voice_language.dart';
import '../../services/voice/voice_preferences.dart';
import '../../utils/app_colors.dart';
import '../mss_design.dart';
import 'saarthi_kit.dart';
import 'saarthi_voice_views.dart';

class SaarthiVoiceSettingsScreen extends StatefulWidget {
  const SaarthiVoiceSettingsScreen({
    super.key,
    this.settings,
    this.preferences,
  });

  final SaarthiVoiceSettings? settings;
  final VoicePreferences? preferences;

  @override
  State<SaarthiVoiceSettingsScreen> createState() =>
      _SaarthiVoiceSettingsScreenState();
}

class _SaarthiVoiceSettingsScreenState
    extends State<SaarthiVoiceSettingsScreen> {
  late final SaarthiVoiceSettings _settings =
      widget.settings ?? SaarthiVoiceSettings.instance;
  late final VoicePreferences _prefs = widget.preferences ?? VoicePreferences();
  String? _language;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_changed);
    _settings.load();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = context.read<AppProvider>().selectedLanguage;
      final lang = await _prefs.languageFor(app);
      if (mounted) setState(() => _language = lang);
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _settings.removeListener(_changed);
    super.dispose();
  }

  Future<void> _pick(String code) async {
    setState(() => _language = code);
    final app = context.read<AppProvider>().selectedLanguage;
    await _prefs.saveLanguage(code, app);
    _settings.changeLanguage(code);
  }

  Widget _card(
    List<Widget> children, {
    EdgeInsets pad = const EdgeInsets.all(14),
  }) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0x0F0F172A)),
    ),
    child: Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );

  TextStyle _langStyle(String code, Color c) => switch (code) {
    'ta' => tamil(14, FontWeight.w600, c, 1),
    'en' => pop(14, FontWeight.w600, c, 1),
    _ => deva(14, FontWeight.w600, c, 1),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final toggles = <(String, String, bool, ValueChanged<bool>)>[
      (
        l10n.sv2Autoplay,
        l10n.sv2AutoplayBody,
        _settings.autoplay,
        (v) => _settings.update(autoplay: v),
      ),
    ];
    const order = ['ta', 'hi', 'en', 'mr'];
    assert(order.every(VoiceLanguage.supported.contains));

    return DesignTextScale(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              BackTitle(title: l10n.sv2VoiceSettings),
              const SizedBox(height: 22),
              _card([
                Text(
                  l10n.sv2VoiceLanguage,
                  style: pop(13, FontWeight.w700, kInk, 1),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3.1,
                  children: [
                    for (final code in order)
                      Semantics(
                        button: true,
                        selected: _language == code,
                        label: voiceLanguageName(code),
                        excludeSemantics: true,
                        child: Material(
                          color: _language == code ? kInk : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0x1F0F172A)),
                          ),
                          child: InkWell(
                            key: Key('sv2-voice-lang-$code'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _pick(code),
                            child: Center(
                              child: Text(
                                voiceLanguageName(code),
                                style: _langStyle(
                                  code,
                                  _language == code ? Colors.white : kInk,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.sv2VoiceNote,
                  style: pop(11.5, FontWeight.w500, kMuted, 1),
                ),
              ]),
              const SizedBox(height: 14),
              _card(
                pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                [
                  for (var i = 0; i < toggles.length; i++)
                    Container(
                      decoration: BoxDecoration(
                        border: i < toggles.length - 1
                            ? const Border(
                                bottom: BorderSide(color: Color(0x120F172A)),
                              )
                            : null,
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: toggles[i].$3,
                        onChanged: toggles[i].$4,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                        title: Text(
                          toggles[i].$1,
                          style: pop(13.5, FontWeight.w600, kInk, 1),
                        ),
                        subtitle: Text(
                          toggles[i].$2,
                          style: pop(11.5, FontWeight.w500, kMuted, 1),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
