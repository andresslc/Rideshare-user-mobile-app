  class RideHistoryResponseEntity {
    final List<RideEntity> rides;
    final PaginationEntity pagination;

    RideHistoryResponseEntity({required this.rides, required this.pagination});
  }

  class RideEntity {
    final String id;
    final String rideStatus;
    final String rideType;
    final double rideDistance;
    final double rideFare;
    final int averageTime;
    final String paymentMethod;
    final String paymentStatus;
    final DateTime createdAt;
    final String? cancelledBy;
    final String? cancellationReason;
    final String? specialRequest;
    final DateTime? startTime;
    final DateTime? endTime;
    final DateTime? updatedAt;
    final UserEntity user;
    final DriverEntity driver;

    final LocationPointEntity pickupPoint;
    final LocationPointEntity dropOffPoint;

    const RideEntity({
      required this.id,
      required this.cancelledBy,
      required this.cancellationReason,
      required this.specialRequest,
      required this.startTime,
      required this.endTime,
      required this.updatedAt,
      required this.rideStatus,
      required this.rideType,
      required this.rideDistance,
      required this.rideFare,
      required this.averageTime,
      required this.paymentMethod,
      required this.paymentStatus,
      required this.createdAt,
      required this.user,
      required this.driver,
      required this.pickupPoint,
      required this.dropOffPoint,
    });
  }

  class UserEntity {
    final String id;
    final String firstName;
    final String lastName;
    final String email;
    final String profilePicture;
    final double rating;
    final DateTime? dob;

    const UserEntity({
      required this.id,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.profilePicture,
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

  class DriverEntity {
    final String id;
    final String firstName;
    final String lastName;
    final String email;
    final String profilePicture;
    final double rating;
    final VehicleDetailsEntity? vehicle; // 👈 add this
    final DateTime? dob;

    const DriverEntity({
      required this.id,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.profilePicture,
      required this.rating,
      required this.vehicle,
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

  class LocationPointEntity {
    final String placeName;
    final double latitude;
    final double longitude;

    const LocationPointEntity({
      required this.placeName,
      required this.latitude,
      required this.longitude,
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

  class VehicleDetailsEntity {
    final String id;
    final String make;
    final String model;
    final int yearOfManufacture;
    final String color;
    final String licensePlateNumber;
    final String vehicleType;

    const VehicleDetailsEntity({
      required this.id,
      required this.make,
      required this.model,
      required this.yearOfManufacture,
      required this.color,
      required this.licensePlateNumber,
      required this.vehicleType,
    });
  }
