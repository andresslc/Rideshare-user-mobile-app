import 'package:dio/dio.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/services/network_quality_service.dart';

/// Feeds timeout events from the main API client into [NetworkQualityService].
class NetworkQualityInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (locator.isRegistered<NetworkQualityService>()) {
      locator<NetworkQualityService>().recordRequestSuccess();
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isTimeout(err) && locator.isRegistered<NetworkQualityService>()) {
      locator<NetworkQualityService>().recordRequestTimeout();
    }
    super.onError(err, handler);
  }

  bool _isTimeout(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;
  }
}
