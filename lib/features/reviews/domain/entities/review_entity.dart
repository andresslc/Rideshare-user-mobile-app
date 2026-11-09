class ReviewEntity {
  final String id;
  final String reviewerName;
  final String reviewerImage;
  final String reviewerId;
  final int stars;
  final String description;
  final bool isAnonymous;
  final String rideId;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.reviewerName,
    required this.reviewerImage,
    required this.reviewerId,
    required this.stars,
    required this.description,
    required this.isAnonymous,
    required this.rideId,
    required this.createdAt,
  });
}
