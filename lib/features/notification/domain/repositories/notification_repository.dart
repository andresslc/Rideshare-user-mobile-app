import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/notification_params.dart';
import 'package:ride_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

abstract class NotificationRepository {
  Future<Either<Failure, ApiResponse>> toggleNotification({
    required bool isEnabled,
    required String? fcm,
  });

  Future<Either<Failure, ApiResponse>> deleteNotification(
    String notificationId,
  );

  Future<Either<Failure, ApiResponse>> deleteAllNotifications();

  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    required NotificationParams params,
  });
}

