import '../network/api_client.dart';

/// Client for the MSS push-device API (`/v1/me/push-devices/:id`).
///
/// The owner comes from the bearer token. [installationId] is a random id of
/// this app installation (see PushInstallationStore), never a user id, and the
/// FCM token is a different credential from the access token.
class PushDevicesApiService {
  PushDevicesApiService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static String _path(String installationId) =>
      '/v1/me/push-devices/$installationId';

  /// Registers or rotates this installation's FCM token for the signed-in
  /// account. Sends no notification by itself.
  Future<void> register({
    required String installationId,
    required String token,
    String platform = 'android',
  }) async {
    await _client.put(
      _path(installationId),
      body: {'token': token, 'platform': platform},
    );
  }

  /// Stops pushes to this installation. Unknown ids answer 204 as well.
  Future<void> unregister(String installationId) async {
    await _client.delete(_path(installationId));
  }
}
