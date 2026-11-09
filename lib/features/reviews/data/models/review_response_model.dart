import 'package:ride_app/core/utils/dob_json.dart';
import 'package:ride_app/features/reviews/data/models/pagination_model.dart';
import 'package:ride_app/features/reviews/data/models/review_model.dart';
import '../../domain/entities/review_response_entity.dart';

// class ReviewsResponseModel extends ReviewsResponseEntity {
//   ReviewsResponseModel({
//     required super.summary,
//     required super.reviews,
//     required super.pagination,
//   });

//   factory ReviewsResponseModel.fromJson(Map<String, dynamic> json) {
//     return ReviewsResponseModel(
//       summary: ReviewsSummaryModel.fromJson(json['data']['summary']),
//       reviews: (json['data']['reviews'] as List)
//           .map((e) => ReviewModel.fromJson(e))
//           .toList(),
//       pagination: PaginationModel.fromJson(json['pagination']),
//     );
//   }
// }

class ReviewsResponseModel extends ReviewsResponseEntity {
  ReviewsResponseModel({
    // super.summary,
    super.driver,
    super.completedRides,
    required super.reviews,
    required super.pagination,
  });

  factory ReviewsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return ReviewsResponseModel(
      driver: data['driver'] != null
          ? DriverModel.fromJson(data['driver'])
          : null,

      completedRides: data['completedRides'],

      reviews: (data['reviews'] as List)
          .map((e) => ReviewModel.fromJson(e))
          .toList(),

      pagination: PaginationModel.fromJson(json['pagination']),

      // old summary support agar backend kabhi bheje
      // summary: data['summary'] != null
      //     ? ReviewsSummaryModel.fromJson(data['summary'])
      //     : null,
    );
  }
}

// class ReviewsSummaryModel extends ReviewsSummaryEntity {
//   ReviewsSummaryModel({
//     required super.averageRating,
//     required super.totalReviews,
//     required super.breakdown,
//   });

//   factory ReviewsSummaryModel.fromJson(Map<String, dynamic> json) {
//     final raw = Map<String, dynamic>.from(json['breakdown'] ?? {});

//     return ReviewsSummaryModel(
//       averageRating: (json['averageRating'] as num).toDouble(),
//       totalReviews: json['totalReviews'],
//       breakdown: raw.map((k, v) => MapEntry(k, v as int)),
//     );
//   }
// }

class DriverModel extends DriverEntity {
  DriverModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.profilePicture,
    required super.rating,
    super.dob,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['_id'] ?? "",
      firstName: json['firstName']?.toString() ?? "",
      lastName: json['lastName']?.toString() ?? "",
      profilePicture: json['profilePicture'] ?? "",
      rating: (json['rating'] ?? 0).toDouble(),
      dob: parseDobFromJson(json['dob']),
    );
  }
}
