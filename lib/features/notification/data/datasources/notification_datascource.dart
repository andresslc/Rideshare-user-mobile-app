import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/params/notification_params.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

import '../notification_model.dart';

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
  final ApiService apiService = locator<ApiService>();

  @override
  Future<Either<Failure, ApiResponse>> toggleNotification({
    required bool isEnabled,
    required String? fcm,
  }) {
    return handleNetworkError(() async {
      final res = await apiService.post(
        ApiEndpoints.toggleNotification,
        data: {"token": fcm}
        // data: {"fcm": fcm, "isEnabled": isEnabled},
      );
      return ApiResponse.fromMap(res.data);
    });
  }

  @override
  Future<Either<Failure, ApiResponse>> deleteNotification(
    String notificationId,
  ) {
    return handleNetworkError(() async {
      final res = await apiService.delete(
        ApiEndpoints.notificationById(notificationId),
      );
      final apiResponse = ApiResponse.fromMap(res.data);
      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Failed to delete notification');
      }
      return apiResponse;
    });
  }

  @override
  Future<Either<Failure, ApiResponse>> deleteAllNotifications() {
    return handleNetworkError(() async {
      final res = await apiService.delete(
        ApiEndpoints.deleteAllNotifications,
      );
      final apiResponse = ApiResponse.fromMap(res.data);
      if (!apiResponse.success) {
        throw Exception(
          apiResponse.message ?? 'Failed to delete notifications',
        );
      }
      return apiResponse;
    });
  }

  @override
  Future<Either<Failure, List<NotificationModel>>> getNotifications({
    required NotificationParams params,
  }) {
    return handleNetworkError(() async {
      final res = await apiService.get(
        ApiEndpoints.getNotifications,
        queryParameters: params.toJson(),
      );
      final data = res.data['data'] as List? ?? [];
      final notifications = data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return notifications;
    });
  }
}

// abstract class NotificationDatasource {
//   Future<Either<Failure, ApiResponse>> toggleNotification(bool isEnabled);
// }

// class NotificationDatasourceImpl implements NotificationDatasource {
//   final ApiService apiService = locator<ApiService>();

//   @override
//   Future<Either<Failure, ApiResponse>> toggleNotification(bool isEnabled) {
//     return handleNetworkError(() async {
//       final res = await apiService.post(
//         ApiEndpoints.toggleNotification,
//         // data: {'isNotificationEnabled': isEnabled},
//       );
//       return ApiResponse.fromMap(res.data);
//     });
//   }
// }

