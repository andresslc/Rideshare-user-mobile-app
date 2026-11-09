import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/shared/models/api_response_model.dart';
import '../../../../core/errors/failure.dart';

/// ===============================
/// ABSTRACT DATASOURCE
/// ===============================
abstract class ChangeLanguageDatasource {
  /// Change app language
  Future<Either<Failure, String>> changeLanguage(String languageCode);
}

/// ===============================
/// IMPLEMENTATION
/// ===============================
class ChangeLanguageDatasourceImpl implements ChangeLanguageDatasource {
  final ApiService apiService = locator<ApiService>();

  /// ---------------------------------
  /// CHANGE LANGUAGE
  /// ---------------------------------
  @override
  Future<Either<Failure, String>> changeLanguage(String languageCode) {
    return handleNetworkError(() async {
      final response = await apiService.post(
        ApiEndpoints.changeLanguage,
        data: {'locale': languageCode},
      );

      final apiResponse = ApiResponse.fromMap(response.data);
      return apiResponse.message ?? 'Language changed successfully';
    });
  }
}

