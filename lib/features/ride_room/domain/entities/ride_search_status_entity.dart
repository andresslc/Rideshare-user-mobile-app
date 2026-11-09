/// One step of the escalating driver search (`ride:search:status`).
///
/// The backend opens a ring, waits, then widens it. The ladder and its timings
/// are configured server-side and there is no endpoint to read them, so every
/// value shown to the rider comes from the event itself — never hardcode the
/// 1 → 2 → 3 → 5 mile default.
class RideSearchStatusEntity {
  final String? rideId;

  /// 1-based index of the ring currently open.
  final int ring;

  /// Total rings in the ladder. Absent on the ack of the ride request, which
  /// only reports the first ring.
  final int? totalRings;

  /// Radius of the current ring, in miles. Raw value; use [radius] to show it.
  final double radiusMiles;

  /// The same radius already converted to [distanceUnit] by the backend. The
  /// app prints this one and never converts anything itself.
  final double radius;

  /// `mi` or `km`, as the admin panel has it configured.
  final String distanceUnit;

  /// The whole sentence, resolved in the rider's language with the numbers
  /// already in place. Editable from the panel, so it wins over anything the
  /// app could compose on its own.
  final String? message;

  /// Drivers newly reached by this ring.
  final int driversNotified;

  /// Drivers reached so far across the whole request.
  final int totalNotified;

  /// Seconds until the next ring opens. Absent on the request ack.
  final int? nextRingInSeconds;

  const RideSearchStatusEntity({
    this.rideId,
    required this.ring,
    this.totalRings,
    required this.radiusMiles,
    required this.radius,
    this.distanceUnit = 'mi',
    this.message,
    required this.driversNotified,
    required this.totalNotified,
    this.nextRingInSeconds,
  });

  /// Progress through the ladder, 0..1. Falls back to an unknown-length ladder
  /// by reporting the ring itself as incomplete progress.
  double get progress {
    final int? total = totalRings;
    if (total == null || total <= 0) return 0;
    return (ring / total).clamp(0.0, 1.0);
  }

  RideSearchStatusEntity copyWith({
    String? rideId,
    int? ring,
    int? totalRings,
    double? radiusMiles,
    double? radius,
    String? distanceUnit,
    String? message,
    int? driversNotified,
    int? totalNotified,
    int? nextRingInSeconds,
  }) {
    return RideSearchStatusEntity(
      rideId: rideId ?? this.rideId,
      ring: ring ?? this.ring,
      totalRings: totalRings ?? this.totalRings,
      radiusMiles: radiusMiles ?? this.radiusMiles,
      radius: radius ?? this.radius,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      message: message ?? this.message,
      driversNotified: driversNotified ?? this.driversNotified,
      totalNotified: totalNotified ?? this.totalNotified,
      nextRingInSeconds: nextRingInSeconds ?? this.nextRingInSeconds,
    );
  }
}
