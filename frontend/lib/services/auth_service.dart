import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final client = Supabase.instance.client;

  static const _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://houpzsxmwemoztpuigmo.supabase.co',
  );

  /// Used only before an online-only sign-in. Core catalog use never waits on
  /// this check.
  static Future<bool> canReachAuthenticationService({
    http.Client? httpClient,
  }) async {
    final ownsClient = httpClient == null;
    final activeClient = httpClient ?? http.Client();
    try {
      final response = await activeClient
          .get(Uri.parse('$_supabaseUrl/auth/v1/health'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode > 0;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } finally {
      if (ownsClient) activeClient.close();
    }
  }

  static const googleRedirectUrl = 'com.inschemes.app://login-callback/';

  static User? get currentUser => client.auth.currentUser;

  static Session? get currentSession => client.auth.currentSession;

  static Future<bool> signInWithGoogle() async {
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: googleRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
        scopes: 'openid email profile',
      );
    } catch (e) {
      debugPrint('[AuthService] Unable to start Google OAuth: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
