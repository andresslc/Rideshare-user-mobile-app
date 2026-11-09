class FareBreakdownEntity {
  final double baseRate;
  final double surcharge;
  final double ratePerMile;
  final double discountPercentage;
  final double discount;
  final double totalFare;
  final bool isPeak;

  const FareBreakdownEntity({
    required this.baseRate,
    required this.surcharge,
    required this.ratePerMile,
    required this.discountPercentage,
    required this.discount,
    required this.totalFare,
    required this.isPeak,
  });

  factory FareBreakdownEntity.fromMap(Map<String, dynamic> map) {
    double readDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;

    return FareBreakdownEntity(
      baseRate: readDouble(map['baseRate']),
      surcharge: readDouble(map['surcharge']),
      ratePerMile: readDouble(map['ratePerMile']),
      discountPercentage: readDouble(map['discountPercentage']),
      discount: readDouble(map['discount']),
      totalFare: readDouble(map['totalFare']),
      isPeak: map['isPeak'] == true,
    );
  }
}

class RideFareQuoteEntity {
  final FareBreakdownEntity? economy;
  final FareBreakdownEntity? luxury;
  final double? totalFare;

  const RideFareQuoteEntity({
    this.economy,
    this.luxury,
    this.totalFare,
  });

  bool get hasBreakdown => economy != null && luxury != null;
  bool get hasAnyFare => hasBreakdown || totalFare != null;
  double get primaryFare => economy?.totalFare ?? totalFare ?? 0;

  factory RideFareQuoteEntity.fromPayload(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return RideFareQuoteEntity._fromMap(payload);
    }

    if (payload is Map) {
      return RideFareQuoteEntity._fromMap(Map<String, dynamic>.from(payload));
    }

    throw const FormatException('Unsupported fare response format');
  }

  factory RideFareQuoteEntity._fromMap(Map<String, dynamic> map) {
    final dynamic economyPayload = map['economy'];
    final dynamic luxuryPayload = map['luxury'];
    final double? totalFare = (map['totalFare'] as num?)?.toDouble();

    FareBreakdownEntity? parseBreakdown(dynamic value) {
      if (value is Map<String, dynamic>) {
        return FareBreakdownEntity.fromMap(value);
      }
      if (value is Map) {
        return FareBreakdownEntity.fromMap(Map<String, dynamic>.from(value));
      }
      return null;
    }

    final FareBreakdownEntity? economy = parseBreakdown(economyPayload);
    final FareBreakdownEntity? luxury = parseBreakdown(luxuryPayload);

    if (economy != null || luxury != null) {
      return RideFareQuoteEntity(
        economy: economy,
        luxury: luxury,
        totalFare: totalFare ?? economy?.totalFare,
      );
    }

    return RideFareQuoteEntity(totalFare: totalFare);
  }
}
