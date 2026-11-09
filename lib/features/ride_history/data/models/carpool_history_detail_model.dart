// import 'package:ride_app/features/ride_history.dart/domain/enitities/carpool_history_detail_entities.dart';

// class CarpoolModel extends CarpoolEntity {
//   CarpoolModel({
//     required super.id,
//     required super.driver,
//     required super.startingPoint,
//     required super.destination,
//     required super.routes,
//     required super.status,
//     required super.maxPassengers,
//     required super.availableSeats,
//     super.graceTime,
//     required super.passengers,
//     required super.createdAt,
//   });

//   factory CarpoolModel.fromJson(Map<String, dynamic> json) {
//     return CarpoolModel(
//       id: json['_id'] ?? '',
//       driver: CarpoolDriverModel.fromJson(json['driver'] ?? {}),
//       startingPoint: CarpoolPointModel.fromJson(json['startingPoint'] ?? {}),
//       destination: CarpoolPointModel.fromJson(json['destination'] ?? {}),
//       routes: (json['routes'] as List<dynamic>? ?? [])
//           .map((e) => CarpoolRouteModel.fromJson(e))
//           .toList(),
//       status: json['status'] ?? '',
//       maxPassengers: json['maxPassengers'] ?? 0,
//       availableSeats: json['availableSeats'] ?? 0,
//       graceTime: json['graceTime'] != null
//           ? DateTime.parse(json['graceTime'])
//           : null,
//       passengers: (json['passengers'] as List<dynamic>? ?? [])
//           .map((e) => CarpoolPassengerModel.fromJson(e))
//           .toList(),
//       createdAt: DateTime.parse(
//         json['createdAt'] ?? DateTime.now().toIso8601String(),
//       ),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'driver': (driver as CarpoolDriverModel).toJson(),
//       'startingPoint': (startingPoint as CarpoolPointModel).toJson(),
//       'destination': (destination as CarpoolPointModel).toJson(),
//       'routes': routes.map((e) => (e as CarpoolRouteModel).toJson()).toList(),
//       'status': status,
//       'maxPassengers': maxPassengers,
//       'availableSeats': availableSeats,
//       'graceTime': graceTime?.toIso8601String(),
//       'passengers': passengers
//           .map((e) => (e as CarpoolPassengerModel).toJson())
//           .toList(),
//       'createdAt': createdAt.toIso8601String(),
//     };
//   }
// }

// // Driver Model
// class CarpoolDriverModel extends CarpoolDriverEntity {
//   CarpoolDriverModel({
//     required super.id,
//     required super.name,
//     required super.email,
//     super.profilePicture,
//     super.vehicleDetails,
//     required super.rating,
//   });

//   factory CarpoolDriverModel.fromJson(Map<String, dynamic> json) {
//     return CarpoolDriverModel(
//       id: json['_id'] ?? '',
//       name: json['name'] ?? '',
//       email: json['email'] ?? '',
//       profilePicture: json['profilePicture'],
//       vehicleDetails: json['vehicleDetails'] != null
//           ? VehicleDetailsModel.fromJson(json['vehicleDetails'])
//           : null,
//       rating: (json['rating'] ?? 0).toDouble(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'name': name,
//       'email': email,
//       'profilePicture': profilePicture,
//       'vehicleDetails': vehicleDetails != null
//           ? (vehicleDetails as VehicleDetailsModel).toJson()
//           : null,
//       'rating': rating,
//     };
//   }
// }

// // Vehicle Model
// class VehicleDetailsModel extends VehicleDetailsEntity {
//   VehicleDetailsModel({
//     required super.id,
//     required super.make,
//     required super.model,
//     required super.yearOfManufacture,
//     required super.color,
//     required super.licensePlateNumber,
//     required super.vehicleType,
//   });

