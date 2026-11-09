// class GeoLocationEntity {
//   final double longitude;
//   final double latitude;

//   const GeoLocationEntity({required this.longitude, required this.latitude});
// }

// class RidePointEntity {
//   final String placeName;
//   final GeoLocationEntity location;

//   const RidePointEntity({required this.placeName, required this.location});
// }

// class RideUserEntity {
//   final String? id;
//   final String? name;
//   final String? phone;
//   final double? rating;
//   final String? profileImage;

//   const RideUserEntity({
//     this.id,
//     this.name,
//     this.phone,
//     this.rating,
//     this.profileImage,
//   });
// }

// class RideVehicleEntity {
//   final String? name;
//   final String? model;
//   final String? numberPlate;
//   final String? image;

//   const RideVehicleEntity({
//     this.name,
//     this.model,
//     this.numberPlate,
//     this.image,
//   });
// }

// class RideEntity {
//   final String id;
//   final String? userId;
//   final String? driverId;
//   final RideUserEntity? user;
//   final RideUserEntity? driver;
//   final RideVehicleEntity? vehicle;
//   final String rideStatus;
//   final String rideType;
//   final String specialRequest;
//   final double rideDistance;
//   final String paymentMethod;
//   final double rideFare;
//   final int averageTime;
//   final String paymentStatus;
//   final DateTime? createdAt;
//   final DateTime? updatedAt;
//   final RidePointEntity? pickupPoint;
//   final RidePointEntity? dropOffPointRequested;
//   final String? otp;

//   const RideEntity({
//     required this.id,
//     this.userId,
//     this.driverId,
//     this.user,
//     this.driver,
//     this.vehicle,
//     this.specialRequest = '',
//     required this.rideStatus,
//     required this.rideType,
//     required this.rideDistance,
//     required this.paymentMethod,
//     required this.rideFare,
//     required this.averageTime,
//     required this.paymentStatus,
//     this.createdAt,
//     this.updatedAt,
//     this.pickupPoint,
//     this.dropOffPointRequested,
//     this.otp,
//   });
// }

import '../../../reviews/domain/entities/pagination_entity.dart';

class GeoLocationEntity {
  final double longitude;
  final double latitude;

  const GeoLocationEntity({required this.longitude, required this.latitude});
}

class RidePointEntity {
  final String placeName;
  final GeoLocationEntity location;

  const RidePointEntity({required this.placeName, required this.location});
}

class RideUserEntity {
  final String firstName;
  final String lastName;
  final String phone;
  final double rating;
  final String id;
  final String profilePicture;

  const RideUserEntity({
    this.id = '',
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.rating = 0.0,
    this.profilePicture = '',
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

class RideVehicleEntity {
  final String? name;
  final String? model;
  final String? numberPlate;
  final String? image;
  

  const RideVehicleEntity({
    this.name,
    this.model,
    this.numberPlate,
    this.image,
  });
}

class RideEntity {
  final String id;
  final String? userId;
  final String? driverId;
  final RideUserEntity? user;
  final RideUserEntity? driver;
  final RideVehicleEntity? vehicle;
  final String rideStatus;
  final String rideType;
  final String specialRequest;
  final double rideDistance;
  final String paymentMethod;
  final double rideFare;
  final int averageTime;
  final String paymentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RidePointEntity? pickupPoint;
  final RidePointEntity? dropOffPointRequested;
  final String? otp;

  const RideEntity({
    required this.id,
    this.userId,
    this.driverId,
    this.user,
    this.driver,
    this.vehicle,
    this.specialRequest = '',
    required this.rideStatus,
    required this.rideType,
    required this.rideDistance,
    required this.paymentMethod,
    required this.rideFare,
    required this.averageTime,
    required this.paymentStatus,
    this.createdAt,
    this.updatedAt,
    this.pickupPoint,
    this.dropOffPointRequested,
    this.otp,
  });
}

class RideRequsetUserEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profilePicture;

  final num rating;

  const RideRequsetUserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profilePicture,
    required this.rating,
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

class RideRequestResponseEntity {
  final List<RideEntity> rides;
  final PaginationEntity pagination;

  RideRequestResponseEntity({required this.rides, required this.pagination});
}
