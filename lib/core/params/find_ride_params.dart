/// Payload for `ride:request:create`.
///
/// The backend renamed `rideType` to `category` and retired `private`: a new
/// request is `economy`, `luxury` or `carpool`. The old spelling is still
/// accepted server-side, but this app only sends `category`.
class FindRideParams {
  final FindRidePointParams pickupPoint;
  final FindRidePointParams dropOffPoint;
  final String category; // economy | luxury | carpool
  final double rideDistance;
  final num rideFare;
  final int averageTime;
  final int requiredSeats;

  /// Optional: a fully discounted ride never reaches a payment rail, so the
  /// request goes out without a method rather than forcing one.
  final String? paymentMethod; // wallet | attached_card
  final String specialRequest;
  final String? codeId;
  final String? campaignId;
  final num? originalRideFare;
  final double? discountAmount;

  /// Same string sent to the fare calculator. Lets the backend price an
  /// upgrade with the city's rate instead of the global one.
  final String? pickupCity;

  const FindRideParams({
    required this.pickupPoint,
    required this.dropOffPoint,
    required this.category,
    required this.rideDistance,
    required this.rideFare,
    required this.averageTime,
    this.requiredSeats = 1,
    this.paymentMethod,
    required this.specialRequest,
    this.codeId,
    this.campaignId,
    this.originalRideFare,
    this.discountAmount,
    this.pickupCity,
  });

  /// True when a promotion covers the whole fare. The backend skips the wallet
  /// and card checks in this case.
  bool get isFreeRide => rideFare <= 0;

  /// The same request after the rider accepted an upgrade, so a retry asks
  /// for the ride they last agreed to. A dropped promo code goes with it; a
  /// kept one loses its pre-discount fare, which only the backend knows for
  /// the new category.
  FindRideParams upgradedTo({
    required String category,
    required num rideFare,
    required bool dropPromoCode,
  }) {
    return FindRideParams(
      pickupPoint: pickupPoint,
      dropOffPoint: dropOffPoint,
      category: category,
      rideDistance: rideDistance,
      rideFare: rideFare,
      averageTime: averageTime,
      requiredSeats: requiredSeats,
      paymentMethod: paymentMethod,
      specialRequest: specialRequest,
      codeId: dropPromoCode ? null : codeId,
      campaignId: dropPromoCode ? null : campaignId,
      pickupCity: pickupCity,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pickupPoint': pickupPoint.toJson(),
      'dropOffPoint': dropOffPoint.toJson(),
      'category': category,
      'rideDistance': rideDistance,
      'rideFare': rideFare,
      'averageTime': averageTime,
      'requiredSeats': requiredSeats,
      if (paymentMethod != null && !isFreeRide) 'paymentMethod': paymentMethod,
      'specialRequest': specialRequest,
      if (codeId != null) 'codeId': codeId,
      if (campaignId != null) 'campaignId': campaignId,
      if (originalRideFare != null) 'originalRideFare': originalRideFare,
      if (pickupCity != null && pickupCity!.trim().isNotEmpty)
        'pickupCity': pickupCity!.trim(),
    };
  }
}

class FindRidePointParams {
  final String placeName;
  final FindRideLocationParams location;

  const FindRidePointParams({required this.placeName, required this.location});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'placeName': placeName,
      'location': location.toJson(),
    };
  }
}

class FindRideLocationParams {
  final String type; // Point
  final List<double> coordinates; // [lng, lat]

  const FindRideLocationParams({
    this.type = 'Point',
    required this.coordinates,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'type': type, 'coordinates': coordinates};
  }
}
