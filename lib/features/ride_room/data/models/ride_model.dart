import 'package:ride_app/features/ride_room/domain/entities/ride_entity.dart';

import '../../../reviews/data/models/pagination_model.dart';

// class GeoLocationModel extends GeoLocationEntity {
//   const GeoLocationModel({required super.longitude, required super.latitude});

//   factory GeoLocationModel.fromJson(Map<String, dynamic> json) {
//     final rawCoords = json['coordinates'];
//     final coords = rawCoords is List ? rawCoords : const <dynamic>[0.0, 0.0];
//     final longitude = coords.isNotEmpty
//         ? (coords[0] as num?)?.toDouble() ?? 0.0
//         : 0.0;
//     final latitude = coords.length > 1
//         ? (coords[1] as num?)?.toDouble() ?? 0.0
//         : 0.0;

//     return GeoLocationModel(longitude: longitude, latitude: latitude);
//   }

//   Map<String, dynamic> toJson() => {
//     "type": "Point",
//     "coordinates": [longitude, latitude],
//   };
// }

// class RidePointModel extends RidePointEntity {
//   const RidePointModel({required super.placeName, required super.location});

//   factory RidePointModel.fromJson(Map<String, dynamic> json) {
//     final rawLocation = json['location'];
//     final locationMap = rawLocation is Map<String, dynamic>
//         ? rawLocation
//         : (rawLocation is Map ? Map<String, dynamic>.from(rawLocation) : null);
//     return RidePointModel(
//       placeName: json['placeName']?.toString() ?? '',
//       location: locationMap != null
//           ? GeoLocationModel.fromJson(locationMap)
//           : const GeoLocationModel(longitude: 0.0, latitude: 0.0),
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     "placeName": placeName,
//     "location": (location as GeoLocationModel).toJson(),
//   };
// }

// class RideUserModel extends RideUserEntity {
//   const RideUserModel({
//     super.id,
//     super.name,
//     super.phone,
//     super.rating,
//     super.profileImage,
//   });

//   factory RideUserModel.fromJson(Map<String, dynamic> json) {
//     return RideUserModel(
//       id: json['_id']?.toString() ?? json['id']?.toString(),
//       name: json['name']?.toString(),
//       phone: json['phone']?.toString() ?? json['phoneNumber']?.toString(),
//       rating: (json['rating'] as num?)?.toDouble(),
//       profileImage:
//           json['profileImage']?.toString() ??
//           json['profilePicture']?.toString() ??
//           json['image']?.toString(),
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     "_id": id,
//     "name": name,
//     "phone": phone,
//     "rating": rating,
//     "profileImage": profileImage,
//   };
// }

// class RideVehicleModel extends RideVehicleEntity {
//   const RideVehicleModel({
//     super.name,
//     super.model,
//     super.numberPlate,
//     super.image,
//   });

//   factory RideVehicleModel.fromJson(Map<String, dynamic> json) {
//     return RideVehicleModel(
//       name:
//           json['name']?.toString() ??
//           json['carName']?.toString() ??
//           json['make']?.toString(),
//       model: json['model']?.toString(),
//       numberPlate:
//           json['numberPlate']?.toString() ??
//           json['plateNumber']?.toString() ??
//           json['licensePlateNumber']?.toString(),
//       image: json['image']?.toString(),
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     "name": name,
//     "model": model,
//     "numberPlate": numberPlate,
//     "image": image,
//   };
// }

// class RideModel extends RideEntity {
//   const RideModel({
//     required super.id,
//     super.userId,
//     super.driverId,
//     super.user,
//     super.driver,
//     super.vehicle,
//     super.specialRequest,
//     required super.rideStatus,
//     required super.rideType,
//     required super.rideDistance,
//     required super.paymentMethod,
//     required super.rideFare,
//     required super.averageTime,
//     required super.paymentStatus,
//     super.createdAt,
//     super.updatedAt,
//     super.pickupPoint,
//     super.dropOffPointRequested,
//     super.otp,
//   });

