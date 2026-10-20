import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/account/app_session.dart';
import 'package:frontend/services/account/token_storage.dart';
import 'package:frontend/services/network/api_exception.dart';
import 'package:frontend/services/notifications/push_devices_api_service.dart';
import 'package:frontend/services/notifications/push_models.dart';
import 'package:frontend/services/notifications/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGateway implements PushMessagingGateway {
  bool granted = true;
  bool askedPermission = false;
  String? token = 'token-one-aaaaaaaa';
  PushMessage? initial;
  final refresh = StreamController<String>.broadcast(sync: true);
  final foreground = StreamController<PushMessage>.broadcast(sync: true);
  final opened = StreamController<PushMessage>.broadcast(sync: true);

  @override
  Future<bool> requestPermission() async {
    askedPermission = true;
    return granted;
  }

  @override
  Future<bool> hasPermission() async => granted && askedPermission;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => foreground.stream;

  @override
  Stream<PushMessage> get onOpenedFromBackground => opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => initial;
}

class _FakeApi extends PushDevicesApiService {
  final List<({String id, String token})> registered = [];
  final List<String> unregistered = [];
  ApiException? failWith;

  @override
  Future<void> register({
    required String installationId,
    required String token,
    String platform = 'android',
  }) async {
    if (failWith != null) throw failWith!;
    registered.add((id: installationId, token: token));
  }

  @override
  Future<void> unregister(String installationId) async {
    unregistered.add(installationId);
  }
}

const _idA = '11111111-1111-4111-8111-111111111111';
const _idB = '22222222-2222-4222-8222-222222222222';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage storage;
  late _FakeGateway gateway;
  late _FakeApi api;
  late PushNotificationService service;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  Future<void> signIn(String userId) async {
    await storage.saveTokens(accessToken: 'a-$userId', refreshToken: 'r');
    await storage.saveUser(id: userId, email: '$userId@example.com');
    await settle();
  }

  Future<void> signOut() async {
    await storage.clear();
    await settle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = TokenStorage(await SharedPreferences.getInstance());
    await AppSession.instance.resetForTest();
    await AppSession.instance.hydrate(storage: storage);
    gateway = _FakeGateway();
    api = _FakeApi();
    service = PushNotificationService(gateway: gateway, api: api);
  });

  tearDown(() async {
    await service.dispose();
    await AppSession.instance.resetForTest();
  });

  test(
    'registers the token with a stable installation id after sign-in',
    () async {
      await service.start();
      expect(api.registered, isEmpty, reason: 'nothing before sign-in');

      await signIn('user-a');

      expect(gateway.askedPermission, isTrue);
      expect(api.registered, hasLength(1));
      expect(api.registered.single.token, 'token-one-aaaaaaaa');
      expect(PushMessage.isUuid(api.registered.single.id), isTrue);

      await service.onAppResumed();
      expect(api.registered, hasLength(1), reason: 'already in sync');
    },
  );

  test('a refused permission does not register and never throws', () async {
    gateway.granted = false;
    await service.start();
    await signIn('user-a');

    expect(api.registered, isEmpty);
  });

  test('a rotated token is registered again', () async {
    await service.start();
    await signIn('user-a');

    gateway.refresh.add('token-two-bbbbbbbb');
    await settle();

    expect(api.registered.map((r) => r.token), [
      'token-one-aaaaaaaa',
      'token-two-bbbbbbbb',
    ]);
    expect(api.registered.first.id, api.registered.last.id);
  });

  test(
    'a server rejection is swallowed and retried on the next resume',
    () async {
      api.failWith = const ApiException(
        statusCode: 503,
        errorCode: 'PUSH_NOT_CONFIGURED',
        message: 'not configured',
      );
      await service.start();
      await signIn('user-a');
      expect(api.registered, isEmpty);

      api.failWith = null;
      await service.onAppResumed();
      expect(api.registered, hasLength(1));
    },
  );

  test(
    'sign-out then another account registers again for the new account',
    () async {
      await service.start();
      await signIn('user-a');
      await signOut();
      await signIn('user-b');

      expect(api.registered, hasLength(2), reason: 'one per account session');
    },
  );

  test('a message is passed on once, only while signed in', () async {
    final shown = <String>[];
    service.onForegroundMessage = (m, owner) =>
        shown.add('${m.notificationId}@$owner');
    await service.start();

    gateway.foreground.add(const PushMessage(notificationId: _idA));
    expect(shown, isEmpty, reason: 'signed out');

    await signIn('user-a');
    gateway.foreground.add(const PushMessage(notificationId: _idA));
    gateway.foreground.add(const PushMessage(notificationId: _idA));
    gateway.foreground.add(const PushMessage(notificationId: _idB));

    expect(shown, ['$_idA@user-a', '$_idB@user-a']);
  });

  test('a notification that launched the app is opened once', () async {
    gateway.initial = const PushMessage(notificationId: _idA);
    final opened = <String>[];
    service.onOpenedMessage = (m, owner) => opened.add(m.notificationId);
    await signIn('user-a');

    await service.start();
    gateway.opened.add(const PushMessage(notificationId: _idA));

    expect(opened, [_idA]);
  });

  test('only a UUID notification_id is accepted from a payload', () {
    expect(
      PushMessage.fromData({'notification_id': _idA})?.notificationId,
      _idA,
    );
    expect(PushMessage.fromData({'notification_id': '../me'}), isNull);
    expect(PushMessage.fromData({'other': 'x'}), isNull);
  });

  test('the installation id is created once and kept', () async {
    final store = PushInstallationStore();
    final first = await store.getOrCreate();
    expect(PushMessage.isUuid(first), isTrue);
    expect(await store.getOrCreate(), first);
  });
}
