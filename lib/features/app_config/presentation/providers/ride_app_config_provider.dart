import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/services/storage_service.dart';
import 'package:ride_app/core/utils/app_log.dart';
import 'package:ride_app/features/app_config/domain/entities/ride_app_config_entity.dart';
import 'package:ride_app/features/app_config/domain/use_cases/get_ride_app_config_usecase.dart';

/// The dispatch configuration the app renders with.
///
/// Loaded once at startup and cached. Null means the app never got one and has
/// to fall back to its own strings — the search still works, because every
/// socket event carries its own values.
final rideAppConfigProvider =
    NotifierProvider<RideAppConfigController, RideAppConfigEntity?>(
      RideAppConfigController.new,
    );

class RideAppConfigController extends Notifier<RideAppConfigEntity?> {
  late GetRideAppConfigUseCase _getRideAppConfigUseCase;
  bool _isLoading = false;

  /// The cached copy only bridges startup; the panel's switches (such as
  /// `categoryUpgrade.enabled`) must reach the app, so every session fetches
  /// once.
  bool _refreshedThisSession = false;

  @override
  RideAppConfigEntity? build() {
    _getRideAppConfigUseCase = locator<GetRideAppConfigUseCase>();
    // Whatever the last run cached, available before the first frame.
    return _getRideAppConfigUseCase.cached();
  }

  /// One refresh per session is enough; the panel does not change mid-ride.
  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force &&
        _refreshedThisSession &&
        state != null &&
        _matchesCurrentLocale(state!)) {
      return;
    }

    _isLoading = true;
    try {
      final result = await _getRideAppConfigUseCase.call(
        locale: _currentLocale(),
      );
      result.fold(
        (failure) {
          log(
            'ride config unavailable, keeping ${state == null ? 'app defaults' : 'cached values'}: ${failure.message}',
            name: 'ride config',
          );
        },
        (config) {
          state = config;
          _refreshedThisSession = true;
        },
      );
    } finally {
      _isLoading = false;
    }
  }

  String _currentLocale() {
    final String? saved = locator<StorageService>().getLanguageCode;
    final String normalized = (saved ?? 'en').trim().toLowerCase();
    if (normalized.isEmpty) return 'en';
    return normalized.split(RegExp('[-_]')).first;
  }

  /// A rider who switches language needs the copy in the new one.
  bool _matchesCurrentLocale(RideAppConfigEntity config) {
    return config.locale.toLowerCase() == _currentLocale();
  }
}
