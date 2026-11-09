import '../../domain/entities/review_entity.dart';
import '../../domain/entities/review_response_entity.dart';

sealed class FeedbackState {
  const FeedbackState();
}

class FeedbackInitial extends FeedbackState {
  const FeedbackInitial();
}

class FeedbackLoading extends FeedbackState {
  const FeedbackLoading();
}

class FeedbackError extends FeedbackState {
  final String message;
  const FeedbackError(this.message);
}

class FeedbackSuccess extends FeedbackState {
  final String message;
  const FeedbackSuccess(this.message);
}

/// Reviews fetched successfully
// class ReviewsSuccess extends FeedbackState {
//   // final ReviewsResponseEntity reviews;
//   final List<ReviewEntity> reviews;
//   final bool hasMore;
//   final bool isLoadingMore;

//   const ReviewsSuccess({
//     required this.reviews,
//     required this.hasMore,
//     this.isLoadingMore = false,
//   });
// }
class ReviewsSuccess extends FeedbackState {
  final List<ReviewEntity> reviews;
  final bool hasMore;
  final bool isLoadingMore;

  /// NEW
  final DriverEntity driver;
  final int completedRides;

  const ReviewsSuccess({
    required this.reviews,
    required this.hasMore,
    required this.driver,
    required this.completedRides,
    this.isLoadingMore = false,
  });
}
