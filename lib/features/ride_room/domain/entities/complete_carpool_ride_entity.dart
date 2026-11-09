class CompleteCarpoolRideEntity {
  final String bookingId;
  final bool carpoolCompleted;
  final DateTime? rideCompletedAt;
  final String message;

  const CompleteCarpoolRideEntity({
    required this.bookingId,
    required this.carpoolCompleted,
    required this.rideCompletedAt,
    required this.message,
  });
}