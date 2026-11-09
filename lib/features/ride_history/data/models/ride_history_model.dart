import 'package:ride_app/core/utils/dob_json.dart';

import '../../domain/enitities/ride_history_entites.dart';

class RideHistoryResponseModel extends RideHistoryResponseEntity {
  RideHistoryResponseModel({required super.rides, required super.pagination});

  factory RideHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    return RideHistoryResponseModel(
      rides: (json['data'] as List).map((e) => RideModel.fromJson(e)).toList(),
      pagination: PaginationEntity(
        page: json['pagination']['page'],
        currentPage: json['pagination']['currentPage'],
        total: json['pagination']['total'],
        totalPages: json['pagination']['totalPages'],
      ),
    );
  }
}

class RideModel extends RideEntity {
  const RideModel({
    required super.id,
    required super.rideStatus,
    required super.rideType,
    required super.rideDistance,
    required super.rideFare,
    required super.averageTime,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.createdAt,
    required super.user,
    required super.driver,
    required super.pickupPoint,
    required super.dropOffPoint,
    super.cancelledBy,
    super.cancellationReason,
    super.specialRequest,
    super.startTime,
    super.endTime,
    super.updatedAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['_id'] ?? "",
      rideStatus: json['rideStatus'] ?? "",
      rideType: json['rideType'] ?? "",
      rideDistance: (json['rideDistance'] as num?)?.toDouble() ?? 0,
      rideFare: (json['rideFare'] as num?)?.toDouble() ?? 0,
      averageTime: json['averageTime'] ?? 0,
      paymentMethod: json['paymentMethod'] ?? "",
      paymentStatus: json['paymentStatus'] ?? "",
      createdAt: DateTime.parse(json['createdAt'] ?? ""),
      cancelledBy: json['cancelledBy'] ?? "",
      cancellationReason: json['cancellationReason'] ?? "",
      specialRequest: json['specialRequest'] ?? "",
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      user: UserModel.fromJson(json['user'] ?? {}),
      driver: DriverModel.fromJson(json['driver'] ?? {}),
      pickupPoint: LocationPointModel.fromJson(json['pickupPoint'] ?? ""),
      dropOffPoint: LocationPointModel.fromJson(
        json['dropOffPointRequested'] ?? "",
      ),
    );
  }
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.profilePicture,
    required super.rating,
    super.dob,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? "",
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0, // parse safely
      dob: parseDobFromJson(json['dob']),
    );
  }
}

class DriverModel extends DriverEntity {
  const DriverModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.profilePicture,
    required super.rating,
    super.vehicle, // new
    super.dob,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['_id'] ?? "",
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email'] ?? "",
      profilePicture: json['profilePicture'] ?? "",
      rating: (json['rating'] as num?)?.toDouble() ?? 0, // parse safely
      vehicle: json['vehicleDetails'] != null
          ? VehicleModel.fromJson(json['vehicleDetails'])
          : null,
      dob: parseDobFromJson(json['dob']),
    );
  }
}

class LocationPointModel extends LocationPointEntity {
  const LocationPointModel({
    required super.placeName,
    required super.latitude,
    required super.longitude,
  });

  factory LocationPointModel.fromJson(Map<String, dynamic> json) {
    final coordinates = json['location']?['coordinates'];

    return LocationPointModel(
      placeName: json['placeName'],
      latitude: (coordinates[0] as num).toDouble(),
      longitude: (coordinates[1] as num).toDouble(),
    );
  }
}

class VehicleModel extends VehicleDetailsEntity {
  const VehicleModel({
    required super.id,
    required super.make,
    required super.model,
    required super.color,
    required super.yearOfManufacture,
    required super.licensePlateNumber,
    required super.vehicleType,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['_id'] ?? "",
      make: json['make'] ?? "",
      model: json['model'] ?? "",
      color: json['color'] ?? "",
      yearOfManufacture: json['yearOfManufacture'] ?? "",
      licensePlateNumber: json['licensePlateNumber'] ?? "",
      vehicleType: json['vehicleType'] ?? "",
    );
  }
}