//   factory RideModel.fromJson(Map<String, dynamic> json) {
//     final rawRide = json['ride'];
//     final ride = rawRide is Map<String, dynamic> ? rawRide : json;

//     return RideModel(
//       id:
//           ride['_id']?.toString() ??
//           ride['id']?.toString() ??
//           ride['rideId']?.toString() ??
//           '',
//       userId: _valueOrNestedId(ride['user']),
//       driverId: _valueOrNestedId(ride['driver']),
//       user: _parseUser(ride['user']),
//       driver: _parseUser(ride['driver']),
//       vehicle: _parseVehicle(
//         ride['vehicle'] ??
//             ride['car'] ??
//             _asMap(ride['driver'])?['vehicle'] ??
//             _asMap(ride['driver'])?['vehicleDetails'],
//       ),
//       specialRequest: ride['specialRequest']?.toString() ?? '',
//       rideStatus: ride['rideStatus']?.toString() ?? ride['status']?.toString() ?? '',
//       rideType: ride['rideType']?.toString() ?? '',
//       rideDistance:
//           (ride['rideDistance'] as num?)?.toDouble() ??
//           (ride['distance'] as num?)?.toDouble() ??
//           0.0,
//       paymentMethod: ride['paymentMethod']?.toString() ?? '',
//       rideFare:
//           (ride['rideFare'] as num?)?.toDouble() ??
//           (ride['fare'] as num?)?.toDouble() ??
//           0.0,
//       averageTime:
//           (ride['averageTime'] as num?)?.toInt() ??
//           (ride['duration'] as num?)?.toInt() ??
//           0,
//       paymentStatus: ride['paymentStatus']?.toString() ?? '',
//       createdAt: _parseDateTime(ride['createdAt']),
//       updatedAt: _parseDateTime(ride['updatedAt']),
//       pickupPoint: _parseRidePoint(ride['pickupPoint']),
//       dropOffPointRequested: _parseRidePoint(
//         ride['dropOffPointRequested'] ??
//             ride['dropoffPointRequested'] ??
//             ride['dropOffPoint'],
//       ),
//       otp:
//           ride['otp']?.toString() ??
//           _asMap(ride['rideOtp'])?['otp']?.toString() ??
//           ride['rideOtp']?.toString(),
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     "_id": id,
//     "user": userId,
//     "driver": driverId,
//     "userDetails": user is RideUserModel
//         ? (user as RideUserModel).toJson()
//         : null,
//     "driverDetails": driver is RideUserModel
//         ? (driver as RideUserModel).toJson()
//         : null,
//     "vehicle": vehicle is RideVehicleModel
//         ? (vehicle as RideVehicleModel).toJson()
//         : null,
//     "rideStatus": rideStatus,
//     "rideType": rideType,
//     "rideDistance": rideDistance,
//     "paymentMethod": paymentMethod,
//     "rideFare": rideFare,
//     "averageTime": averageTime,
//     "paymentStatus": paymentStatus,
//     "createdAt": createdAt?.toIso8601String(),
//     "updatedAt": updatedAt?.toIso8601String(),
//     "pickupPoint": pickupPoint is RidePointModel
//         ? (pickupPoint as RidePointModel).toJson()
//         : null,
//     "dropOffPointRequested": dropOffPointRequested is RidePointModel
//         ? (dropOffPointRequested as RidePointModel).toJson()
//         : null,
//   };

//   static DateTime? _parseDateTime(dynamic value) {
//     final text = value?.toString();
//     if (text == null || text.isEmpty) return null;
//     return DateTime.tryParse(text);
//   }

//   static RidePointModel? _parseRidePoint(dynamic value) {
//     final map = _asMap(value);
//     if (map != null) return RidePointModel.fromJson(map);
//     return null;
//   }

//   static String? _valueOrNestedId(dynamic value) {
//     if (value == null) return null;
//     if (value is String) return value;
//     if (value is Map<String, dynamic>) {
//       return value['_id']?.toString() ?? value['id']?.toString();
//     }
//     return value.toString();
//   }

