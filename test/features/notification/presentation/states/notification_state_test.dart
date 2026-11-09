import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/features/notification/presentation/states/notification_state.dart';

void main() {
  test('toggle command result reports success and failure', () {
    final success = NotificationToggleCommandResult.success(true);
    final failure = NotificationToggleCommandResult.failure(
      revertedValue: false,
      message: 'network error',
    );

    expect(success.isSuccess, isTrue);
    expect(success.isEnabled, isTrue);
    expect(failure.isSuccess, isFalse);
    expect(failure.error, 'network error');
    expect(failure.isEnabled, isFalse);
  });

  test('delete command result reports success and failure', () {
    final failure = NotificationDeleteCommandResult.failure('bad');

    expect(NotificationDeleteCommandResult.success.isSuccess, isTrue);
    expect(failure.isSuccess, isFalse);
    expect(failure.error, 'bad');
  });
}
