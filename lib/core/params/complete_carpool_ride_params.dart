class CompleteCarpoolRideParams {
  final String bookingId;

  const CompleteCarpoolRideParams({required this.bookingId});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'bookingId': bookingId};
  }
}