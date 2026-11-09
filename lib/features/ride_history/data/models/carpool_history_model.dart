import '../../domain/enitities/carpool_history_entities.dart';

class CarpoolHistoryResponseModel extends CarpoolHistoryEntity {
  CarpoolHistoryResponseModel({
    required super.rides,
    required super.pagination,
  });

  factory CarpoolHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    return CarpoolHistoryResponseModel(
      rides: (json['data'] as List<dynamic>? ?? [])
          .map((e) => CarpoolRideModel.fromJson(e))
          .toList(),

      pagination: PaginationModel.fromJson(json['pagination'] ?? {}),
    );
  }
}

class CarpoolRideModel extends CarpoolRideEntity {
  CarpoolRideModel({
    required super.id,
    required super.driver,
    required super.startingPoint,
    required super.destination,
    required super.routes,
    required super.status,
    required super.requiredSeats, // ✅ add

    required super.maxPassengers,
    required super.availableSeats,
    super.graceTime,
    required super.createdAt,
    required super.avgTime,
    required super.distance,
    required super.fareCharged,
  });

  factory CarpoolRideModel.fromJson(Map<String, dynamic> json) {
    return CarpoolRideModel(
      id: json['_id'] ?? '',
      driver: CarpoolDriverModel.fromJson(json['driver'] ?? {}),
      startingPoint: CarpoolPointModel.fromJson(json['startingPoint'] ?? {}),
      destination: CarpoolPointModel.fromJson(json['destination'] ?? {}),
      routes: (json['routes'] as List<dynamic>? ?? [])
          .map((e) => CarpoolRouteModel.fromJson(e))
          .toList(),
      status: json['status'] ?? json['rideStatus'] ?? '',
      requiredSeats: json['requiredSeats'] ?? 0, // ✅ add

      maxPassengers: json['maxPassengers'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      graceTime: json['graceTime'] != null
          ? DateTime.tryParse(json['graceTime'])
          : null,
      createdAt:
          DateTime.tryParse(
            json['createdAt'] ?? DateTime.now().toIso8601String(),
          ) ??
          DateTime.now(),
      avgTime: (json['avgTime'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      fareCharged: (json['fareCharged'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CarpoolDriverModel extends CarpoolDriverEntity {
  CarpoolDriverModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    super.profilePicture,
    required super.vehicleDetails,
    required super.rating,
  });

  factory CarpoolDriverModel.fromJson(Map<String, dynamic> json) {
    return CarpoolDriverModel(
      id: json['_id'] ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'],
      vehicleDetails: VehicleDetailsModel.fromJson(
        json['vehicleDetails'] ?? {},
      ),
      rating: (json['rating'] != null)
          ? double.tryParse(json['rating'].toString()) ?? 0
          : 0,
    );
  }
}

class VehicleDetailsModel extends VehicleDetailsEntity {
  VehicleDetailsModel({
    required super.id,
    required super.make,
    required super.model,
    required super.yearOfManufacture,
    super.color,
    required super.licensePlateNumber,
    required super.vehicleType,
  });

  factory VehicleDetailsModel.fromJson(Map<String, dynamic> json) {
    return VehicleDetailsModel(
      id: json['_id'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      yearOfManufacture: json['yearOfManufacture'] ?? 0,
      color: json['color'],
      licensePlateNumber: json['licensePlateNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
    );
  }
}

class CarpoolPointModel extends CarpoolPointEntity {
  CarpoolPointModel({required super.placeName, required super.location});

  factory CarpoolPointModel.fromJson(Map<String, dynamic> json) {
    return CarpoolPointModel(
      placeName: json['placeName'] ?? '',
      location: LocationModel.fromJson(json['location'] ?? {}),
    );
  }
}

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
}

class CarpoolRouteModel extends CarpoolRouteEntity {
  CarpoolRouteModel({
    required super.id,
    required super.placeName,
    required super.location,
    required super.status,
    required super.order,
  });

  factory CarpoolRouteModel.fromJson(Map<String, dynamic> json) {
    return CarpoolRouteModel(
      id: json['_id'] ?? '',
      placeName: json['placeName'] ?? '',
      location: LocationModel.fromJson(json['location'] ?? {}),
      status: json['status'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}

class PaginationModel extends PaginationEntity {
  PaginationModel({
    required super.page,
    required super.currentPage,
    required super.total,
    required super.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
