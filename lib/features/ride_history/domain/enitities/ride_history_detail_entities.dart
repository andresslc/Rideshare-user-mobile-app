class RideDetailResponseEntity {
  final RideDetailEntity ride;
  final List<ReviewHistoryEntity> reviews;

  RideDetailResponseEntity({required this.ride, required this.reviews});
}

class RideDetailEntity {
  final String id;
  final UserDetailEntity user;
  final List<ReviewHistoryEntity> reviews;
  final LocationEntity pickupPoint;
  final LocationEntity dropOffPointRequested;
  final String specialRequest;
  final String rideStatus;
  final String rideType;
  final double rideDistance;
  final String paymentMethod;
  final double rideFare;
  final int averageTime;
  final String paymentStatus;
  final DateTime createdAt;

  final DateTime updatedAt;
  final DriverDetailEntity driver;
  final TransactionEntity transaction;

  RideDetailEntity({
    required this.id,
    required this.user,
    required this.reviews,
    required this.pickupPoint,
    required this.dropOffPointRequested,
    required this.specialRequest,
    required this.rideStatus,
    required this.rideType,
    required this.rideDistance,
    required this.paymentMethod,
    required this.rideFare,
    required this.averageTime,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.driver,
    required this.transaction,
  });
}

class UserDetailEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String profilePicture;
  final num rating;
  final int reviewsReceived;

  UserDetailEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.rating,
    required this.reviewsReceived,
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

class DriverDetailEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String profilePicture;
  final double rating;
  final int reviewsReceived;
  final VehicleDetailsEntity vehicleDetails;

  DriverDetailEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.rating,
    required this.reviewsReceived,
    required this.vehicleDetails,
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

class VehicleDetailsEntity {
  final String id;
  final String make;
  final String model;
  final int yearOfManufacture;
  final String color;
  final String licensePlateNumber;
  final String vehicleType;

  VehicleDetailsEntity({
    required this.id,
    required this.make,
    required this.model,
    required this.yearOfManufacture,
    required this.color,
    required this.licensePlateNumber,
    required this.vehicleType,
  });
}

class LocationEntity {
  final String placeName;
  final List<double> coordinates;

  LocationEntity({required this.placeName, required this.coordinates});
}

class TransactionEntity {
  final String id;
  final double amount;
  final String type;
  final String user;
  final String userType;
  final String status;
  final CardEntity card;

  TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.user,
    required this.userType,
    required this.status,
    required this.card,
  });
}

class CardEntity {
  final String id;
  final String brand;
  final String last4;

  CardEntity({required this.id, required this.brand, required this.last4});
}

class ReviewHistoryEntity {
  final String id;
  final String reviewer;
  final String receiver;
  final String reviewerType;
  final String receiverType;
  final int stars;
  final String description;
  final bool isAnonymous;
  final bool isDeleted;
  final String? ride;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewHistoryEntity({
    required this.id,
    required this.reviewer,
    required this.receiver,
    required this.reviewerType,
    required this.receiverType,
    required this.stars,
    required this.description,
    required this.isAnonymous,
    required this.isDeleted,
    required this.ride,
    required this.createdAt,
    required this.updatedAt,
  });
}
