import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/features/settings/presentation/states/change_language_state.dart';

void main() {
  test('idle state uses idle status', () {
    const state = ChangeLanguageState.idle();

    expect(state.status, ChangeLanguageStatus.idle);
    expect(state.errorMessage, isNull);
  });

  test('error state exposes error message', () {
    const state = ChangeLanguageState.error('failed');

    expect(state.status, ChangeLanguageStatus.error);
    expect(state.errorMessage, 'failed');
  });

  test('command result reports success and failure', () {
    final success = ChangeLanguageCommandResult.success('ok');
    final failure = ChangeLanguageCommandResult.failure('bad');

    expect(success.isSuccess, isTrue);
    expect(success.message, 'ok');
    expect(failure.isSuccess, isFalse);
    expect(failure.error, 'bad');
  });
}
