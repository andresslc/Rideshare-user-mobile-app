import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/params/apply_promo_code_params.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/features/ride_room/data/models/apply_promo_code_model.dart';
import 'package:ride_app/features/ride_room/data/models/ride_model.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

import '../models/share_ride_model.dart';

abstract class RideDetailsRemoteDataSource {
  Future<Either<Failure, RideModel>> getRideById(String rideId);
  Future<Either<Failure, PromoCodeModel>> applyPromoCode(
    ApplyPromoCodeParams params,
  );

  Future<Either<Failure, ShareRideModel>> getShareRideUrl(String rideId);
  Future<Either<Failure, ShareRideModel>> getShareCarpoolRideUrl(String rideId);
  Future<Either<Failure, Unit>> notifyRiderComing(String rideId);
}

class RideDetailsRemoteDataSourceImpl implements RideDetailsRemoteDataSource {
  final ApiService _apiService = locator<ApiService>();

  @override
  Future<Either<Failure, RideModel>> getRideById(String rideId) {
    return handleNetworkError(() async {
      final response = await _apiService.get(ApiEndpoints.rideById(rideId));
      final apiResponse = ApiResponse.fromMap(response.data);
      final payload = apiResponse.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Ride detail response payload is invalid');
      }
      return RideModel.fromJson(payload);
    });
  }

  @override
  Future<Either<Failure, ShareRideModel>> getShareRideUrl(String rideId) {
    return handleNetworkError(() async {
      final response = await _apiService.get(ApiEndpoints.shareRideUrl(rideId));
      final apiResponse = ApiResponse.fromMap(response.data);
      final payload = apiResponse.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Share ride URL response payload is invalid');
      }
      return ShareRideModel.fromResponse(response.data);
    });
  }

  @override
  Future<Either<Failure, ShareRideModel>> getShareCarpoolRideUrl(
    String rideId,
  ) {
    return handleNetworkError(() async {
      final response = await _apiService.get(
        ApiEndpoints.shareCarpoolRideUrl(rideId),
      );
      final apiResponse = ApiResponse.fromMap(response.data);
      final payload = apiResponse.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Share carpool URL response payload is invalid');
      }
      return ShareRideModel.fromResponse(response.data);
    });
  }

  @override
  Future<Either<Failure, Unit>> notifyRiderComing(String rideId) {
    return handleNetworkError(() async {
      final response = await _apiService.post(ApiEndpoints.riderComing(rideId));
      final raw = response.data;
      if (raw is! Map) {
        throw Exception('Rider coming response payload is invalid');
      }
      final data = Map<String, dynamic>.from(raw);
      final apiResponse = ApiResponse.fromMap(data);
      if (data.containsKey('success') && !apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Could not notify driver');
      }
      return unit;
    });
  }

  @override
  Future<Either<Failure, PromoCodeModel>> applyPromoCode(
    ApplyPromoCodeParams params,
  ) {
    return handleNetworkError(() async {
      final response = await _apiService.post(
        ApiEndpoints.promocode,
        data: params.toJson(),
      );
      final raw = response.data;
      if (raw is! Map) {
        throw Exception('Apply promo code response payload is invalid');
      }
      final map = Map<String, dynamic>.from(raw);
      final apiResponse = ApiResponse.fromMap(map);

      return PromoCodeModel.fromJson(apiResponse.data);
    });
  }
}
