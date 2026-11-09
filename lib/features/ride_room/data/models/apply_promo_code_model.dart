import 'package:ride_app/features/ride_room/domain/entities/apply_promo_code_entity.dart';

class PromoCodeFareModel extends PromoCodeFareEntity {
  const PromoCodeFareModel({
    required super.originalFare,
    required super.discountApplied,
    required super.discountAmount,
    required super.finalFare,
  });

  factory PromoCodeFareModel.fromJson(Map<String, dynamic> json) {
    return PromoCodeFareModel(
      originalFare: (json['originalFare'] ?? 0).toDouble(),
      discountApplied: json['discountApplied'] ?? false,
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalFare: (json['finalFare'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "originalFare": originalFare,
      "discountApplied": discountApplied,
      "discountAmount": discountAmount,
      "finalFare": finalFare,
    };
  }
}

class PromoCodeModel extends PromoCodeEntity {
  const PromoCodeModel({
    required List<PromoCodeFareModel> super.fares,
    required super.codeId,
    required super.campaignId,
    required super.discountType,
    required super.discountValue,
  });

  factory PromoCodeModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PromoCodeModel(
        fares: [],
        codeId: '',
        campaignId: '',
        discountType: '',
        discountValue: 0,
      );
    }

    final rawFares = json['fares'] as List?;
    final List<PromoCodeFareModel> parsedFares = rawFares != null
        ? rawFares
            .map((e) => PromoCodeFareModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : [];

    return PromoCodeModel(
      fares: parsedFares,
      codeId: json['codeId'] ?? '',
      campaignId: json['campaignId'] ?? '',
      discountType: json['discountType'] ?? '',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "fares": fares.map((e) => (e as PromoCodeFareModel).toJson()).toList(),
      "codeId": codeId,
      "campaignId": campaignId,
      "discountType": discountType,
      "discountValue": discountValue,
    };
  }
}
