import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/notification_params.dart';
import 'package:ride_app/features/notification/domain/repositories/notification_repository.dart';

import '../entities/notification_entity.dart';

class GetNotificationUseCase {
  final NotificationRepository repository;

  GetNotificationUseCase(this.repository);

  Future<Either<Failure, List<NotificationEntity>>> call({
    required NotificationParams params,
  }) {
    return repository.getNotifications(params: params);
  }
}

