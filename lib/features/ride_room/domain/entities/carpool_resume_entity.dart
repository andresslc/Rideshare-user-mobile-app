class CarpoolResumeEntity {
  final String message;
  final String role;
  final String type;
  final String carpoolId;
  final String bookingId;
  final bool otpVerified;

  const CarpoolResumeEntity({
    required this.message,
    required this.role,
    required this.type,
    required this.carpoolId,
    required this.bookingId,
    required this.otpVerified,
  });
}
