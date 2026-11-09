import 'package:ride_app/features/ride_room/domain/entities/share_ride_entity.dart';

class ShareRideModel extends ShareRideEntity {
  const ShareRideModel({required super.url});

  factory ShareRideModel.fromResponse(Map<String, dynamic> json) {
    final data = json['data'];

    if (data is Map<String, dynamic>) {
      final url = data['url'];
      if (url is String && url.isNotEmpty) {
        return ShareRideModel(url: url);
      }
    }

    if (data is String && data.isNotEmpty) {
      return ShareRideModel(url: data);
    }

    throw const FormatException(' URL not found in response');
  }
}
