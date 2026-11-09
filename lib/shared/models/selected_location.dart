import '../../core/services/places_search_service.dart';

class Address {
  final ResolvedPlace? resolvedPlace;
  final double latitiude;
  final double longitude;
  final String country;
  final String state;
  final String city;
  final String zipCode;
  final String countryCode;
  final String formattedAddress;

  Address({
    this.resolvedPlace,
    required this.latitiude,
    required this.longitude,
    required this.country,
    required this.state,
    required this.city,
    required this.zipCode,
    required this.countryCode,
    required this.formattedAddress,
  });

  factory Address.fromResolvedPlace(ResolvedPlace place) => Address(
    resolvedPlace: place,
    latitiude: place.latitude,
    longitude: place.longitude,
    country: place.country,
    state: place.state,
    city: place.city,
    zipCode: place.postalCode,
    countryCode: place.countryCode,
    formattedAddress: place.formattedAddress,
  );

  factory Address.idle() {
    return Address(
      latitiude: 0,
      longitude: 0,
      country: '',
      state: '',
      city: '',
      zipCode: '',
      countryCode: '',
      formattedAddress: '',
    );
  }

  factory Address.fromLocationEntity(dynamic location) {
    final String addressStr = location.address as String? ?? '';
    final String nameStr = location.name as String? ?? '';
    final double lat = (location.latitude as num?)?.toDouble() ?? 0.0;
    final double lng = (location.longitude as num?)?.toDouble() ?? 0.0;

    final parts = addressStr
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final country = parts.isNotEmpty ? parts.last : '';
    final state = parts.length > 1 ? parts[parts.length - 2] : '';
    final city = parts.length > 2 ? parts[parts.length - 3] : nameStr;

    return Address(
      latitiude: lat,
      longitude: lng,
      country: country,
      state: state,
      city: city,
      zipCode: '',
      countryCode: country.length >= 2
          ? country.substring(0, 2).toUpperCase()
          : '',
      formattedAddress: addressStr,
    );
  }

  Address copyWith({
    double? latitiude,
    double? longitude,
    String? streetAddress,
    String? country,
    String? state,
    String? city,
    String? zipCode,
    String? countryCode,
    String? formattedAddress,
  }) {
    return Address(
      resolvedPlace: resolvedPlace,
      latitiude: latitiude ?? this.latitiude,
      longitude: longitude ?? this.longitude,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      countryCode: countryCode ?? this.countryCode,
      formattedAddress: formattedAddress ?? this.formattedAddress,
    );
  }
}
