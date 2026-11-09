class CancelCarpoolRequestParams {
  final String bookingId;

  const CancelCarpoolRequestParams({required this.bookingId});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'bookingId': bookingId};
  }
}
