import 'package:ride_app/features/ride_room/domain/entities/carpool_booking_status_entity.dart';

class CarpoolBookingStatusModel extends CarpoolBookingStatusEntity {
  const CarpoolBookingStatusModel({
    required super.bookingId,
    required super.status,
    required super.otp,
    required super.reason,
  });

  factory CarpoolBookingStatusModel.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> payload = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : json);

    return CarpoolBookingStatusModel(
      bookingId: payload['bookingId']?.toString() ?? '',
      status: payload['status']?.toString() ?? '',
      otp: payload['otp']?.toString() ?? '',
      reason: payload['reason']?.toString() ?? '',
    );
  }
}
