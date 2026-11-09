import 'package:ride_app/features/ride_room/domain/entities/ride_fare_quote_entity.dart';

class FareBreakdownModel extends FareBreakdownEntity {
  const FareBreakdownModel({
    required super.baseRate,
    required super.surcharge,
    required super.ratePerMile,
    required super.discountPercentage,
    required super.discount,
    required super.totalFare,
    required super.isPeak,
  });

  factory FareBreakdownModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const FareBreakdownModel(
        baseRate: 0,
        surcharge: 0,
        ratePerMile: 0,
        discountPercentage: 0,
        discount: 0,
        totalFare: 0,
        isPeak: false,
      );
    }

    double readDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;

    return FareBreakdownModel(
      baseRate: readDouble(json['baseRate']),
      surcharge: readDouble(json['surcharge']),
      ratePerMile: readDouble(json['ratePerMile']),
      discountPercentage: readDouble(json['discountPercentage']),
      discount: readDouble(json['discount']),
      totalFare: readDouble(json['totalFare']),
      isPeak: json['isPeak'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'baseRate': baseRate,
      'surcharge': surcharge,
      'ratePerMile': ratePerMile,
      'discountPercentage': discountPercentage,
      'discount': discount,
      'totalFare': totalFare,
      'isPeak': isPeak,
    };
  }
}

class RideFareQuoteModel extends RideFareQuoteEntity {
  const RideFareQuoteModel({
    super.economy,
    super.luxury,
    super.totalFare,
  });

  factory RideFareQuoteModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RideFareQuoteModel();
    }

    final FareBreakdownModel? economy = _asMap(json['economy']) != null
        ? FareBreakdownModel.fromJson(_asMap(json['economy']))
        : null;
    final FareBreakdownModel? luxury = _asMap(json['luxury']) != null
        ? FareBreakdownModel.fromJson(_asMap(json['luxury']))
        : null;
    final double? totalFare = (json['totalFare'] as num?)?.toDouble();

    if (economy != null || luxury != null) {
      return RideFareQuoteModel(
        economy: economy,
        luxury: luxury,
        totalFare: totalFare ?? economy?.totalFare,
      );
    }

    return RideFareQuoteModel(totalFare: totalFare);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'economy': (economy as FareBreakdownModel?)?.toJson(),
      'luxury': (luxury as FareBreakdownModel?)?.toJson(),
      'totalFare': totalFare,
    };
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
