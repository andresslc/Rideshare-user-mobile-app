import 'package:ride_app/features/reviews/domain/entities/pagination_entity.dart';
import 'package:ride_app/features/reviews/domain/entities/review_entity.dart';

class ReviewsResponseEntity {
  // final ReviewsSummaryEntity? summary;
  final DriverEntity? driver;
  final int? completedRides;
  final List<ReviewEntity> reviews;
  final PaginationEntity pagination;

  const ReviewsResponseEntity({
    // this.summary,
    this.driver,
    this.completedRides,
    required this.reviews,
    required this.pagination,
  });
}

class DriverEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final double rating;
  final DateTime? dob;

  const DriverEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    required this.rating,
    this.dob,
  });

  String get fullName {
    final parts = <String>[firstName.trim()];
    final trimmedLastName = lastName.trim();
    if (trimmedLastName.isNotEmpty) {
      parts.add(trimmedLastName);
    }
    return parts.join(' ').trim();
  }
}
