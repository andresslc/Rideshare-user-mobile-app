import 'package:dio/dio.dart';

import 'failure.dart';

/// Maps [DioException] types to domain [Failure] objects.
class ErrorHandler {
  static ServerFailure handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerFailure(message: 'Connection timed out');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        String message = 'Something went wrong';
        if (data is Map<String, dynamic>) {
          message = data['message']?.toString() ?? message;
        }

        return ServerFailure(
          message: message,
          statusCode: statusCode,
          error: e,
        );

      case DioExceptionType.cancel:
        return const ServerFailure(message: 'Request was cancelled');

      case DioExceptionType.connectionError:
        return const ServerFailure(message: 'No internet connection');

      case DioExceptionType.unknown:
      default:
        return ServerFailure(
          message: e.message ?? 'An unexpected error occurred',
          error: e,
        );
    }
  }
}
