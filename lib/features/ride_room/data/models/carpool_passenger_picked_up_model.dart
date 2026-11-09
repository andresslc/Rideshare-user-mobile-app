import 'package:ride_app/features/ride_room/domain/entities/carpool_passenger_picked_up_entity.dart';

class CarpoolPassengerPickedUpModel extends CarpoolPassengerPickedUpEntity {
  const CarpoolPassengerPickedUpModel({
    required super.bookingId,
    required super.carpoolId,
    required super.passengerId,
    required super.pickedUpAt,
    required super.otpVerified,
  });

  factory CarpoolPassengerPickedUpModel.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> payload = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : json);

    return CarpoolPassengerPickedUpModel(
      bookingId: payload['bookingId']?.toString() ?? '',
      carpoolId: payload['carpoolId']?.toString() ?? '',
      passengerId: payload['passengerId']?.toString() ?? '',
      pickedUpAt: DateTime.tryParse(payload['pickedUpAt']?.toString() ?? ''),
      otpVerified:
          payload['otpVerified'] == true ||
          payload['otpVerified '] == true ||
          payload['otpVerified']?.toString().trim().toLowerCase() == 'true' ||
          payload['otpVerified ']?.toString().trim().toLowerCase() == 'true',
    );
  }
}
