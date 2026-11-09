import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/notification_params.dart';
import 'package:ride_app/features/notification/data/datasources/notification_datascource.dart';
import 'package:ride_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

import '../../domain/entities/notification_entity.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDatasource datasource;

  NotificationRepositoryImpl(this.datasource);

  @override
  Future<Either<Failure, ApiResponse>> toggleNotification({
    required bool isEnabled,
    required String? fcm,
  }) {
    return datasource.toggleNotification(isEnabled: isEnabled, fcm: fcm);
  }

  @override
  Future<Either<Failure, ApiResponse>> deleteNotification(
    String notificationId,
  ) {
    return datasource.deleteNotification(notificationId);
  }

  @override
  Future<Either<Failure, ApiResponse>> deleteAllNotifications() {
    return datasource.deleteAllNotifications();
  }

  @override
  Future<Either<Failure,  List<NotificationEntity>>> getNotifications({
    required NotificationParams params,
  }) async {
    final res = await datasource.getNotifications(params: params);
    return res.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (data) => Right(data),
    );
  }
}

