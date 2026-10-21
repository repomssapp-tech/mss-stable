import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

/// DTO representing a registered push device from `GET /v1/me/push-devices`.
class PushDeviceDto {
  final String id;
  final String platform;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PushDeviceDto({
    required this.id,
    required this.platform,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PushDeviceDto.fromJson(Map<String, dynamic> json) {
    return PushDeviceDto(
      id: json['id']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'android',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }
}

/// Service managing mobile push device registration under `/v1/me/push-devices`.
class PushDeviceService {
  PushDeviceService({ApiClient? client, SharedPreferences? prefs})
      : _client = client ?? ApiClient.instance,
        _prefs = prefs;

  final ApiClient _client;
  SharedPreferences? _prefs;

  static const String _kDeviceIdKey = 'mss_push_device_uuid';

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns a stable locally persisted UUIDv4 installation identifier.
  Future<String> getOrCreateDeviceId() async {
    final prefs = await _getPrefs();
    String? deviceId = prefs.getString(_kDeviceIdKey);
    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    deviceId = _generateUuidV4();
    await prefs.setString(_kDeviceIdKey, deviceId);
    return deviceId;
  }

  /// Lists active push registrations for the current owner.
  Future<List<PushDeviceDto>> getRegisteredDevices() async {
    final response = await _client.get(
      '/v1/me/push-devices',
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      final items = (response.data['items'] as List<dynamic>?) ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((json) => PushDeviceDto.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Registers or rotates the FCM token for this installation UUID.
  /// [platform] must be 'android' or 'ios'.
  Future<PushDeviceDto> registerDevice({
    required String token,
    required String platform,
  }) async {
    assert(platform == 'android' || platform == 'ios', 'Platform must be android or ios');
    final deviceId = await getOrCreateDeviceId();

    final response = await _client.put(
      '/v1/me/push-devices/$deviceId',
      body: {
        'token': token.trim(),
        'platform': platform.toLowerCase(),
      },
      requiresAuth: true,
    );

    if (response.data is Map<String, dynamic>) {
      return PushDeviceDto.fromJson(response.data as Map<String, dynamic>);
    }

    return PushDeviceDto(
      id: deviceId,
      platform: platform,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// Unregisters the push device from the backend.
  Future<void> unregisterDevice({String? deviceId}) async {
    final id = deviceId ?? await getOrCreateDeviceId();
    try {
      await _client.delete(
        '/v1/me/push-devices/$id',
        requiresAuth: true,
      );
    } catch (e) {
      debugPrint('[PushDeviceService] Error unregistering device: $e');
    }
  }

  /// Generates a RFC 4122 compliant UUIDv4 using secure random bytes.
  static String _generateUuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant RFC 4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
