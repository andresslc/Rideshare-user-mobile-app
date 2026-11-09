import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../../core/params/feedback_params.dart';
import '../../../../core/params/review_request_param.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/entities/review_response_entity.dart';
import '../../domain/use_case/feedback_usecase.dart';
import '../../domain/use_case/get_review_usecase.dart';
import '../states/feedback_state.dart';

final feedbackProvider = NotifierProvider<FeedbackController, FeedbackState>(
  FeedbackController.new,
);

class FeedbackController extends Notifier<FeedbackState> {
  FeedBackUseCase get _feedbackUseCase => locator<FeedBackUseCase>();
  GetReviewUsecase get _getreviewUseCase => locator<GetReviewUsecase>();

  // 🔹 Pagination Variables
  int _currentPage = 1;
  DriverEntity? _driver;
  int _completedRides = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  List<ReviewEntity> _reviews = [];

  @override
  FeedbackState build() {
    return const FeedbackInitial();
  }

  /// ------------------------------
  /// SUBMIT FEEDBACK
  /// ------------------------------
  Future<void> submitFeedback(FeedbackParam params) async {
    state = const FeedbackLoading();

    final result = await _feedbackUseCase.call(params);

    result.fold(
      (failure) => state = FeedbackError(failure.message),
      (message) => state = FeedbackSuccess(message),
    );
  }

  /// ------------------------------
  /// FIRST PAGE LOAD
  /// ------------------------------
  Future<void> fetchReviews(String id) async {
    _currentPage = 1;
    _reviews.clear();
    state = const FeedbackLoading();

    final result = await _getreviewUseCase.fetchReviews(
      params: ReviewsRequestParams(page: _currentPage, id: id),
    );

    result.fold((failure) => state = FeedbackError(failure.message), (
      response,
    ) {
      _reviews = response.reviews;
      _driver = response.driver;
      _completedRides = response.completedRides ?? 0;

      _hasMore =
          response.pagination.currentPage < response.pagination.totalPages;

      state = ReviewsSuccess(
        reviews: _reviews,
        hasMore: _hasMore,
        driver: _driver!,
        completedRides: _completedRides,
      );
    });
  }

  /// ------------------------------
  /// LOAD MORE (Pagination)
  /// ------------------------------
  Future<void> loadMore(String id) async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    _currentPage++;

    final result = await _getreviewUseCase.fetchReviews(
      params: ReviewsRequestParams(page: _currentPage, id: id),
    );

    result.fold((failure) {}, (response) {
      _reviews.addAll(response.reviews);

      _hasMore =
          response.pagination.currentPage < response.pagination.totalPages;

      state = ReviewsSuccess(
        reviews: _reviews,
        hasMore: _hasMore,
        driver: _driver!,
        completedRides: _completedRides,
        isLoadingMore: true,
      );
    });

    _isLoadingMore = false;
  }
}
