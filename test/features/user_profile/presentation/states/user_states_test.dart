import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/features/user_profile/presentation/states/user_states.dart';

void main() {
  test('idle state keeps profile data', () {
    const state = UserProfileState.idle();
    expect(state.status, UserProfileStatus.idle);
    expect(state.profile, isNull);
  });

  test('loading state preserves existing profile', () {
    const state = UserProfileState.loading();
    expect(state.status, UserProfileStatus.loading);
  });

  test('ProfileCommandResult success and failure', () {
    final success = ProfileCommandResult.success('ok');
    final failure = ProfileCommandResult.failure<String>('bad');

    expect(success.isSuccess, isTrue);
    expect(success.data, 'ok');
    expect(failure.isSuccess, isFalse);
    expect(failure.error, 'bad');
  });
}
