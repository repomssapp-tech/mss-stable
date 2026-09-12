import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;
import 'package:http/http.dart' as http;

/// Avatar loads use a client that fails fast instead of hanging
/// indefinitely -- flutter_cache_manager's default HttpFileService has no
/// built-in request timeout.
///
/// Extracted from `profile_screen.dart` (frontend refactor C5, safe slice).
class TimeoutHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(const Duration(seconds: 10));
  }
}

final fcm.CacheManager avatarCacheManager = fcm.CacheManager(
  fcm.Config(
    'profileAvatarCache',
    fileService: fcm.HttpFileService(httpClient: TimeoutHttpClient()),
  ),
);
