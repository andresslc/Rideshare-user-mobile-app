import '../../../core/services/places_search_service.dart';

class AddressDetails {
  final bool isResolvedFromPlaces;
  final String street;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;
  final String zipCode;

  AddressDetails({
    this.isResolvedFromPlaces = false,
    this.street = '',
    this.formattedAddress = '',
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
  });

  factory AddressDetails.fromResolvedPlace(ResolvedPlace place) =>
      AddressDetails(
        isResolvedFromPlaces: true,
        latitude: place.latitude,
        longitude: place.longitude,
        city: place.city,
        state: place.state,
        country: place.country,
        zipCode: place.postalCode,
        street: place.street,
        formattedAddress: place.formattedAddress,
      );

  factory AddressDetails.fromMap(Map<String, dynamic> map) {
    return AddressDetails(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      zipCode: map['zipCode'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
    };
  }

  @override
  String toString() =>
      'AddressDetails(city: $city, state: $state, country: $country, zipCode: $zipCode, lat: $latitude, lng: $longitude)';
}
