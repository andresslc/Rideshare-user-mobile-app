import 'package:ride_app/features/ride_room/domain/entities/ride_entity.dart';

class CarpoolRideStopEntity {
  final String id;
  final String placeName;
  final GeoLocationEntity location;
  final String status;
  final int order;

  /// The role of this stop in the route: "pickup", "stop", or "dropoff".
  final String type;

  const CarpoolRideStopEntity({
    required this.id,
    required this.placeName,
    required this.location,
    required this.status,
    required this.order,
    this.type = '',
  });

  CarpoolRideStopEntity copyWith({
    String? id,
    String? placeName,
    GeoLocationEntity? location,
    String? status,
    int? order,
    String? type,
  }) {
    return CarpoolRideStopEntity(
      id: id ?? this.id,
      placeName: placeName ?? this.placeName,
      location: location ?? this.location,
      status: status ?? this.status,
      order: order ?? this.order,
      type: type ?? this.type,
    );
  }
}

class CarpoolRideBookingEntity {
  final String passengerId;
  final String bookingId;
  final String otp;
  final double distance;
  final int avgTime;
  final int requiredSeats;
  final double fareCharged;

  const CarpoolRideBookingEntity({
    required this.passengerId,
    required this.bookingId,
    required this.otp,
    required this.distance,
    required this.requiredSeats,
    required this.avgTime,
    required this.fareCharged,
  });

  CarpoolRideBookingEntity copyWith({
    String? passengerId,
    String? bookingId,
    String? otp,
    double? distance,
    int? requiredSeats,
    int? avgTime,
    double? fareCharged,
  }) {
    return CarpoolRideBookingEntity(
      passengerId: passengerId ?? this.passengerId,
      bookingId: bookingId ?? this.bookingId,
      otp: otp ?? this.otp,
      distance: distance ?? this.distance,
      requiredSeats: requiredSeats ?? this.requiredSeats,
      avgTime: avgTime ?? this.avgTime,
      fareCharged: fareCharged ?? this.fareCharged,
    );
  }
}

class CarpoolRideEntity {
  final String id;
  final RideUserEntity? driver;
  final RideVehicleEntity? vehicle;
  final int availableSeats;
  final int maxPassengers;
  final DateTime? graceTime;
  final List<CarpoolRideBookingEntity> bookings;
  final List<CarpoolRideStopEntity> routes;
  final CarpoolRideStopEntity? resolvedPickupStop;
  final CarpoolRideStopEntity? resolvedDropOffStop;
  final String otp;
  final double distance;
  final int avgTime;
  final double pickupDistanceMeters;
  final double dropOffDistanceMeters;
  final double fare;
  final String paymentMethod;
  final double relevanceScore;
  final int requiredSeats;

  const CarpoolRideEntity({
    required this.id,
    this.driver,
    this.vehicle,
    required this.availableSeats,
    required this.maxPassengers,
    this.graceTime,
    this.bookings = const <CarpoolRideBookingEntity>[],
    required this.routes,
    this.resolvedPickupStop,
    this.resolvedDropOffStop,
    required this.otp,
    required this.distance,
    required this.avgTime,
    required this.pickupDistanceMeters,
    required this.dropOffDistanceMeters,
    required this.fare,
    required this.paymentMethod,
    required this.relevanceScore,
    required this.requiredSeats,
  });

  CarpoolRideEntity copyWith({
    String? id,
    RideUserEntity? driver,
    RideVehicleEntity? vehicle,
    int? availableSeats,
    int? maxPassengers,
    DateTime? graceTime,
    List<CarpoolRideBookingEntity>? bookings,
    List<CarpoolRideStopEntity>? routes,
    CarpoolRideStopEntity? resolvedPickupStop,
    CarpoolRideStopEntity? resolvedDropOffStop,
    String? otp,
    double? distance,
    int? avgTime,
    double? pickupDistanceMeters,
    double? dropOffDistanceMeters,
    double? fare,
    String? paymentMethod,
    double? relevanceScore,
    int? requiredSeats,
  }) {
    return CarpoolRideEntity(
      id: id ?? this.id,
      driver: driver ?? this.driver,
      vehicle: vehicle ?? this.vehicle,
      availableSeats: availableSeats ?? this.availableSeats,
      maxPassengers: maxPassengers ?? this.maxPassengers,
      graceTime: graceTime ?? this.graceTime,
      bookings: bookings ?? this.bookings,
      routes: routes ?? this.routes,
      resolvedPickupStop: resolvedPickupStop ?? this.resolvedPickupStop,
      resolvedDropOffStop: resolvedDropOffStop ?? this.resolvedDropOffStop,
      otp: otp ?? this.otp,
      distance: distance ?? this.distance,
      avgTime: avgTime ?? this.avgTime,
      pickupDistanceMeters: pickupDistanceMeters ?? this.pickupDistanceMeters,
      dropOffDistanceMeters:
          dropOffDistanceMeters ?? this.dropOffDistanceMeters,
      fare: fare ?? this.fare,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      requiredSeats: requiredSeats ?? this.requiredSeats,
    );
  }
}

class CarpoolRideResponseEntity {
  final String message;
  final List<CarpoolRideEntity> rides;

  const CarpoolRideResponseEntity({required this.message, required this.rides});

  CarpoolRideResponseEntity copyWith({
    String? message,
    List<CarpoolRideEntity>? rides,
  }) {
    return CarpoolRideResponseEntity(
      message: message ?? this.message,
      rides: rides ?? this.rides,
    );
  }
}
