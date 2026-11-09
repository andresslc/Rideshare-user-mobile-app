class FareCalculatorParams {
  final double miles;
  final String rideType;
  final String? pickupCity;

  const FareCalculatorParams({
    required this.miles,
    required this.rideType,
    this.pickupCity,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'miles': miles,
      'rideType': rideType,
    };
    final String? city = pickupCity?.trim();
    if (city != null && city.isNotEmpty) {
      json['pickupCity'] = city;
    }
    return json;
  }
}