//   factory VehicleDetailsModel.fromJson(Map<String, dynamic> json) {
//     return VehicleDetailsModel(
//       id: json['_id'] ?? '',
//       make: json['make'] ?? '',
//       model: json['model'] ?? '',
//       yearOfManufacture: json['yearOfManufacture'] ?? 0,
//       color: json['color'] ?? '',
//       licensePlateNumber: json['licensePlateNumber'] ?? '',
//       vehicleType: json['vehicleType'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'make': make,
//       'model': model,
//       'yearOfManufacture': yearOfManufacture,
//       'color': color,
//       'licensePlateNumber': licensePlateNumber,
//       'vehicleType': vehicleType,
//     };
//   }
// }

// // Point Model
// class CarpoolPointModel extends CarpoolPointEntity {
//   CarpoolPointModel({required super.placeName, required super.location});

//   factory CarpoolPointModel.fromJson(Map<String, dynamic> json) {
//     return CarpoolPointModel(
//       placeName: json['placeName'] ?? '',
//       location: LocationModel.fromJson(json['location'] ?? {}),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'placeName': placeName,
//       'location': (location as LocationModel).toJson(),
//     };
//   }
// }

// // Location Model
// class LocationModel extends LocationEntity {
//   LocationModel({required super.type, required super.coordinates});

//   factory LocationModel.fromJson(Map<String, dynamic> json) {
//     return LocationModel(
//       type: json['type'] ?? '',
//       coordinates: (json['coordinates'] as List<dynamic>? ?? [])
//           .map((e) => (e as num).toDouble())
//           .toList(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {'type': type, 'coordinates': coordinates};
//   }
// }

// // Route Model
// class CarpoolRouteModel extends CarpoolRouteEntity {
//   CarpoolRouteModel({
//     required super.id,
//     required super.placeName,
//     required super.location,
//     required super.status,
//     required super.order,
//   });

//   factory CarpoolRouteModel.fromJson(Map<String, dynamic> json) {
//     return CarpoolRouteModel(
//       id: json['_id'] ?? '',
//       placeName: json['placeName'] ?? '',
//       location: LocationModel.fromJson(json['location'] ?? {}),
//       status: json['status'] ?? '',
//       order: json['order'] ?? 0,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'placeName': placeName,
//       'location': (location as LocationModel).toJson(),
//       'status': status,
//       'order': order,
//     };
//   }
// }

// // Passenger Model
// class CarpoolPassengerModel extends CarpoolPassengerEntity {
//   CarpoolPassengerModel({
//     required super.id,
//     required super.user,
//     required super.bookingId,
//     required super.pickupStop,
//     required super.dropOffStop,
//     required super.status,
//   });

//   factory CarpoolPassengerModel.fromJson(Map<String, dynamic> json) {
//     return CarpoolPassengerModel(
//       id: json['_id'] ?? '',
//       user: CarpoolUserModel.fromJson(json['user'] ?? {}),
//       bookingId: json['bookingId'] ?? '',
//       pickupStop: CarpoolRouteModel.fromJson(json['pickupStop'] ?? {}),
//       dropOffStop: CarpoolRouteModel.fromJson(json['dropOffStop'] ?? {}),
//       status: json['status'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'user': (user as CarpoolUserModel).toJson(),
//       'bookingId': bookingId,
//       'pickupStop': (pickupStop as CarpoolRouteModel).toJson(),
//       'dropOffStop': (dropOffStop as CarpoolRouteModel).toJson(),
//       'status': status,
//     };
//   }
// }

// // User Model
// class CarpoolUserModel extends CarpoolUserEntity {
//   CarpoolUserModel({
//     required super.id,
//     required super.name,
//     required super.email,
//     super.profilePicture,
//     required super.rating,
//   });

//   factory CarpoolUserModel.fromJson(Map<String, dynamic> json) {
//     return CarpoolUserModel(
//       id: json['_id'] ?? '',
//       name: json['name'] ?? '',
//       email: json['email'] ?? '',
//       profilePicture: json['profilePicture'],
//       rating: (json['rating'] ?? 0).toDouble(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'name': name,
//       'email': email,
//       'profilePicture': profilePicture,
//       'rating': rating,
//     };
//   }
// }

