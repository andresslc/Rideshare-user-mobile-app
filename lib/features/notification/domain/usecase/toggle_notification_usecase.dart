import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

class ToggleNotificationUsecase {
  final NotificationRepository repository;

  ToggleNotificationUsecase(this.repository);

  Future<Either<Failure, ApiResponse>> call({
    required bool isEnabled,
    required String? fcm,
  }) {
    return repository.toggleNotification(isEnabled: isEnabled, fcm: fcm);
  }
}

