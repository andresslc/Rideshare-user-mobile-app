import 'package:ride_app/features/notification/data/datasources/notification_datascource.dart';
import 'package:ride_app/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:ride_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:ride_app/features/notification/domain/usecase/delete_all_notifications_usecase.dart';
import 'package:ride_app/features/notification/domain/usecase/delete_notification_usecase.dart';
import 'package:ride_app/features/notification/domain/usecase/get_notification_use_case.dart';
import 'package:ride_app/features/notification/domain/usecase/toggle_notification_usecase.dart';

import '../service_locator.dart';

/// Registers notification feature dependencies.
void registerNotificationModule() {
  // Data source
  locator.registerLazySingleton<NotificationDatasource>(
    () => NotificationDatasourceImpl(),
  );

  // Repository
  locator.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(locator<NotificationDatasource>()),
  );

  // Use cases
  locator.registerLazySingleton(
    () => ToggleNotificationUsecase(locator<NotificationRepository>()),
  );
  locator.registerLazySingleton(
    () => DeleteNotificationUsecase(locator<NotificationRepository>()),
  );
  locator.registerLazySingleton(
    () => DeleteAllNotificationsUsecase(locator<NotificationRepository>()),
  );
  locator.registerLazySingleton(
    () => GetNotificationUseCase(locator<NotificationRepository>()),
  );
}
