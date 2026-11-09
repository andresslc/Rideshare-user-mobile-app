import 'package:ride_app/features/ride_room/data/models/ride_model.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_response_entity.dart';

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<dynamic> _asList(dynamic value) {
  if (value is List<dynamic>) return value;
  if (value is List) return List<dynamic>.from(value);
  return <dynamic>[];
}

DateTime? _parseDateTime(dynamic value) {
  final String text = value?.toString() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}

class CarpoolRideStopModel extends CarpoolRideStopEntity {
  const CarpoolRideStopModel({
    required super.id,
    required super.placeName,
    required super.location,
    required super.status,
    required super.order,
    super.type,
  });

  factory CarpoolRideStopModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? locationMap = _asMap(json['location']);

    return CarpoolRideStopModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      placeName: json['placeName']?.toString() ?? '',
      location: locationMap == null
          ? const GeoLocationModel(longitude: 0.0, latitude: 0.0)
          : GeoLocationModel.fromJson(locationMap),
      status: json['status']?.toString() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    '_id': id,
    'placeName': placeName,
    'location': (location as GeoLocationModel).toJson(),
    'status': status,
    'order': order,
    'type': type,
  };
}

class CarpoolRideBookingModel extends CarpoolRideBookingEntity {
  const CarpoolRideBookingModel({
    required super.passengerId,
    required super.bookingId,
    required super.otp,
    required super.distance,
    required super.requiredSeats,
    required super.avgTime,
    required super.fareCharged,
  });

