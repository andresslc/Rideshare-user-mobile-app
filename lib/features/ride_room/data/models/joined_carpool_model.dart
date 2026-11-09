import 'package:ride_app/features/ride_room/domain/entities/joined_carpool_entity.dart';

class JoinedCarpoolModel extends JoinedCarpoolEntity {
  const JoinedCarpoolModel({
    required super.bookingId,
    required super.message,
  });

  factory JoinedCarpoolModel.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> payload = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});

    return JoinedCarpoolModel(
      bookingId: payload['bookingId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}
