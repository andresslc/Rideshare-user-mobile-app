class PromoCodeFareEntity {
  final double originalFare;
  final bool discountApplied;
  final double discountAmount;
  final double finalFare;

  const PromoCodeFareEntity({
    required this.originalFare,
    required this.discountApplied,
    required this.discountAmount,
    required this.finalFare,
  });
}

class PromoCodeEntity {
  final List<PromoCodeFareEntity> fares;
  final String codeId;
  final String campaignId;
  final String discountType;
  final double discountValue;

  const PromoCodeEntity({
    required this.fares,
    required this.codeId,
    required this.campaignId,
    required this.discountType,
    required this.discountValue,
  });
}