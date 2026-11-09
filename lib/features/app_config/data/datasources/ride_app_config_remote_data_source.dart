import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/features/app_config/data/models/ride_app_config_model.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

abstract class RideAppConfigRemoteDataSource {
  /// `GET /api/config/ride`. Public: the search screen has to read correctly
  /// before anyone signs in.
  Future<Either<Failure, RideAppConfigModel>> fetch({required String locale});
}

class RideAppConfigRemoteDataSourceImpl
    implements RideAppConfigRemoteDataSource {
  final ApiService _apiService = locator<ApiService>();

  @override
  Future<Either<Failure, RideAppConfigModel>> fetch({
    required String locale,
  }) async {
    return handleNetworkError(() async {
      final response = await _apiService.get(
        ApiEndpoints.rideConfig,
        queryParameters: <String, dynamic>{'locale': locale},
      );
      final dynamic payload = ApiResponse.fromMap(response.data).data;
      final Map<String, dynamic>? map = _asMap(payload);
      if (map == null) {
        throw Exception('Ride configuration response payload is invalid');
      }
      return RideAppConfigModel.fromJson(map);
    });
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
