import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/notifications/notification_translator.dart';

/// Translates nothing: the on-device translator is a platform plugin that never
/// answers inside a widget test and would leave its timeout timer pending.
class _NoTranslation implements TextTranslationBackend {
  @override
  Future<String?> translate(String text, {required String target}) async =>
      null;
}

/// Runs before every test file. Tokens live in the Android Keystore through
/// flutter_secure_storage (issue #131); tests have no platform channel, so each
/// test gets a fresh in-memory store instead.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    NotificationTranslator.instance = NotificationTranslator(
      backend: _NoTranslation(),
    );
  });
  await testMain();
}
