import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file. Tokens live in the Android Keystore through
/// flutter_secure_storage (issue #131); tests have no platform channel, so each
/// test gets a fresh in-memory store instead.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  await testMain();
}
