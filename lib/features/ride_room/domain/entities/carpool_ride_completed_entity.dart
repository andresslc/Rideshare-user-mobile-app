class CarpoolRideCompletedEntity {
  final String bookingId;
  final String carpoolId;
  final double fareCharged;
  final DateTime? rideCompletedAt;

  const CarpoolRideCompletedEntity({
    required this.bookingId,
    required this.carpoolId,
    required this.fareCharged,
    required this.rideCompletedAt,
  });
}
