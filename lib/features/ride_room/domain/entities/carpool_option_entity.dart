/// Represents an available carpool ride option shown on the selection screen.
class CarpoolOptionEntity {
  const CarpoolOptionEntity({
    required this.id,
    required this.driverName,
    required this.driverRating,
    required this.driverProfileImage,
    required this.carName,
    required this.plate,
    required this.locationStops,
    required this.rideStartTime,
    required this.availableSeats,
    required this.avgTimeMinutes,
    required this.totalDistanceKm,
    // required this.fareMin,
    required this.fareMax,
  });

  final String id;
  final String driverName;
  final double driverRating;
  final String driverProfileImage;
  final String carName;
  final String plate;

  /// Ordered list: first = pickup (Stop 1), last = your destination.
  final List<String> locationStops;
  final String rideStartTime;
  final int availableSeats;
  final int avgTimeMinutes;
  final double totalDistanceKm;
  // final double fareMin;
  final double fareMax;
}
