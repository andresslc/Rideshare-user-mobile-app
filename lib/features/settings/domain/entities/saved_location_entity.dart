class SavedLocationEntity {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String country;
  final double lat;
  final double lng;
  final int order;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SavedLocationEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.lat,
    required this.lng,
    required this.order,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  String get formattedAddress {
    if (address.trim().isNotEmpty) return address;
    final parts = <String>[city, state, country]
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  SavedLocationEntity copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? state,
    String? country,
    double? lat,
    double? lng,
    int? order,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedLocationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      order: order ?? this.order,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
