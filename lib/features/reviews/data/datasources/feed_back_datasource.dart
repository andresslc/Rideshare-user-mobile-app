import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/feedback_params.dart';
import '../../../../core/params/report_params.dart';
import '../../../../core/params/review_request_param.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/review_response_entity.dart';
import '../models/review_response_model.dart';

abstract class FeedbackRemoteDataSource {
  Future<Either<Failure, String>> submitFeedback({
    required FeedbackParam params,
  });
  Future<Either<Failure, String>> report({required ReportParam params});

  Future<Either<Failure, ReviewsResponseEntity>> getReviews({
    required ReviewsRequestParams params,
  });
}

/// Implementation
// class FeedbackRemoteDataSourceImpl implements FeedbackRemoteDataSource {
//   final ApiService _apiService;
//   FeedbackRemoteDataSourceImpl(this._apiService);

//   @override
//   Future<Either<Failure, String>> submitFeedback({
//     required FeedbackParam params,
//   }) async {
//     return handleNetworkError(() async {
//       final res = await _apiService.post(
//         ApiEndpoints.review,
//         data: params.toJson(),
//       );
//       final ApiResponse response = ApiResponse.fromMap(res.data);
//       return response.message ?? '';
//     });
//   }

//   @override
//   Future<Either<Failure, ReviewsResponseEntity>> getReviews({
//     required String receiverId,
//     required String receiverType,
//   }) async {
//     return handleNetworkError(() async {
//       final res = await _apiService.get(
//         ApiEndpoints.review,
//         queryParameters: {
//           "receiverId": receiverId,
//           "receiverType": receiverType, // Driver | User
//         },
//       );

//       final ApiResponse response = ApiResponse.fromMap(res.data);
//       return ReviewsResponseModel.fromJson(response.data);
//     });
//   }
// }

class FeedbackRemoteDataSourceImpl implements FeedbackRemoteDataSource {
  final ApiService _apiService;
  FeedbackRemoteDataSourceImpl(this._apiService);

  @override
  Future<Either<Failure, String>> submitFeedback({
    required FeedbackParam params,
  }) async {
    return handleNetworkError(() async {
      final res = await _apiService.post(
        ApiEndpoints.review,
        data: params.toJson(),
      );
      final ApiResponse response = ApiResponse.fromMap(res.data);
      return response.message ?? '';
    });
  }

  @override
  Future<Either<Failure, String>> report({required ReportParam params}) async {
    return handleNetworkError(() async {
      final res = await _apiService.post(
        ApiEndpoints.report,
        data: params.toJson(),
      );
      final ApiResponse response = ApiResponse.fromMap(res.data);
      return response.message ?? '';
    });
  }

  @override
  Future<Either<Failure, ReviewsResponseEntity>> getReviews({
    required ReviewsRequestParams params,
  }) async {
    return handleNetworkError(() async {
      final res = await _apiService.get(
        // ApiEndpoints.review,
        ApiEndpoints.driverProfile(params.id),
      );
      // final ApiResponse response = ApiResponse.fromMap(res.data);
      return ReviewsResponseModel.fromJson(res.data);
    });
  }
}
