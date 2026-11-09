class JoinedCarpoolEntity {
  final String bookingId;
  final String message;

  const JoinedCarpoolEntity({
    required this.bookingId,
    required this.message,
  });

  JoinedCarpoolEntity copyWith({
    String? bookingId,
    String? message,
  }) {
    return JoinedCarpoolEntity(
      bookingId: bookingId ?? this.bookingId,
      message: message ?? this.message,
    );
  }
}
