import 'package:ride_app/features/ride_room/data/models/ride_model.dart';
import 'package:ride_app/features/ride_room/data/models/ride_search_status_model.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_response_entity.dart';

class RideResponseModel extends RideResponseEntity {
  const RideResponseModel({
    super.type,
    super.message,
    super.ride,
    super.rideOtp,
    super.rideId,
    super.searchStatus,
  });

  factory RideResponseModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rideMap =
        _asMap(json['ride']) ?? <String, dynamic>{};
    final String? resolvedRideId =
        json['rideId']?.toString() ??
        rideMap['id']?.toString() ??
        rideMap['_id']?.toString();

    // The request ack reports the first dispatch ring under `search`, so the
    // rider sees the search already in progress instead of a bare spinner.
    final Map<String, dynamic>? searchMap = _asMap(json['search']);

    return RideResponseModel(
      rideId: resolvedRideId,
      type: json['type']?.toString(),
      message: json['message']?.toString(),
      ride: rideMap.isNotEmpty ? RideModel.fromJson(rideMap) : null,
      rideOtp: json['rideOTP']?.toString() ?? json['rideOtp']?.toString(),
      searchStatus: searchMap == null
          ? null
          : RideSearchStatusModel.fromJson(<String, dynamic>{
              'rideId': resolvedRideId,
              ...searchMap,
            }),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'message': message,
      'ride': (ride as RideModel).toJson(),
      'rideOTP': rideOtp,
      'rideId': rideId,
    };
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
