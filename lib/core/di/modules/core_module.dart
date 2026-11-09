import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/config/app_config.dart';
import 'package:ride_app/core/config/remote_config_model.dart';
import 'package:ride_app/core/config/remote_config_service.dart';
import 'package:ride_app/core/constants/constants_data.dart';
import 'package:ride_app/core/navigation/app_router.dart';
import 'package:ride_app/core/navigation/routes.dart';
import 'package:ride_app/core/observability/observability_service.dart';
import 'package:ride_app/core/services/connectivity_service.dart';
import 'package:ride_app/core/services/device_info_service.dart';
import 'package:ride_app/features/auth/data/session/auth_session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../location/service_region.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/network_quality_service.dart';
import '../../services/socket_service.dart';
import '../../services/storage_service.dart';
import '../../theme/theme_notifier.dart';
import '../service_locator.dart';

/// Registers core infrastructure services.
void registerCoreModule() {
  locator.registerLazySingleton<StorageService>(
    () => StorageService(locator<SharedPreferences>()),
  );

  locator.registerLazySingleton<ApiService>(
    () => ApiService(
      locator<StorageService>(),
      locator<DeviceInfoService>(),
      locator<SocketService>(),
      baseUrl: locator<AppConfig>().baseUrl,
    ),
  );

  locator.registerLazySingleton<ThemeNotifier>(
    () => ThemeNotifier(locator<StorageService>()),
  );

  locator.registerLazySingleton<LocationService>(
    () => LocationService(
      locator<StorageService>(),
      placesObserver: (event) {
        if (locator.isRegistered<ObservabilityService>()) {
          unawaited(
            locator<ObservabilityService>().recordAddressSearchEvent(event),
          );
        }
      },
    ),
  );

  locator.registerLazySingleton<SocketService>(
    () => SocketService(
      locator<StorageService>(),
      onAuthRequired: (_) {
        unawaited(locator<StorageService>().clearAuthSession());
        locator<ApiService>().clearAuthToken();
        rootNavigatorKey.currentState?.overlay?.context.goNamed(
          Routes.login.name,
          extra: true,
        );
      },
    ),
  );

  locator.registerSingleton<ConnectivityService>(ConnectivityService());
  locator.registerSingleton<NetworkQualityService>(NetworkQualityService());

  locator.registerLazySingleton<RemoteConfigService>(
    () => RemoteConfigService(
      FirebaseRemoteConfig.instance,
      onConfigChanged: _onRemoteConfigChangedInLocator,
    ),
  );
}

void _onRemoteConfigChangedInLocator(RemoteConfigModel config) {
  final invalidateSearch =
      remoteConfigModel.addressSearchV2Enabled !=
          config.addressSearchV2Enabled ||
      remoteConfigModel.mapApiKey != config.mapApiKey ||
      remoteConfigModel.serviceRegionId != config.serviceRegionId;
  remoteConfigModel = config;
  if (invalidateSearch && locator.isRegistered<LocationService>()) {
    locator<LocationService>().invalidateAddressSearches();
  }
  ServiceRegionConfig.setActiveByKey(config.serviceRegionId);

  // Update ApiService if already initialized
  if (locator.isRegistered<ApiService>()) {
    locator<ApiService>().updateBaseUrl(locator<AppConfig>().baseUrl);
  }

  if (locator.isRegistered<NetworkQualityService>()) {
    locator<NetworkQualityService>().configure(
      baseUrl: locator<AppConfig>().baseUrl,
    );
  }

  // Update SocketService if already initialized
  if (locator.isRegistered<SocketService>()) {
    locator<SocketService>().updateSocketUrl(locator<AppConfig>().baseUrl);
  }

  // Update Stripe publishable key at runtime
  if (config.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = config.stripePublishableKey;
  }
}

/// Registers Crashlytics-backed observability and the auth session bridge.
///
/// Must run after [registerCoreModule] — depends on StorageService/ApiService.
void registerObservabilityModule() {
  locator.registerLazySingleton<ObservabilityService>(
    () => ObservabilityService(
      FirebaseCrashlytics.instance,
      locator<StorageService>(),
      locator<AppConfig>(),
    ),
  );

  locator.registerLazySingleton<AuthSessionManager>(
    () => AuthSessionManager(
      storageService: locator<StorageService>(),
      apiService: locator<ApiService>(),
      observabilityService: locator<ObservabilityService>(),
    ),
  );
}
