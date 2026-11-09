import '../../domain/enitities/ride_history_detail_entities.dart';

class RideDetailResponseModel extends RideDetailResponseEntity {
  RideDetailResponseModel({required super.ride, required super.reviews});

  factory RideDetailResponseModel.fromJson(Map<String, dynamic> json) {
    final rideJson = json['ride'] ?? {};

    return RideDetailResponseModel(
      ride: RideDetailModel.fromJson(rideJson),
      reviews:
          (rideJson['review'] as List?)
              ?.map((e) => ReviewHistoryModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RideDetailModel extends RideDetailEntity {
  RideDetailModel({
    required super.id,
    required super.user,
    required super.reviews,
    required super.pickupPoint,
    required super.dropOffPointRequested,
    required super.specialRequest,
    required super.rideStatus,
    required super.rideType,
    required super.rideDistance,
    required super.paymentMethod,
    required super.rideFare,
    required super.averageTime,
    required super.paymentStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.driver,
    required super.transaction,
  });

  factory RideDetailModel.fromJson(Map<String, dynamic> json) {
    final reviewsJson = (json['review'] as List?) ?? const [];

    return RideDetailModel(
      id: json['id'] ?? '',
      user: UserDetailModel.fromJson(json['user'] ?? {}),
      reviews: reviewsJson.map((e) => ReviewHistoryModel.fromJson(e)).toList(),
      pickupPoint: LocationModel.fromJson(json['pickupPoint'] ?? {}),
      dropOffPointRequested: LocationModel.fromJson(json['dropOffPoint'] ?? {}),
      specialRequest: json['specialRequest'] ?? '',
      rideStatus: json['status'] ?? '',
      rideType: json['rideType'] ?? '',
      rideDistance: (json['distance'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      rideFare: (json['fare'] as num?)?.toDouble() ?? 0,
      averageTime: json['duration'] ?? 0,
      paymentStatus: json['paymentStatus'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      driver: DriverDetailModel.fromJson(json['driver'] ?? {}),
      transaction: json['transaction'] != null
          ? TransactionModel.fromJson(json['transaction'])
          : TransactionModel.empty(),
    );
  }
}

class UserDetailModel extends UserDetailEntity {
  UserDetailModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.profilePicture,
    required super.rating,
    required super.reviewsReceived,
  });

  factory UserDetailModel.fromJson(Map<String, dynamic> json) {
    return UserDetailModel(
      id: json['id'] ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profilePicture: json['profilePicture'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsReceived: json['reviews'] ?? 0,
    );
  }
}

class DriverDetailModel extends DriverDetailEntity {
  DriverDetailModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.profilePicture,
    required super.rating,
    required super.reviewsReceived,
    required super.vehicleDetails,
  });

  factory DriverDetailModel.fromJson(Map<String, dynamic> json) {
    return DriverDetailModel(
      id: json['id'] ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profilePicture: json['profilePicture'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsReceived: json['reviews'] ?? 0,
      vehicleDetails: VehicleDetailsModel.fromJson(json['vehicle'] ?? {}),
    );
  }
}

class VehicleDetailsModel extends VehicleDetailsEntity {
  VehicleDetailsModel({
    required super.id,
    required super.make,
    required super.model,
    required super.yearOfManufacture,
    required super.color,
    required super.licensePlateNumber,
    required super.vehicleType,
  });

  factory VehicleDetailsModel.fromJson(Map<String, dynamic> json) {
    return VehicleDetailsModel(
      id: json['id'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      yearOfManufacture: json['year'] ?? 0,
      color: json['color'] ?? '',
      licensePlateNumber: json['plate'] ?? '',
      vehicleType: json['type'] ?? '',
    );
  }
}

class LocationModel extends LocationEntity {
  LocationModel({required super.placeName, required super.coordinates});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      placeName: json['placeName'] ?? '',
      coordinates: List<double>.from(
        (json['location']?['coordinates'] ?? []).map(
          (x) => (x as num).toDouble(),
        ),
      ),
    );
  }
}

class TransactionModel extends TransactionEntity {
  TransactionModel({
    required super.id,
    required super.amount,
    required super.type,
    required super.user,
    required super.userType,
    required super.status,
    required super.card,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: json['type'] ?? '',
      user: json['user'] ?? '',
      userType: json['userType'] ?? '',
      status: json['status'] ?? '',
      card: json['card'] != null
          ? CardModel.fromJson(json['card'])
          : CardModel.empty(),
    );
  }

  factory TransactionModel.empty() {
    return TransactionModel(
      id: '',
      amount: 0,
      type: '',
      user: '',
      userType: '',
      status: '',
      card: CardModel.empty(),
    );
  }
}

class CardModel extends CardEntity {
  CardModel({required super.id, required super.brand, required super.last4});
  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] ?? '',
      brand: json['brand'] ?? '',
      last4: json['last4'] ?? '',
    );
  }
  factory CardModel.empty() {
    return CardModel(id: '', brand: '', last4: '');
  }
}

class ReviewHistoryModel extends ReviewHistoryEntity {
  ReviewHistoryModel({
    required super.id,
    required super.reviewer,
    required super.receiver,
    required super.reviewerType,
    required super.receiverType,
    required super.stars,
    required super.description,
    required super.isAnonymous,
    required super.isDeleted,
    required super.ride,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ReviewHistoryModel.fromJson(Map<String, dynamic> json) {
    return ReviewHistoryModel(
      id: json['_id'] ?? "",
      reviewer: json['reviewer'] ?? "",
      receiver: json['receiver'] ?? "",
      reviewerType: json['reviewerType'] ?? "",
      receiverType: json['receiverType'] ?? "",
      stars: json['stars'] ?? 0,
      description: json['description'] ?? "",
      isAnonymous: json['isAnonymous'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      ride: json['ride']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // Map<String, dynamic> toJson() {
  //   return {
  //     "_id": id,
  //     "reviewer": reviewer,
  //     "receiver": receiver,
  //     "reviewerType": reviewerType,
  //     "receiverType": receiverType,
  //     "stars": stars,
  //     "description": description,
  //     "isAnonymous": isAnonymous,
  //     "isDeleted": isDeleted,
  //     "ride": ride,
  //     "createdAt": createdAt.toIso8601String(),
  //     "updatedAt": updatedAt.toIso8601String(),
  //   };
  // }
  factory ReviewHistoryModel.empty() {
    return ReviewHistoryModel(
      id: '',
      reviewer: '',
      receiver: '',
      reviewerType: '',
      receiverType: '',
      stars: 0,
      description: '',
      isAnonymous: false,
      isDeleted: false,
      ride: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
