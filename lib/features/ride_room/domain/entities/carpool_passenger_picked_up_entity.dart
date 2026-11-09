class CarpoolPassengerPickedUpEntity {
  final String bookingId;
  final String carpoolId;
  final String passengerId;
  final DateTime? pickedUpAt;
  final bool otpVerified;

  const CarpoolPassengerPickedUpEntity({
    required this.bookingId,
    required this.carpoolId,
    required this.passengerId,
    required this.pickedUpAt,
    required this.otpVerified,
  });
}
