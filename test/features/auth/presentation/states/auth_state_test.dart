import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/features/auth/presentation/states/auth_state.dart';

void main() {
  test('AuthState.loading sets loading status', () {
    const state = AuthState.loading();
    expect(state.status, AuthStatus.loading);
  });

  test('AuthCommandResult.success marks success', () {
    final result = AuthCommandResult.success('ok');
    expect(result.isSuccess, isTrue);
    expect(result.data, 'ok');
  });

  test('AuthCommandResult.failure marks failure', () {
    final result = AuthCommandResult.failure<String>('failed');
    expect(result.isSuccess, isFalse);
    expect(result.error, 'failed');
  });
}
