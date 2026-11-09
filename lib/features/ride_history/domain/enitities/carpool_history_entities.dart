class CarpoolHistoryEntity {
  final List<CarpoolRideEntity> rides;
  final PaginationEntity pagination;

  CarpoolHistoryEntity({required this.rides, required this.pagination});
}

class CarpoolRideEntity {
  final String id;
  final CarpoolDriverEntity driver;
  final CarpoolPointEntity startingPoint;
  final CarpoolPointEntity destination;
  final List<CarpoolRouteEntity> routes;
  final String status;
  final int requiredSeats;

  final int maxPassengers;
  final int availableSeats;
  final DateTime? graceTime;
  final DateTime createdAt;
  final double avgTime; // added
  final double distance;
  final num fareCharged;
  CarpoolRideEntity({
    required this.id,
    required this.driver,
    this.requiredSeats = 1,
    required this.startingPoint,
    required this.destination,
    required this.routes,
    required this.status,
    required this.maxPassengers,
    required this.availableSeats,
    this.graceTime,
    this.fareCharged = 0,
    required this.avgTime,
    required this.distance,
    required this.createdAt,
  });
}

class CarpoolDriverEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profilePicture;
  final VehicleDetailsEntity vehicleDetails;
  final double rating;

  CarpoolDriverEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profilePicture,
    required this.vehicleDetails,
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

class VehicleDetailsEntity {
  final String id;
  final String make;
  final String model;
  final int yearOfManufacture;
  final String? color;
  final String licensePlateNumber;
  final String vehicleType;

  VehicleDetailsEntity({
    required this.id,
    required this.make,
    required this.model,
    required this.yearOfManufacture,
    this.color,
    required this.licensePlateNumber,
    required this.vehicleType,
  });
}

class CarpoolPointEntity {
  final String placeName;
  final LocationEntity location;

  CarpoolPointEntity({required this.placeName, required this.location});
}

class LocationEntity {
  final String type;
  final List<double> coordinates;

  LocationEntity({required this.type, required this.coordinates});
}

class CarpoolRouteEntity {
  final String id;
  final String placeName;
  final LocationEntity location;
  final String status;
  final int order;

  CarpoolRouteEntity({
    required this.id,
    required this.placeName,
    required this.location,
    required this.status,
    required this.order,
  });
}

class PaginationEntity {
  final int page;
  final int currentPage;
  final int total;
  final int totalPages;

  PaginationEntity({
    required this.page,
    required this.currentPage,
    required this.total,
    required this.totalPages,
  });
}
