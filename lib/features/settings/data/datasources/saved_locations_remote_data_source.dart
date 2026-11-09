import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/params/location_params.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/features/settings/data/models/saved_location_model.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

abstract class SavedLocationsRemoteDataSource {
  Future<Either<Failure, (List<SavedLocationModel>, Pagination?)>>
      getSavedLocations({int page, int limit});

  Future<Either<Failure, SavedLocationModel>> saveLocation(
    SaveLocationParams params,
  );

  Future<Either<Failure, SavedLocationModel>> updateLocation(
    String locationId,
    SaveLocationParams params,
  );

  Future<Either<Failure, ApiResponse>> deleteLocation(String locationId);

  Future<Either<Failure, ApiResponse>> reorderSavedLocations(
    List<String> locationIds,
  );
}

class SavedLocationsRemoteDataSourceImpl
    implements SavedLocationsRemoteDataSource {
  final ApiService _apiService = locator<ApiService>();

  @override
  Future<Either<Failure, (List<SavedLocationModel>, Pagination?)>>
      getSavedLocations({int page = 1, int limit = 50}) {
    return handleNetworkError(() async {
      final response = await _apiService.get(
        ApiEndpoints.myLocations,
        queryParameters: <String, dynamic>{'page': page, 'limit': limit},
      );

      final apiResponse = ApiResponse.fromMap(response.data);
      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Failed to fetch locations');
      }

      final dynamic rawData = apiResponse.data;
      final Map<String, dynamic> data = rawData is Map<String, dynamic>
          ? rawData
          : <String, dynamic>{};
      final List<dynamic> rawLocations = _extractLocations(rawData, data);
      final locations = rawLocations
          .map(
            (item) => SavedLocationModel.fromJson(item as Map<String, dynamic>),
          )
          .where((item) => !item.isDeleted)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      final pagination = apiResponse.pagination ?? _extractPagination(data);
      return (locations, pagination);
    });
  }

  @override
  Future<Either<Failure, SavedLocationModel>> saveLocation(
    SaveLocationParams params,
  ) {
    return handleNetworkError(() async {
      final response = await _apiService.post(
        ApiEndpoints.saveLocation,
        data: params.toJson(),
      );

      final apiResponse = ApiResponse.fromMap(response.data);
      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Failed to save location');
      }

      final dynamic rawData = apiResponse.data;
      final Map<String, dynamic> data = rawData is Map<String, dynamic>
          ? rawData
          : <String, dynamic>{};
      final rawLocation = _extractSingleLocation(rawData, data);
      if (rawLocation == null) {
        throw Exception('Invalid save location response');
      }

      return SavedLocationModel.fromJson(rawLocation);
    });
  }

  @override
  Future<Either<Failure, SavedLocationModel>> updateLocation(
    String locationId,
    SaveLocationParams params,
  ) {
    return handleNetworkError(() async {
      final response = await _apiService.patch(
        ApiEndpoints.locationById(locationId),
        data: params.toJson(),
      );

      final apiResponse = ApiResponse.fromMap(response.data);
      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Failed to update location');
      }

      final dynamic rawData = apiResponse.data;
      final Map<String, dynamic> data = rawData is Map<String, dynamic>
          ? rawData
          : <String, dynamic>{};
      final rawLocation = _extractSingleLocation(rawData, data);
      if (rawLocation == null) {
        throw Exception('Invalid update location response');
      }

      return SavedLocationModel.fromJson(rawLocation);
    });
  }

  @override
  Future<Either<Failure, ApiResponse>> deleteLocation(String locationId) {
    return handleNetworkError(() async {
      final response = await _apiService.delete(
        ApiEndpoints.locationById(locationId),
      );
      final apiResponse = ApiResponse.fromMap(response.data);
      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Failed to delete location');
      }
      return apiResponse;
    });
  }

  @override
  Future<Either<Failure, ApiResponse>> reorderSavedLocations(
    List<String> locationIds,
  ) {
    return handleNetworkError(() async {
      final response = await _apiService.patch(
        ApiEndpoints.reorderLocations,
        data: <String, dynamic>{'locations': locationIds},
      );
      final apiResponse = ApiResponse.fromMap(response.data);
      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Failed to reorder locations');
      }
      return apiResponse;
    });
  }

  List<dynamic> _extractLocations(dynamic rawData, Map<String, dynamic> data) {
    if (data['locations'] is List<dynamic>) {
      return data['locations'] as List<dynamic>;
    }
    if (data['savedLocations'] is List<dynamic>) {
      return data['savedLocations'] as List<dynamic>;
    }
    if (rawData is List<dynamic>) {
      return rawData;
    }
    return <dynamic>[];
  }

  Map<String, dynamic>? _extractSingleLocation(
    dynamic rawData,
    Map<String, dynamic> data,
  ) {
    if (data['location'] is Map<String, dynamic>) {
      return data['location'] as Map<String, dynamic>;
    }
    if (data['savedLocation'] is Map<String, dynamic>) {
      return data['savedLocation'] as Map<String, dynamic>;
    }
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }
    return null;
  }

  Pagination? _extractPagination(Map<String, dynamic> data) {
    final dynamic rawPagination = data['pagination'];
    if (rawPagination is! Map<String, dynamic>) {
      return null;
    }
    return Pagination.fromMap(rawPagination);
  }
}

