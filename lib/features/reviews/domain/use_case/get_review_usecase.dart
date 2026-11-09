
import '../../../../core/params/review_request_param.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/review_response_entity.dart';
import '../repositories/feed_back_repository.dart';

class GetReviewUsecase {
  final FeedBackRepository _repository;
  GetReviewUsecase(this._repository);

  FutureEither<ReviewsResponseEntity> fetchReviews({
    required ReviewsRequestParams params,
  }) async {
    return _repository.getReviews(params: params);
  }
}