//   static RideUserModel? _parseUser(dynamic value) {
//     final map = _asMap(value);
//     if (map != null) return RideUserModel.fromJson(map);
//     return null;
//   }

//   static RideVehicleModel? _parseVehicle(dynamic value) {
//     final map = _asMap(value);
//     if (map != null) return RideVehicleModel.fromJson(map);
//     return null;
//   }

//   static Map<String, dynamic>? _asMap(dynamic value) {
//     if (value is Map<String, dynamic>) return value;
//     if (value is Map) return Map<String, dynamic>.from(value);
//     return null;
//   }
// }

class GeoLocationModel extends GeoLocationEntity {
  const GeoLocationModel({required super.longitude, required super.latitude});

  factory GeoLocationModel.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'];
    final coords = rawCoords is List ? rawCoords : const <dynamic>[0.0, 0.0];
    final longitude = coords.isNotEmpty
        ? (coords[0] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final latitude = coords.length > 1
        ? (coords[1] as num?)?.toDouble() ?? 0.0
        : 0.0;

    return GeoLocationModel(longitude: longitude, latitude: latitude);
  }

  Map<String, dynamic> toJson() => {
    "type": "Point",
    "coordinates": [longitude, latitude],
  };
}

class RidePointModel extends RidePointEntity {
  const RidePointModel({required super.placeName, required super.location});

  factory RidePointModel.fromJson(Map<String, dynamic> json) {
    final rawLocation = json['location'];
    final locationMap = rawLocation is Map<String, dynamic>
        ? rawLocation
        : (rawLocation is Map ? Map<String, dynamic>.from(rawLocation) : null);
    return RidePointModel(
      placeName: json['placeName']?.toString() ?? '',
      location: locationMap != null
          ? GeoLocationModel.fromJson(locationMap)
          : const GeoLocationModel(longitude: 0.0, latitude: 0.0),
    );
  }

  Map<String, dynamic> toJson() => {
    "placeName": placeName,
    "location": (location as GeoLocationModel).toJson(),
  };
}

class RideUserModel extends RideUserEntity {
  const RideUserModel({
    super.id,
    super.firstName,
    super.lastName,
    super.phone,
    super.rating,
    super.profilePicture,
  });

  factory RideUserModel.fromJson(Map<String, dynamic> json) {
    final String? rawPhone =
        json['phone']?.toString() ?? json['phoneNumber']?.toString();
    final String? rawProfile =
        json['profileImage']?.toString() ??
        json['profilePicture']?.toString() ??
        json['image']?.toString();

    return RideUserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: rawPhone == null || rawPhone == 'null' ? '' : rawPhone,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      profilePicture: rawProfile == null || rawProfile == 'null'
          ? ''
          : rawProfile,
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "firstName": firstName,
    "lastName": lastName.trim(),
    "phone": phone,
    "rating": rating,
    "profileImage": profilePicture,
  };
}

class RideVehicleModel extends RideVehicleEntity {
  const RideVehicleModel({
    super.name,
    super.model,
    super.numberPlate,
    super.image,
  });

