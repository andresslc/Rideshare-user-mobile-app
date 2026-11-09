import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/notification_params.dart';
import 'package:ride_app/features/notification/data/datasources/notification_datascource.dart';
import 'package:ride_app/features/notification/data/models/notification_model.dart';
import 'package:ride_app/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

class _MockNotificationDatasource extends Mock
    implements NotificationDatasource {}

void main() {
  late NotificationDatasource datasource;
  late NotificationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(NotificationParams());
  });

  final model = NotificationModel(
    id: 'notif-1',
    notificationContent: NotificationContentModel(
      id: 'content-1',
      title: 'Ride accepted',
    ),
    user: 'user-1',
    userType: 'user',
    isRead: false,
    createdAt: DateTime.utc(2026, 6, 23),
  );

  setUp(() {
    datasource = _MockNotificationDatasource();
    repository = NotificationRepositoryImpl(datasource);
  });

  test('maps notification models to entities', () async {
    when(
      () => datasource.getNotifications(
        params: any(named: 'params'),
      ),
    ).thenAnswer((_) async => Right([model]));

    final result = await repository.getNotifications(
      params: NotificationParams(),
    );

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected success'), (notifications) {
      expect(notifications.single.id, 'notif-1');
      expect(notifications.single.notificationContent.title, 'Ride accepted');
    });
  });

  test('forwards delete success', () async {
    final response = ApiResponse(success: true, message: 'deleted');
    when(() => datasource.deleteNotification('notif-1')).thenAnswer(
      (_) async => Right(response),
    );

    final result = await repository.deleteNotification('notif-1');

    expect(result.isRight(), isTrue);
  });

  test('returns failure when datasource fails', () async {
    when(
      () => datasource.getNotifications(
        params: any(named: 'params'),
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'network error')),
    );

    final result = await repository.getNotifications(
      params: NotificationParams(),
    );

    expect(result.isLeft(), isTrue);
  });
}
