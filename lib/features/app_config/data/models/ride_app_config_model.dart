import 'package:ride_app/features/app_config/domain/entities/ride_app_config_entity.dart';

class DispatchRingModel extends DispatchRingEntity {
  const DispatchRingModel({
    required super.ring,
    required super.radiusMiles,
    required super.radius,
  });

  factory DispatchRingModel.fromJson(Map<String, dynamic> json) {
    final double miles = _toDouble(json['radiusMiles']) ?? 0;
    return DispatchRingModel(
      ring: _toInt(json['ring']) ?? 0,
      radiusMiles: miles,
      // `radius` is the display value. Falling back to miles keeps an older
      // backend readable instead of printing a zero.
      radius: _toDouble(json['radius']) ?? miles,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ring': ring,
    'radiusMiles': radiusMiles,
    'radius': radius,
  };
}

class DispatchConfigModel extends DispatchConfigEntity {
  const DispatchConfigModel({
    required super.totalRings,
    required super.ringTimeoutSeconds,
    required super.rings,
    required super.maxSearchSeconds,
    super.maxSearchSecondsWithUpgrade,
    super.categoryUpgrade,
  });

  factory DispatchConfigModel.fromJson(Map<String, dynamic> json) {
    final List<DispatchRingModel> rings =
        (json['rings'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map>()
            .map(
              (dynamic item) =>
                  DispatchRingModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

    final int ringTimeout = _toInt(json['ringTimeoutSeconds']) ?? 0;
    final int totalRings = _toInt(json['totalRings']) ?? rings.length;

    return DispatchConfigModel(
      totalRings: totalRings,
      ringTimeoutSeconds: ringTimeout,
      rings: rings,
      maxSearchSeconds:
          _toInt(json['maxSearchSeconds']) ?? (totalRings * ringTimeout),
      maxSearchSecondsWithUpgrade: _toInt(json['maxSearchSecondsWithUpgrade']),
      categoryUpgrade: _categoryUpgradeFrom(json['categoryUpgrade']),
    );
  }

  /// Anything missing or malformed reads as "off", so an older backend keeps
  /// the app on today's behaviour.
  static CategoryUpgradeConfigEntity _categoryUpgradeFrom(dynamic value) {
    final Map<String, dynamic>? json = RideAppConfigModel._asMap(value);
    if (json == null) return CategoryUpgradeConfigEntity.disabled;
    final Map<String, dynamic> map =
        RideAppConfigModel._asMap(json['map']) ?? <String, dynamic>{};
    return CategoryUpgradeConfigEntity(
      enabled: json['enabled'] == true,
      decisionSeconds: _toInt(json['decisionSeconds']) ?? 0,
      map: map.map(
        (String key, dynamic target) =>
            MapEntry<String, String>(key, target?.toString() ?? ''),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'totalRings': totalRings,
    'ringTimeoutSeconds': ringTimeoutSeconds,
    'rings': rings
        .map(
          (DispatchRingEntity ring) => ring is DispatchRingModel
              ? ring.toJson()
              : <String, dynamic>{
                  'ring': ring.ring,
                  'radiusMiles': ring.radiusMiles,
                  'radius': ring.radius,
                },
        )
        .toList(),
    'maxSearchSeconds': maxSearchSeconds,
    'maxSearchSecondsWithUpgrade': maxSearchSecondsWithUpgrade,
    'categoryUpgrade': <String, dynamic>{
      'enabled': categoryUpgrade.enabled,
      'decisionSeconds': categoryUpgrade.decisionSeconds,
      'map': categoryUpgrade.map,
    },
  };
}

class RideAppConfigModel extends RideAppConfigEntity {
  const RideAppConfigModel({
    required super.locale,
    required super.distanceUnit,
    required super.dispatch,
    required super.messages,
    super.updatedAt,
  });

  factory RideAppConfigModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> dispatch =
        _asMap(json['dispatch']) ?? <String, dynamic>{};
    final Map<String, dynamic> messages =
        _asMap(json['messages']) ?? <String, dynamic>{};

    return RideAppConfigModel(
      locale: json['locale']?.toString() ?? 'en',
      distanceUnit: json['distanceUnit']?.toString() ?? 'mi',
      dispatch: DispatchConfigModel.fromJson(dispatch),
      messages: messages.map(
        (String key, dynamic value) =>
            MapEntry<String, String>(key, value?.toString() ?? ''),
      ),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'locale': locale,
    'distanceUnit': distanceUnit,
    'dispatch': dispatch is DispatchConfigModel
        ? (dispatch as DispatchConfigModel).toJson()
        : <String, dynamic>{},
    'messages': messages,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
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
