import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/params/find_carpool_ride_params.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/features/ride_room/data/models/carpool_ride_response_model.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

abstract class CarpoolRideDataSource {
  Future<Either<Failure, CarpoolRideModel>> getCarpoolRideById(String rideId);

  Future<Either<Failure, CarpoolRideResponseModel>> findCarpoolRidesByAPI(
    FindCarpoolRideParams params,
  );
}

class CarpoolRideDataSourceImpl implements CarpoolRideDataSource {
  final ApiService apiService;

  CarpoolRideDataSourceImpl({required this.apiService});

  @override
  Future<Either<Failure, CarpoolRideModel>> getCarpoolRideById(String rideId) {
    return handleNetworkError(() async {
      final response = await apiService.get(ApiEndpoints.carpoolById(rideId));
      final apiResponse = ApiResponse.fromMap(response.data);
      final payload = apiResponse.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Carpool ride detail response payload is invalid');
      }
      return CarpoolRideModel.fromJson(payload['carpool']);
    }); 
  }

  @override
  Future<Either<Failure, CarpoolRideResponseModel>> findCarpoolRidesByAPI(
    FindCarpoolRideParams params,
  ) {
    return handleNetworkError(() async {
      final response = await apiService.post(
        ApiEndpoints.findCarpoolRides,
        data: params.toJson(),
      );
      final apiResponse = ApiResponse.fromMap(response.data);
      final payload = apiResponse.data;
      if (payload is! Map<String, dynamic>) {
        throw Exception('Carpool rides response payload is invalid');
      }
      return CarpoolRideResponseModel.fromJson(payload);
    });
  }
}