  factory CarpoolRideBookingModel.fromJson(Map<String, dynamic> json) {
    return CarpoolRideBookingModel(
      passengerId: json['passenger']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? json['_id']?.toString() ?? '',
      otp: json['otp']?.toString() ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      requiredSeats: (json['requiredSeats'] as num?)?.toInt() ?? 0,
      avgTime: (json['avgTime'] as num?)?.toInt() ?? 0,
      fareCharged: (json['fareCharged'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'passenger': passengerId,
    'bookingId': bookingId,
    'otp': otp,
    'distance': distance,
    'requiredSeats': requiredSeats,
    'avgTime': avgTime,
    'fareCharged': fareCharged,
  };
}

class CarpoolRideModel extends CarpoolRideEntity {
  const CarpoolRideModel({
    required super.id,
    super.driver,
    super.vehicle,
    required super.availableSeats,
    required super.maxPassengers,
    super.graceTime,
    required super.bookings,
    required super.routes,
    super.resolvedPickupStop,
    super.resolvedDropOffStop,
    required super.otp,
    required super.distance,
    required super.avgTime,
    required super.requiredSeats,
    required super.pickupDistanceMeters,
    required super.dropOffDistanceMeters,
    required super.fare,
    required super.paymentMethod,
    required super.relevanceScore,
  });

  factory CarpoolRideModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? driverMap = _asMap(json['driver']);
    final Map<String, dynamic>? vehicleMap = _asMap(
      json['vehicle'] ?? driverMap?['vehicleDetails'] ?? driverMap?['vehicle'],
    );
    final List<CarpoolRideBookingModel> parsedBookings =
        _asList(json['bookings'])
            .map<CarpoolRideBookingModel>(
              (dynamic item) => CarpoolRideBookingModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
    final List<CarpoolRideStopModel> parsedRoutes = _asList(json['routes'])
        .map<CarpoolRideStopModel>(
          (dynamic item) =>
              CarpoolRideStopModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    final Map<String, dynamic>? pickupStopMap =
        _asMap(json['pickupPoint']) ?? _asMap(json['startingPoint']);
    final Map<String, dynamic>? dropOffStopMap =
        _asMap(json['dropOffPoint']) ?? _asMap(json['destination']);
    final CarpoolRideStopModel? resolvedPickupStop = pickupStopMap == null
        ? null
        : CarpoolRideStopModel.fromJson(pickupStopMap);
    final CarpoolRideStopModel? resolvedDropOffStop = dropOffStopMap == null
        ? null
        : CarpoolRideStopModel.fromJson(dropOffStopMap);
    // Exclude the pickup and dropoff stops by matching their IDs.
    // Everything else in the routes array is an intermediate stop.
    // final String pickupPlace = resolvedPickupStop?.placeName.trim() ?? '';
    // final String dropoffPlace = resolvedDropOffStop?.placeName.trim() ?? '';
    // final List<CarpoolRideStopModel> intermediateStops = parsedRoutes.where((
    //   CarpoolRideStopModel stop,
    // ) {
    //   final String stopPlace = stop.placeName.trim();
    //   if (stopPlace.isEmpty) return true; // no place name to match — keep it
    //   if (pickupPlace.isNotEmpty && stopPlace == pickupPlace) return false;
    //   if (dropoffPlace.isNotEmpty && stopPlace == dropoffPlace) return false;
    //   return true;
    // }).toList();

    final List<CarpoolRideStopModel> intermediateStops = parsedRoutes.sublist(
      1,
      parsedRoutes.length - 1,
    );

    return CarpoolRideModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      driver: driverMap == null ? null : RideUserModel.fromJson(driverMap),
      vehicle: vehicleMap == null
          ? null
          : RideVehicleModel.fromJson(vehicleMap),
      availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 0,
      maxPassengers: (json['maxPassengers'] as num?)?.toInt() ?? 0,
      graceTime: _parseDateTime(json['graceTime']),
      bookings: parsedBookings,
      routes: intermediateStops,
      resolvedPickupStop: parsedRoutes.isNotEmpty
          ? parsedRoutes.first
          : resolvedPickupStop,
      resolvedDropOffStop: parsedRoutes.isNotEmpty
          ? parsedRoutes.last
          : resolvedDropOffStop,
      otp: json['otp']?.toString() ?? '',
      distance:
          (json['distance'] as num?)?.toDouble() ??
          (json['rideDistance'] as num?)?.toDouble() ??
          0.0,
      avgTime:
          (json['avgTime'] as num?)?.toInt() ??
          (json['averageTime'] as num?)?.toInt() ??
          (json['duration'] as num?)?.toInt() ??
          0,
      pickupDistanceMeters:
          (json['pickupDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      dropOffDistanceMeters:
          (json['dropOffDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      fare:
          (json['fare'] as num?)?.toDouble() ??
          (json['fareCharged'] as num?)?.toDouble() ??
          0.0,
      requiredSeats: (json['requiredSeats'] as num?)?.toInt() ?? 0,
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    '_id': id,
    'driver': driver is RideUserModel
        ? (driver as RideUserModel).toJson()
        : null,
    'vehicle': vehicle is RideVehicleModel
        ? (vehicle as RideVehicleModel).toJson()
        : null,
    'availableSeats': availableSeats,
    'maxPassengers': maxPassengers,
    'graceTime': graceTime?.toIso8601String(),
    'bookings': bookings
        .map(
          (CarpoolRideBookingEntity booking) =>
              booking is CarpoolRideBookingModel
              ? booking.toJson()
              : <String, dynamic>{
                  'passenger': booking.passengerId,
                  'bookingId': booking.bookingId,
                  'otp': booking.otp,
                  'distance': booking.distance,
                  'avgTime': booking.avgTime,
                  'fareCharged': booking.fareCharged,
                },
        )
        .toList(),
    'routes': routes
        .map(
          (CarpoolRideStopEntity stop) => stop is CarpoolRideStopModel
              ? stop.toJson()
              : <String, dynamic>{
                  '_id': stop.id,
                  'placeName': stop.placeName,
                  'location': stop.location is GeoLocationModel
                      ? (stop.location as GeoLocationModel).toJson()
                      : <String, dynamic>{
                          'type': 'Point',
                          'coordinates': <double>[
                            stop.location.longitude,
                            stop.location.latitude,
                          ],
                        },
                  'status': stop.status,
                  'order': stop.order,
                },
        )
        .toList(),
    'resolvedPickupStop': resolvedPickupStop is CarpoolRideStopModel
        ? (resolvedPickupStop as CarpoolRideStopModel).toJson()
        : null,
    'resolvedDropOffStop': resolvedDropOffStop is CarpoolRideStopModel
        ? (resolvedDropOffStop as CarpoolRideStopModel).toJson()
        : null,
    'otp': otp,
    'distance': distance,
    'avgTime': avgTime,
    'pickupDistanceMeters': pickupDistanceMeters,
    'dropOffDistanceMeters': dropOffDistanceMeters,
    'fare': fare,
    'paymentMethod': paymentMethod,
    'relevanceScore': relevanceScore,
  };
}

class CarpoolRideResponseModel extends CarpoolRideResponseEntity {
  const CarpoolRideResponseModel({
    required super.message,
    required super.rides,
  });

  factory CarpoolRideResponseModel.fromJson(Map<String, dynamic> json) {
    final List<CarpoolRideModel> parsedRides = _extractRides(json)
        .map<CarpoolRideModel>(
          (Map<String, dynamic> rideJson) =>
              CarpoolRideModel.fromJson(rideJson),
        )
        .toList();

    return CarpoolRideResponseModel(
      message: json['message']?.toString() ?? '',
      rides: parsedRides,
    );
  }

  static List<Map<String, dynamic>> _extractRides(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final dynamic candidates = data is Map<String, dynamic>
        ? data['rides'] ?? data['routes'] ?? data['data'] ?? data
        : data ?? json['rides'] ?? json['routes'];

    if (candidates is List) {
      return candidates
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (Map item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    final Map<String, dynamic>? rideMap = _asMap(candidates) ?? _asMap(json);
    if (rideMap == null) return <Map<String, dynamic>>[];

    final bool looksLikeRide =
        rideMap.containsKey('_id') ||
        rideMap.containsKey('driver') ||
        rideMap.containsKey('routes');

    return looksLikeRide
        ? <Map<String, dynamic>>[rideMap]
        : <Map<String, dynamic>>[];
  }
}
