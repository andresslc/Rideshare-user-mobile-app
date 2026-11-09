import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/params/notification_params.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/features/notification/data/models/notification_model.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

abstract class NotificationDatasource {
  Future<Either<Failure, ApiResponse>> toggleNotification({
    required bool isEnabled,
    required String? fcm,
  });

  Future<Either<Failure, ApiResponse>> deleteNotification(String notificationId);

  Future<Either<Failure, ApiResponse>> deleteAllNotifications();

  Future<Either<Failure, List<NotificationModel>>> getNotifications({
    required NotificationParams params,
  });
}

class NotificationDatasourceImpl implements NotificationDatasource {
  final ApiService _apiService;

  const NotificationDatasourceImpl(this._apiService);

  @override
  Future<Either<Failure, ApiResponse>> toggleNotification({
    required bool isEnabled,
    required String? fcm,
  }) {
    return handleNetworkError(() async {
      final response = await _apiService.post(
        ApiEndpoints.toggleNotification,
        data: {'token': fcm},
      );
      return ApiResponse.fromMap(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<Either<Failure, ApiResponse>> deleteNotification(
    String notificationId,
  ) {
    return handleNetworkError(() async {
      final response = await _apiService.delete(
        ApiEndpoints.notificationById(notificationId),
      );
      return NotificationModel.successEnvelopeFromResponse(
        response.data as Map<String, dynamic>,
        fallbackMessage: 'Failed to delete notification',
      );
    });
  }

  @override
  Future<Either<Failure, ApiResponse>> deleteAllNotifications() {
    return handleNetworkError(() async {
      final response = await _apiService.delete(
        ApiEndpoints.deleteAllNotifications,
      );
      return NotificationModel.successEnvelopeFromResponse(
        response.data as Map<String, dynamic>,
        fallbackMessage: 'Failed to delete notifications',
      );
    });
  }

  @override
  Future<Either<Failure, List<NotificationModel>>> getNotifications({
    required NotificationParams params,
  }) {
    return handleNetworkError(() async {
      final response = await _apiService.get(
        ApiEndpoints.getNotifications,
        queryParameters: params.toJson(),
      );
      return NotificationModel.listFromResponse(
        response.data as Map<String, dynamic>,
      );
    });
  }
}
