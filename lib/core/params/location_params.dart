class SaveLocationParams {
  final String name;
  final String address;
  final String country;
  final String city;
  final String state;
  final double lat;
  final double lng;

  const SaveLocationParams({
    required this.name,
    required this.address,
    required this.country,
    required this.city,
    required this.state,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'address': address,
      'country': country,
      'city': city,
      'state': state,
      'coordinates': <String, dynamic>{'lat': lat, 'lng': lng},
    };
  }
}
