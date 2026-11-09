/// The dispatch ladder ran out of rings without a driver taking the ride
/// (`ride:search:exhausted`).
///
/// By the time this arrives the backend has already moved the ride to
/// `expired`, dropped the rider's pending request and charged nothing, so the
/// rider can request another ride straight away.
class RideSearchExhaustedEntity {
  final String? rideId;
  final String? reason;

  /// Already translated to the rider's language by the backend; safe to show
  /// as-is.
  final String? message;

  /// Widest radius the search reached, in miles. Raw; use [radiusReached].
  final double? radiusReachedMiles;

  /// The same radius already converted to [distanceUnit] by the backend.
  final double? radiusReached;

  /// `mi` or `km`, as the admin panel has it configured.
  final String distanceUnit;

  const RideSearchExhaustedEntity({
    this.rideId,
    this.reason,
    this.message,
    this.radiusReachedMiles,
    this.radiusReached,
    this.distanceUnit = 'mi',
  });
}
