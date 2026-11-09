import 'package:ride_app/features/ride_room/domain/entities/carpool_resume_entity.dart';

Map<String, dynamic>? _resumeAsMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class CarpoolResumeModel extends CarpoolResumeEntity {
  const CarpoolResumeModel({
    required super.message,
    required super.role,
    required super.type,
    required super.carpoolId,
    required super.bookingId,
    required super.otpVerified,
  });

  factory CarpoolResumeModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = _resumeAsMap(json['data']) ?? json;
    final Map<String, dynamic>? booking = _resumeAsMap(data['booking']);

    return CarpoolResumeModel(
      message: json['message']?.toString() ?? data['message']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      carpoolId: data['carpoolId']?.toString() ?? '',
      bookingId:
          data['bookingId']?.toString() ??
          booking?['bookingId']?.toString() ??
          booking?['_id']?.toString() ??
          booking?['id']?.toString() ??
          '',
      otpVerified: data['otpVerified'] == true,
    );
  }
}
