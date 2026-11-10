import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/voice/speech_output_controller.dart';
import 'package:frontend/services/voice/voice_language.dart';

void main() {
  test('every supported voice language maps to its Indian locale', () {
    expect(VoiceLanguage.speechLocale('en'), 'en-IN');
    expect(VoiceLanguage.speechLocale('ta'), 'ta-IN');
    expect(VoiceLanguage.speechLocale('hi'), 'hi-IN');
    // Marathi was removed in 2.5.0: it falls back to English.
    expect(VoiceLanguage.speechLocale('mr'), 'en-IN');
    expect(VoiceLanguage.speechLocale('HI_in'), 'hi-IN');
    expect(VoiceLanguage.speechLocale('fr'), 'en-IN');
    expect(VoiceLanguage.speechLocale(null), 'en-IN');
    expect(VoiceLanguage.chatCode('mr-IN'), 'en');
    expect(VoiceLanguage.supported, ['en', 'ta', 'hi']);
  });

  test('speech capabilities are checked per language', () {
    const caps = SpeechOutputCapabilities(
      available: true,
      english: true,
      tamil: false,
      hindi: true,
    );
    expect(caps.supports('hi-IN'), isTrue);
    // Marathi was removed; it is treated as English.
    expect(caps.supports('mr-IN'), isTrue);
    expect(caps.supports('ta-IN'), isFalse);
    expect(caps.supports('en-IN'), isTrue);
  });
}
