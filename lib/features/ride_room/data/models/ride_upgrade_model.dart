import 'package:ride_app/features/ride_room/data/models/ride_search_status_model.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_upgrade_entity.dart';

class RideUpgradeOfferModel extends RideUpgradeOfferEntity {
  const RideUpgradeOfferModel({
    super.rideId,
    required super.from,
    required super.to,
    super.promoCode,
    required super.decisionSeconds,
    super.expiresAt,
    super.message,
    super.searchAttempt,
  });

  factory RideUpgradeOfferModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? promo = _asMap(json['promoCode']);

    return RideUpgradeOfferModel(
      rideId: json['rideId']?.toString(),
      from: _fareFrom(_asMap(json['from'])),
      to: _fareFrom(_asMap(json['to'])),
      promoCode: promo == null
          ? null
          : RideUpgradePromoEntity(
              dropped: promo['dropped'] == true,
              reason: promo['reason']?.toString(),
              lostDiscount: _toDouble(promo['lostDiscount']),
            ),
      decisionSeconds: _toInt(json['decisionSeconds']) ?? 0,
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      message: json['message']?.toString(),
      searchAttempt: _toInt(json['searchAttempt']) ?? 0,
    );
  }

  static RideUpgradeFareEntity _fareFrom(Map<String, dynamic>? json) {
    return RideUpgradeFareEntity(
      category: json?['category']?.toString() ?? '',
      fare: _toDouble(json?['fare']) ?? 0,
    );
  }
}

class RideUpgradeResultModel extends RideUpgradeResultEntity {
  const RideUpgradeResultModel({
    super.rideId,
    required super.outcome,
    super.rideType,
    super.rideFare,
    super.searchAttempt,
    super.message,
  });

  factory RideUpgradeResultModel.fromJson(Map<String, dynamic> json) {
    return RideUpgradeResultModel(
      rideId: json['rideId']?.toString(),
      outcome: json['outcome']?.toString() ?? '',
      rideType: json['rideType']?.toString(),
      rideFare: _toDouble(json['rideFare']),
      searchAttempt: _toInt(json['searchAttempt']) ?? 0,
      message: json['message']?.toString(),
    );
  }
}

class RideUpgradeDecisionModel extends RideUpgradeDecisionEntity {
  const RideUpgradeDecisionModel({
    required super.success,
    super.message,
    super.reason,
    super.rideId,
    super.rideType,
    super.rideFare,
    super.searchAttempt,
    super.search,
  });

  factory RideUpgradeDecisionModel.fromAck({
    required bool success,
    required String message,
    dynamic data,
  }) {
    final Map<String, dynamic> json = _asMap(data) ?? <String, dynamic>{};
    final Map<String, dynamic>? search = _asMap(json['search']);
    return RideUpgradeDecisionModel(
      success: success,
      message: message.trim().isEmpty ? null : message.trim(),
      reason: json['reason']?.toString(),
      rideId: json['rideId']?.toString(),
      rideType: json['rideType']?.toString(),
      rideFare: _toDouble(json['rideFare']),
      searchAttempt: _toInt(json['searchAttempt']),
      search: search == null
          ? null
          : RideSearchStatusModel.fromJson(<String, dynamic>{
              'rideId': json['rideId'],
              ...search,
            }),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
