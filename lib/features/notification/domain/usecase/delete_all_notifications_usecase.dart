import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

class DeleteAllNotificationsUsecase {
  final NotificationRepository repository;

  DeleteAllNotificationsUsecase(this.repository);

  Future<Either<Failure, ApiResponse>> call() {
    return repository.deleteAllNotifications();
  }
}