  factory RideVehicleModel.fromJson(Map<String, dynamic> json) {
    return RideVehicleModel(
      name:
          json['name']?.toString() ??
          json['carName']?.toString() ??
          json['make']?.toString(),
      model: json['model']?.toString(),
      numberPlate:
          json['plate']?.toString() ??
          json['numberPlate']?.toString() ??
          json['plateNumber']?.toString() ??
          json['licensePlateNumber']?.toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "model": model,
    "numberPlate": numberPlate,
    "image": image,
  };
}

class RideModel extends RideEntity {
  const RideModel({
    required super.id,
    super.userId,
    super.driverId,
    super.user,
    super.driver,
    super.vehicle,
    super.specialRequest,
    required super.rideStatus,
    required super.rideType,
    required super.rideDistance,
    required super.paymentMethod,
    required super.rideFare,
    required super.averageTime,
    required super.paymentStatus,
    super.createdAt,
    super.updatedAt,
    super.pickupPoint,
    super.dropOffPointRequested,
    super.otp,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    // final Map<String, dynamic> root = Map<String, dynamic>.from(json);
    final rawRide = json['ride'];
    final ride = rawRide is Map<String, dynamic> ? rawRide : json;

    return RideModel(
      id: ride['id']?.toString() ?? '',
      userId: _valueOrNestedId(ride['user']),
      driverId: _valueOrNestedId(ride['driver']),
      user: _parseUser(ride['user']),
      driver: _parseUser(ride['driver']),
      vehicle: _parseVehicle(_asMap(ride['driver'])?['vehicle']),
      specialRequest: ride['specialRequest']?.toString() ?? '',
      rideStatus: ride['status']?.toString() ?? '',
      rideType: ride['rideType']?.toString() ?? '',
      rideDistance: (ride['distance'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: ride['paymentMethod']?.toString() ?? '',
      rideFare: (ride['fare'] as num?)?.toDouble() ?? 0.0,
      averageTime: (ride['duration'] as num?)?.toInt() ?? 0,
      paymentStatus: ride['paymentStatus']?.toString() ?? '',
      createdAt: _parseDateTime(ride['createdAt']),
      updatedAt: _parseDateTime(ride['updatedAt']),
      pickupPoint: _parseRidePoint(ride['pickupPoint']),
      dropOffPointRequested: _parseRidePoint(ride['dropOffPoint']),
      otp: ride['rideOtp']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "user": userId,
    "driver": driverId,
    "userDetails": user is RideUserModel
        ? (user as RideUserModel).toJson()
        : null,
    "driverDetails": driver is RideUserModel
        ? (driver as RideUserModel).toJson()
        : null,
    "vehicle": vehicle is RideVehicleModel
        ? (vehicle as RideVehicleModel).toJson()
        : null,
    "rideStatus": rideStatus,
    "rideType": rideType,
    "rideDistance": rideDistance,
    "paymentMethod": paymentMethod,
    "rideFare": rideFare,
    "averageTime": averageTime,
    "paymentStatus": paymentStatus,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "pickupPoint": pickupPoint is RidePointModel
        ? (pickupPoint as RidePointModel).toJson()
        : null,
    "dropOffPointRequested": dropOffPointRequested is RidePointModel
        ? (dropOffPointRequested as RidePointModel).toJson()
        : null,
  };

  static DateTime? _parseDateTime(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static RidePointModel? _parseRidePoint(dynamic value) {
    final map = _asMap(value);
    if (map != null) return RidePointModel.fromJson(map);
    return null;
  }

  static String? _valueOrNestedId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['_id']?.toString() ?? value['id']?.toString();
    }
    return value.toString();
  }

  static RideUserModel? _parseUser(dynamic value) {
    final map = _asMap(value);
    if (map != null) return RideUserModel.fromJson(map);
    return null;
  }

  static RideVehicleModel? _parseVehicle(dynamic value) {
    final map = _asMap(value);
    if (map != null) return RideVehicleModel.fromJson(map);
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

class RideRequestResponseModel extends RideRequestResponseEntity {
  RideRequestResponseModel({required super.rides, required super.pagination});

  factory RideRequestResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final pagination = json['pagination'] ?? {};

    List<RideModel> parsedRides = [];

    if (data is List) {
      parsedRides = data
          .whereType<Map<String, dynamic>>()
          .map((e) => RideModel.fromJson(e))
          .toList();
    } else if (data is Map<String, dynamic>) {
      parsedRides = [RideModel.fromJson(data)];
    }

    return RideRequestResponseModel(
      rides: parsedRides,
      pagination: PaginationModel.fromJson(pagination),
    );
  }

  RideRequestResponseEntity toEntity() =>
      RideRequestResponseEntity(rides: rides, pagination: pagination);
}
