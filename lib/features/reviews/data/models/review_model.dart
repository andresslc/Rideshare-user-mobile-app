import '../../domain/entities/review_entity.dart';

class ReviewModel extends ReviewEntity {
  ReviewModel({
    required super.id,
    required super.reviewerName,
    required super.reviewerImage,
    required super.reviewerId,
    required super.stars,
    required super.description,
    required super.isAnonymous,
    required super.rideId,
    required super.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] as Map<String, dynamic>? ?? {};

    final firstName = reviewer['firstName']?.toString().trim() ?? '';
    final lastName = reviewer['lastName']?.toString().trim() ?? '';
    final directName = reviewer['name']?.toString().trim() ?? '';

    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final reviewerName = fullName.isNotEmpty ? fullName : directName;

    return ReviewModel(
      id: json['_id'] ?? '',
      reviewerId: reviewer['_id'] ?? '',
      reviewerName: reviewerName,
      reviewerImage: reviewer['profilePicture'] ?? '',
      stars: json['stars'] ?? 0,
      description: json['description'] ?? '',
      isAnonymous: json['isAnonymous'] ?? false,
      rideId: json['ride'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime(1970),
    );
  }
}