import 'package:ride_app/features/ride_history/domain/enitities/carpool_history_detail_entities.dart';

// Main Carpool Model
class CarpoolModel extends CarpoolEntity {
  CarpoolModel({
    required super.driver,
    required super.stops,
    required super.totalSeatsBooked,
    required super.paymentMethod,
    required super.requiredSeats, // ✅ add
    required super.avgTime, // ✅ add
    required super.distance,
    required super.paymentStatus,
    required super.fareCharged,
    required super.status,
    super.review,
    super.transaction,
  });

  factory CarpoolModel.fromJson(Map<String, dynamic> json) {
    return CarpoolModel(
      driver: CarpoolDriverModel.fromJson(json['driver'] ?? {}),
      stops: (json['stops'] as List<dynamic>? ?? [])
          .map((e) => CarpoolStopModel.fromJson(e))
          .toList(),
      totalSeatsBooked: json['totalSeatsBooked'] ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      requiredSeats: json['requiredSeats'] ?? 0, // ✅ add
      avgTime: json['avgTime'] ?? 0, // ✅ add
      distance: (json['distance'] ?? 0).toDouble(), // ✅ add
      fareCharged: (json['fareCharged'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      review: json['review'] != null
          ? CarpoolReviewModel.fromJson(json['review'])
          : null,
      transaction: json['transaction'] != null
          ? TransactionModel.fromJson(json['transaction'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver': (driver as CarpoolDriverModel).toJson(),
      'stops': stops.map((e) => (e as CarpoolStopModel).toJson()).toList(),
      'totalSeatsBooked': totalSeatsBooked,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'fareCharged': fareCharged,
      'status': status,
      'review': review != null ? (review as CarpoolReviewModel).toJson() : null,
    };
  }
}

// Driver Model
class CarpoolDriverModel extends CarpoolDriverEntity {
  CarpoolDriverModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.rating,
  });

  factory CarpoolDriverModel.fromJson(Map<String, dynamic> json) {
    return CarpoolDriverModel(
      id: json['_id'] ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName.trim(),
      'rating': rating,
    };
  }
}

// Stop Model
class CarpoolStopModel extends CarpoolStopEntity {
  CarpoolStopModel({
    required super.label,
    required super.placeName,
    required super.location,
    required super.status,
  });

  factory CarpoolStopModel.fromJson(Map<String, dynamic> json) {
    return CarpoolStopModel(
      label: json['label'] ?? '',
      placeName: json['placeName'] ?? '',
      location: LocationModel.fromJson(json['location'] ?? {}),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'placeName': placeName,
      'location': (location as LocationModel).toJson(),
      'status': status,
    };
  }
}

// Location Model
class LocationModel extends LocationEntity {
  LocationModel({required super.type, required super.coordinates});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      type: json['type'] ?? '',
      coordinates: (json['coordinates'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }
}

// Review Model
class CarpoolReviewModel extends CarpoolReviewEntity {
  CarpoolReviewModel({
    required super.id,
    required super.stars,
    required super.description,
    required super.isAnonymous,
  });

  factory CarpoolReviewModel.fromJson(Map<String, dynamic> json) {
    return CarpoolReviewModel(
      id: json['_id'] ?? '',
      stars: (json['stars'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      isAnonymous: json['isAnonymous'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'stars': stars,
      'description': description,
      'isAnonymous': isAnonymous,
    };
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
    super.card,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      user: json['user'] ?? '',
      userType: json['userType'] ?? '',
      status: json['status'] ?? '',
      card: json['card'] != null ? CardModel.fromJson(json['card']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'amount': amount,
      'type': type,
      'user': user,
      'userType': userType,
      'status': status,
      'card': card != null ? (card as CardModel).toJson() : null,
    };
  }
}

class CardModel extends CardEntity {
  CardModel({required super.id, required super.brand, required super.last4});

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['_id'] ?? '',
      brand: json['brand'] ?? '',
      last4: json['last4'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'brand': brand, 'last4': last4};
  }
}
