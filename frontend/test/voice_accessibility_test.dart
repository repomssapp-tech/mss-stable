import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/voice/voice_accessibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.inschemes.app/voice_accessibility');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  test(
    'a generic accessibility flag does not silence Android reply audio',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'screenReaderEnabled');
        return false;
      });
      expect(
        await VoiceAccessibility.screenReaderEnabled(platformHint: true),
        isFalse,
      );
    },
  );
  test(
    'a spoken accessibility service hands reading over to the reader',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async => true);
      expect(
        await VoiceAccessibility.screenReaderEnabled(platformHint: false),
        isTrue,
      );
    },
  );
  test(
    'platforms without native detection retain the accessibility hint',
    () async {
      expect(
        await VoiceAccessibility.screenReaderEnabled(platformHint: true),
        isTrue,
      );
    },
  );
}
