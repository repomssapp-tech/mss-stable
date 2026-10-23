// Sign-in progress (the loading overlay's state machine) and the translated
// notification inbox view, both with fake backends: no platform channels.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/controllers/notification_translation_controller.dart';
import 'package:frontend/services/account/sign_in_progress.dart';
import 'package:frontend/services/notifications/notification_translator.dart';
import 'package:frontend/widgets/common/auto_translated_text.dart';

class _FakeBackend implements TextTranslationBackend {
  _FakeBackend(this.fn);
  final String? Function(String text, String target) fn;
  int calls = 0;

  @override
  Future<String?> translate(String text, {required String target}) async {
    calls++;
    return fn(text, target);
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('SignInProgress', () {
    setUp(SignInProgress.instance.resetForTest);
    tearDown(SignInProgress.instance.resetForTest);

    test('goes idle -> in browser -> completing -> idle', () {
      final p = SignInProgress.instance;
      expect(p.phase.value, SignInPhase.idle);
      p.browserOpened();
      expect(p.phase.value, SignInPhase.inBrowser);
      p.completing();
      expect(p.phase.value, SignInPhase.completing);
      p.finish();
      expect(p.phase.value, SignInPhase.idle);
    });

    test('coming back from the browser starts waiting for the callback', () {
      final p = SignInProgress.instance;
      p.browserOpened();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(p.phase.value, SignInPhase.inBrowser);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(p.phase.value, SignInPhase.completing);
    });

    test('resuming without a sign-in in flight changes nothing', () {
      final p = SignInProgress.instance;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(p.phase.value, SignInPhase.idle);
    });
  });

  group('NotificationTranslationController', () {
    final items = [
      {'id': '1', 'title': 'New scheme', 'body': 'Apply before Friday'},
      {'id': '2', 'title': '', 'body': ''},
    ];

    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test(
      'shows the original until the translation arrives, then swaps',
      () async {
        final backend = _FakeBackend((t, target) => '[$target] $t');
        final c = NotificationTranslationController(
          translator: NotificationTranslator(backend: backend),
        );
        var notified = 0;
        c.addListener(() => notified++);

        final first = c.view(items, 'ta');
        expect(first[0]['title'], 'New scheme');
        await settle();
        expect(notified, greaterThan(0));

        final second = c.view(items, 'ta');
        expect(second[0]['title'], '[ta] New scheme');
        expect(second[0]['body'], '[ta] Apply before Friday');
        expect(second[0]['title_original'], 'New scheme');
        // Empty text is left alone and never sent to the translator.
        expect(second[1]['title'], '');
      },
    );

    test('keeps the original when the text cannot be translated', () async {
      final backend = _FakeBackend((t, target) => null);
      final c = NotificationTranslationController(
        translator: NotificationTranslator(backend: backend),
      );
      c.view(items, 'hi');
      await settle();
      expect(c.view(items, 'hi')[0]['title'], 'New scheme');
      // A failed text is not re-sent on every rebuild.
      final calls = backend.calls;
      c.view(items, 'hi');
      await settle();
      expect(backend.calls, calls);
    });

    test('a translator error never breaks the inbox', () async {
      final c = NotificationTranslationController(
        translator: NotificationTranslator(
          backend: _FakeBackend((t, target) => throw StateError('boom')),
        ),
      );
      expect(c.view(items, 'ta')[0]['title'], 'New scheme');
      await settle();
      expect(c.view(items, 'ta')[0]['title'], 'New scheme');
    });
  });

  group('AutoTranslatedText.isEnglishOnly', () {
    test('English names need translating, localised ones do not', () {
      expect(AutoTranslatedText.isEnglishOnly('EDII Technology Fund'), isTrue);
      expect(AutoTranslatedText.isEnglishOnly('மத்திய திட்டம்'), isFalse);
      expect(AutoTranslatedText.isEnglishOnly('प्रधानमंत्री योजना'), isFalse);
      expect(AutoTranslatedText.isEnglishOnly('PMEGP 2.0 திட்டம்'), isFalse);
      expect(AutoTranslatedText.isEnglishOnly('1234 – 5'), isFalse);
      expect(AutoTranslatedText.isEnglishOnly(''), isFalse);
    });
  });

  test('"Mss" in a broadcast is shown as "MSS", translated or not', () async {
    final c = NotificationTranslationController(
      translator: NotificationTranslator(backend: _FakeBackend((t, l) => null)),
    );
    final out = c.view([
      {'id': '1', 'title': 'Mss app update', 'body': 'Update the Mss app now'},
    ], 'en');
    expect(out[0]['title'], 'MSS app update');
    expect(out[0]['body'], 'Update the MSS app now');
  });
}
