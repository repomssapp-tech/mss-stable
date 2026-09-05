import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/companion_mode/saarthi_home_screen.dart';

SaarthiMessage message(String role, {String? status}) => SaarthiMessage(
  id: role,
  role: role,
  text: role,
  timestamp: DateTime(2026),
  status: status,
);

void main() {
  test('a user turn starts a new assistant transcript bubble', () {
    final messages = [message('assistant'), message('user')];
    expect(cloudAssistantMessageTargetIndex(messages), -1);
  });

  test('streaming chunks update only the current assistant bubble', () {
    final messages = [message('user'), message('assistant')];
    expect(cloudAssistantMessageTargetIndex(messages), 1);
  });

  test('scheme cards wait for the assistant turn after the current user', () {
    final waitingForReply = [message('assistant'), message('user')];
    final streamingReply = [message('user'), message('assistant')];

    expect(cloudSchemeResultTargetIndex(waitingForReply), -1);
    expect(cloudSchemeResultTargetIndex(streamingReply), 1);
  });

  test('only transient connection failures are retried automatically', () {
    expect(
      isTransientCloudConnectionFailure(StateError('socket timeout')),
      isTrue,
    );
    expect(
      isTransientCloudConnectionFailure(StateError('network unavailable')),
      isTrue,
    );
    expect(
      isTransientCloudConnectionFailure(StateError('401 invalid session')),
      isFalse,
    );
    expect(
      isTransientCloudConnectionFailure(StateError('not configured')),
      isFalse,
    );
  });

  test('transcribing state can be cleared when a turn completes', () {
    final transcribing = message('user', status: 'transcribing');
    expect(transcribing.copyWith(clearStatus: true).status, isNull);
  });

  test('stale output is not copied into the next assistant bubble', () {
    expect(
      shouldApplyCloudOutput(
        output: 'Previous answer',
        previousOutput: 'Previous answer',
      ),
      isFalse,
    );
    expect(
      shouldApplyCloudOutput(
        output: 'New answer',
        previousOutput: 'Previous answer',
      ),
      isTrue,
    );
  });
}
