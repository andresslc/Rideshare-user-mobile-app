/// One step of the dispatch ladder as the panel has it configured.
class DispatchRingEntity {
  final int ring;

  /// Raw radius in miles — the number every backend socket event carries.
  final double radiusMiles;

  /// The same radius already converted to [RideAppConfigEntity.distanceUnit].
  /// This is what goes on screen; the app never converts anything itself.
  final double radius;

  const DispatchRingEntity({
    required this.ring,
    required this.radiusMiles,
    required this.radius,
  });
}

class DispatchConfigEntity {
  final int totalRings;
  final int ringTimeoutSeconds;
  final List<DispatchRingEntity> rings;

  /// How long the whole search may keep the rider waiting.
  final int maxSearchSeconds;

  /// Search length including the upgrade decision window and the second
  /// ladder. Null when the backend doesn't send it.
  final int? maxSearchSecondsWithUpgrade;

  /// Switch for the "switch to Luxury" offer, owned by the admin panel.
  final CategoryUpgradeConfigEntity categoryUpgrade;

  const DispatchConfigEntity({
    required this.totalRings,
    required this.ringTimeoutSeconds,
    required this.rings,
    required this.maxSearchSeconds,
    this.maxSearchSecondsWithUpgrade,
    this.categoryUpgrade = CategoryUpgradeConfigEntity.disabled,
  });

  /// The longest a search can legitimately run with the current config.
  int get effectiveMaxSearchSeconds {
    final int? withUpgrade = maxSearchSecondsWithUpgrade;
    if (categoryUpgrade.enabled && withUpgrade != null && withUpgrade > 0) {
      return withUpgrade;
    }
    return maxSearchSeconds;
  }
}

/// `dispatch.categoryUpgrade` from `GET /api/config/ride`. Defaults to off,
/// which keeps the app behaving exactly as before the feature existed.
class CategoryUpgradeConfigEntity {
  final bool enabled;
  final int decisionSeconds;

  /// Source category → offered category, e.g. `economy` → `luxury`.
  final Map<String, String> map;

  const CategoryUpgradeConfigEntity({
    required this.enabled,
    required this.decisionSeconds,
    required this.map,
  });

  static const CategoryUpgradeConfigEntity disabled =
      CategoryUpgradeConfigEntity(
        enabled: false,
        decisionSeconds: 0,
        map: <String, String>{},
      );
}

/// Everything the search screen needs, served by `GET /api/config/ride` and
/// editable from the admin panel: the ladder, its timings, the distance unit
/// and the copy.
///
/// Nothing here may be hardcoded in a build. Change the ladder or a sentence in
/// the panel and the app has to follow without a release.
class RideAppConfigEntity {
  final String locale;

  /// `mi` or `km`. Printed next to every distance as it comes.
  final String distanceUnit;
  final DispatchConfigEntity dispatch;

  /// Copy already resolved in [locale], keyed by the backend's message key.
  final Map<String, String> messages;
  final DateTime? updatedAt;

  const RideAppConfigEntity({
    required this.locale,
    required this.distanceUnit,
    required this.dispatch,
    required this.messages,
    this.updatedAt,
  });

  /// The configured copy for [key], or null when the panel has nothing for it
  /// and the app should fall back to its own string.
  String? message(String key) {
    final String? value = messages[key];
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Message keys the rider app reads. The backend serves more; these are the
/// ones this app has a place for.
class RideConfigMessageKeys {
  RideConfigMessageKeys._();

  static const String findingDrivers = 'RIDE_REQUESTED_FINDING_DRIVERS';
  static const String searchInProgress = 'RIDE_SEARCH_IN_PROGRESS';
  static const String searchExhausted = 'RIDE_SEARCH_EXHAUSTED';
  static const String useCarpoolMatching = 'USE_CARPOOL_MATCHING';
  static const String offersDisabled = 'RIDE_OFFERS_DISABLED';
}
