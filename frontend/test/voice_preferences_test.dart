import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/voice/voice_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('initial voice selection follows the app language', () async {
    expect(await VoicePreferences().languageFor('ta-IN'), 'ta');
  });
  test('explicit voice language survives a new preferences instance', () async {
    await VoicePreferences().saveLanguage('hi-IN', 'en');
    expect(await VoicePreferences().languageFor('en'), 'hi');
  });
  test('a new app language supersedes the earlier voice override', () async {
    await VoicePreferences().saveLanguage('hi', 'en');
    expect(await VoicePreferences().languageFor('ta'), 'ta');
    await VoicePreferences().saveLanguage('hi', 'ta');
    expect(await VoicePreferences().languageFor('ta'), 'hi');
  });
}
