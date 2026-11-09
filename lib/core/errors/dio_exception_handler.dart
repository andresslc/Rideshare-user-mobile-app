import 'package:dio/dio.dart';
import 'package:ride_app/core/errors/network_exception.dart';
import '../utils/app_log.dart';

class CustomDioException extends DioException {
  final String customMessage;
  final dynamic responseData;

  CustomDioException({
    required super.requestOptions,
    required this.customMessage,
    this.responseData,
    super.response,
    super.type,
    super.error,
  });

  @override
  String toString() {
    return 'CustomDioException: $customMessage (Status Code: ${response?.statusCode})';
  }

  /// Dio error ko custom exception me convert karne ka method
  static CustomDioException fromDioError(DioException dioError) {
    String errorMessage = NetworkExceptions.handleException(dioError);
    dynamic responseData;

    if (dioError.response != null) {
      responseData = dioError.response?.data;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('message')) {
        errorMessage = responseData['message']; // Backend ka error message
      }

      log(
        name: 'API Error (${dioError.response?.statusCode})',
        responseData.toString(),
        // category: LogCategory.apiError,
      );
    }

    return CustomDioException(
      requestOptions: dioError.requestOptions,
      response: dioError.response,
      type: dioError.type,
      error: dioError.error,
      customMessage: errorMessage,
      responseData: responseData,
    );
  }
}
