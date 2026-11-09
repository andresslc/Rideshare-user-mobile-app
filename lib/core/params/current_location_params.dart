class CurrentLocationParams {
  final String type;
  final double longitude;
  final double latitude;

  const CurrentLocationParams({
    this.type = 'Point',
    required this.longitude,
    required this.latitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'location': {
        'type': type,
        'coordinates': [longitude, latitude],
      },
    };
  }
}
