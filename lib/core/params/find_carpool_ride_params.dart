import 'package:ride_app/core/params/find_ride_params.dart';

class FindCarpoolRideParams {
  final String carpoolId;
  final FindRidePointParams pickupPoint;
  final FindRidePointParams dropOffPoint;
  final int requiredSeats;
  final int avgTime;
  final num distance;
  final num fare;
  final String paymentMethod; // wallet | attached_card
  final String? codeId;
  final String? campaignId;
  final num? originalFare;
  final double? discountAmount;

  const FindCarpoolRideParams({
    this.carpoolId = '',
    required this.pickupPoint,
    required this.dropOffPoint,
    required this.requiredSeats,
    required this.avgTime,
    required this.distance,
    required this.fare,
    required this.paymentMethod,
    this.codeId,
    this.campaignId,
    this.originalFare,
    this.discountAmount,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'carpoolId': carpoolId,
      'pickupPoint': pickupPoint.toJson(),
      'dropOffPoint': dropOffPoint.toJson(),
      'requiredSeats': requiredSeats,
      'avgTime': avgTime,
      'distance': distance,
      'fare': fare,
      'paymentMethod': paymentMethod,
      if (codeId != null) 'codeId': codeId,
      if (campaignId != null) 'campaignId': campaignId,
      if (originalFare != null) 'originalFare': originalFare,
      if (discountAmount != null) 'discountAmount': discountAmount,
    };
  }
}
