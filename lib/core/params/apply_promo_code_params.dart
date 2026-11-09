class ApplyPromoCodeParams {
  final String code;
  final String rideType;
  final String pickupCity;
  final List<double> rideFare;

  const ApplyPromoCodeParams({
    required this.code,
    required this.rideType,
    required this.pickupCity,
    required this.rideFare,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "code": code,
      "rideType": rideType,
      "pickupCity": pickupCity,
      "rideFare": rideFare,
    };
  }
}
