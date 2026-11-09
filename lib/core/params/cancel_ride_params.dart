class CancelRideParams {
  final String rideId;
  final bool isPendingRequestCancelled;
  final String? cancellationReason;

  const CancelRideParams({
    required this.rideId,
    this.isPendingRequestCancelled = false,
    this.cancellationReason,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rideId': rideId,
      'isPendingRequestCancelled': isPendingRequestCancelled,
      if (cancellationReason != null && cancellationReason!.trim().isNotEmpty)
        'cancellationReason': cancellationReason!.trim(),
    };
  }
}
