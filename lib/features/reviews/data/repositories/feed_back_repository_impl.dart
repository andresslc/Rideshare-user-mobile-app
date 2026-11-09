
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/feedback_params.dart';
import '../../../../core/params/report_params.dart';
import '../../../../core/params/review_request_param.dart';
import '../../domain/entities/review_response_entity.dart';
import '../../domain/repositories/feed_back_repository.dart';
import '../datasources/feed_back_datasource.dart';

abstract class FeedBackRepositoryInternal implements FeedBackRepository {}

class FeedBackRepositoryImpl implements FeedBackRepository {
  final FeedbackRemoteDataSource dataSource;

  FeedBackRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, String>> feedback({
    required FeedbackParam params,
  }) async {
    final response = await dataSource.submitFeedback(params: params);
    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (message) => Right(message),
    );
  }
//report
@override
  Future<Either<Failure, String>> report({
    required ReportParam params,
  }) async {
    final response = await dataSource.report(params: params);
    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (message) => Right(message),
    );
  }
  /// ------------------------------
  /// GET REVIEWS
  /// ------------------------------
  @override
  Future<Either<Failure, ReviewsResponseEntity>> getReviews({
     required ReviewsRequestParams params,
  }) async {
    final response = await dataSource.getReviews(
      params: params,
    );

    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (data) => Right(data),
    );
  }
}
