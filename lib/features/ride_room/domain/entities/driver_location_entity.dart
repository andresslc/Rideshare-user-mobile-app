class DriverLocationEntity {
  final String driver;
  final List<double> coordinates; // [lng, lat]
  final int timestamp;
  final String? eta;

  const DriverLocationEntity({
    required this.driver,
    required this.coordinates,
    required this.timestamp,
    this.eta,
  });

  double? get longitude => coordinates.isNotEmpty ? coordinates[0] : null;
  double? get latitude => coordinates.length > 1 ? coordinates[1] : null;
  bool get hasValidEta =>
      eta != null && eta!.trim().isNotEmpty && !eta!.trim().startsWith('0');

  /// Returns a copy of this entity, but falls back to [previous]'s ETA when
  /// the incoming ETA is null / empty / zero — preventing momentary driver GPS
  /// gaps from blanking the ETA pill the user is already seeing.
  DriverLocationEntity mergeEta(DriverLocationEntity? previous) {
    if (hasValidEta) return this; // incoming ETA is fine — use as-is
    final String? fallback = previous?.eta;
    if (fallback == null) return this; // no previous ETA to fall back to
    return DriverLocationEntity(
      driver: driver,
      coordinates: coordinates,
      timestamp: timestamp,
      eta: fallback,
    );
  }
}

