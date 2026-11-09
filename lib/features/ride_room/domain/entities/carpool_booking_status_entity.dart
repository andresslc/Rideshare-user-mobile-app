class CarpoolBookingStatusEntity {
  final String bookingId;
  final String status;
  final String otp;
  final String reason;

  const CarpoolBookingStatusEntity({
    required this.bookingId,
    required this.status,
    required this.otp,
    required this.reason,
  });
}
