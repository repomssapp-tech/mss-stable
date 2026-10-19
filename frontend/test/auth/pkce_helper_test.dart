import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/account/pkce_helper.dart';

void main() {
  group('PkceHelper', () {
    test('generates valid RFC 7636 code_verifier', () {
      final verifier = PkceHelper.generateCodeVerifier(64);
      expect(verifier.length, 64);

      // Verify allowed characters A-Z, a-z, 0-9, -, ., _, ~
      final allowedRegex = RegExp(r'^[A-Za-z0-9\-._~]+$');
      expect(allowedRegex.hasMatch(verifier), isTrue);
    });

    test('clamps verifier length between 43 and 128', () {
      final shortVerifier = PkceHelper.generateCodeVerifier(10);
      expect(shortVerifier.length, 43);

      final longVerifier = PkceHelper.generateCodeVerifier(200);
      expect(longVerifier.length, 128);
    });

    test('generates unpadded base64url SHA-256 challenge', () {
      const knownVerifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      final challenge = PkceHelper.generateCodeChallenge(knownVerifier);

      // Manual computation
      final expectedHash = sha256.convert(ascii.encode(knownVerifier));
      final expectedChallenge = base64Url
          .encode(expectedHash.bytes)
          .replaceAll('=', '');

      expect(challenge, expectedChallenge);
      expect(challenge.contains('='), isFalse);
      expect(challenge.length, 43);
    });
  });
}
