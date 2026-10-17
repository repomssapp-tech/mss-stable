import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Helper for generating cryptographically secure RFC 7636 PKCE parameters.
class PkceHelper {
  PkceHelper._();

  static const String _charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  /// Generates a random code_verifier between 43 and 128 characters (default 64).
  static String generateCodeVerifier([int length = 64]) {
    final clampedLength = length.clamp(43, 128);
    final random = Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < clampedLength; i++) {
      buffer.write(_charset[random.nextInt(_charset.length)]);
    }
    return buffer.toString();
  }

  /// Derives code_challenge as unpadded base64url(SHA256(verifier)).
  static String generateCodeChallenge(String verifier) {
    final bytes = ascii.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
