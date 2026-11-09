import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/params/carpool_param.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failure.dart';

import '../../../../core/params/carpool_detail_params.dart';
import '../../../../core/params/ride_history_detail_params.dart';
import '../../../../core/params/ride_history_param.dart';
import '../../../../core/services/api_service.dart';
import '../models/carpool_history_detail_model.dart';
import '../models/carpool_history_model.dart';
import '../models/ride_history_detail_model.dart';

import '../models/ride_history_model.dart';

abstract class RideHistoryRemoteDataSource {
  Future<Either<Failure, RideHistoryResponseModel>> getRideHistory({
    required RideHistoryRequestParams params,
  });
  Future<Either<Failure, CarpoolHistoryResponseModel>> getCarpoolHistory({
    required CarpoolParam params,
  });
  Future<Either<Failure, RideDetailResponseModel>> getRideDetail({
    required RideHistoryDetailParams params,
  });

  Future<Either<Failure, CarpoolModel>> getCarpoolDetail({
    required CarpoolDetailParams params,
  });
}

class RideHistoryRemoteDataSourceImpl implements RideHistoryRemoteDataSource {
  final ApiService _apiService;

  RideHistoryRemoteDataSourceImpl(this._apiService);

  @override
  Future<Either<Failure, RideHistoryResponseModel>> getRideHistory({
    required RideHistoryRequestParams params,
  }) {
    return handleNetworkError(() async {
      final queryParams = <String, dynamic>{};
      if (params.status != null) queryParams['status'] = params.status;
      if (params.cancelledBy != null) {
        queryParams['cancelledBy'] = params.cancelledBy;
      }
      final res = await _apiService.get(
        ApiEndpoints.ridehistory,
        queryParameters: queryParams,
      );
      return RideHistoryResponseModel.fromJson(res.data);
    });
  }

  @override
  Future<Either<Failure, RideDetailResponseModel>> getRideDetail({
    required RideHistoryDetailParams params,
  }) async {
    return handleNetworkError(() async {
      final res = await _apiService.get(
        '${ApiEndpoints.ridedetail}${params.id}',
      );
      return RideDetailResponseModel.fromJson(res.data['data']);
    });
  }

  @override
  Future<Either<Failure, CarpoolHistoryResponseModel>> getCarpoolHistory({
    required CarpoolParam params,
  }) async {
    return handleNetworkError(() async {
      final res = await _apiService.get(
        ApiEndpoints.carpoolhistory,
        queryParameters: params.toJson(),
      );
      return CarpoolHistoryResponseModel.fromJson(res.data);
    });
  }

  @override
  Future<Either<Failure, CarpoolModel>> getCarpoolDetail({
    required CarpoolDetailParams params,
  }) async {
    return handleNetworkError(() async {
      final res = await _apiService.get(ApiEndpoints.carpooldetail(params.id));
      return CarpoolModel.fromJson(res.data["data"]);
    });
  }
}

