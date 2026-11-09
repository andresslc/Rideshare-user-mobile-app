import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/services/storage_service.dart';

final rideEtaProvider = NotifierProvider<RideEtaNotifier, String?>(
  RideEtaNotifier.new,
);

class RideEtaNotifier extends Notifier<String?> {
  @override
  String? build() {
    // Synchronously restore last known ETA from local storage on app cold start
    try {
      final storage = locator<StorageService>();
      return storage.getActiveRideEtaRaw;
    } catch (_) {
      return null;
    }
  }

  /// Updates the ETA. If the incoming ETA is null/empty/0, it ignores it (preserves the current ETA).
  void setEta({required String? eta, String? rideId}) {
    final String? trimmed = eta?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed.startsWith('0')) {
      return;
    }

    state = trimmed;

    final String? trimmedId = rideId?.trim();
    if (trimmedId != null && trimmedId.isNotEmpty) {
      unawaited(locator<StorageService>().setActiveRideEta(trimmedId, trimmed));
    }
  }

  /// Clears ETA when ride ends (completed / cancelled / new search)
  void clearEta() {
    state = null;
    try {
      unawaited(locator<StorageService>().clearActiveRideEta());
    } catch (_) {}
  }
}
