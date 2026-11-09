import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../di/service_locator.dart';
import 'app_config.dart';

/// Model class to hold all remote configuration values
class RemoteConfigModel {
  static const String stripeTestKey =
      'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY';

  static bool _isDevOrStaging() {
    if (locator.isRegistered<AppConfig>()) {
      return locator<AppConfig>().isDevOrStaging;
    }
    return kDebugMode;
  }

  final String baseUrlDev;
  final String baseUrlStaging;
  final String baseUrlProd;
  // final String socketUrl;
  final String mapApiKey;
  final String stripePublishableKey;
  final String termsURL;
  final String privacyURL;
  final String supportEmail;
  final String appDomain;
  final String websiteURL;
  final bool addressSearchV2Enabled;
  final bool useOsrmInDebug;
  final String serviceRegionId;
  final String updateTitle;
  final String updateMessage;
  final String minRequiredVersion;
  final String latestVersion;
  final String appStoreUrl;
  final String playStoreUrl;

  const RemoteConfigModel({
    this.addressSearchV2Enabled = false,
    required this.baseUrlDev,
    required this.baseUrlStaging,
    required this.baseUrlProd,
    // required this.socketUrl,
    required this.mapApiKey,
    required this.stripePublishableKey,
    required this.termsURL,
    required this.privacyURL,
    required this.supportEmail,
    required this.appDomain,
    required this.websiteURL,
    required this.useOsrmInDebug,
    required this.serviceRegionId,
    required this.updateTitle,
    required this.updateMessage,
    required this.minRequiredVersion,
    required this.latestVersion,
    required this.appStoreUrl,
    required this.playStoreUrl,
  });

  /// Static async method to create from Firebase Remote Config
  static Future<RemoteConfigModel> fromRemoteConfig(
    FirebaseRemoteConfig remoteConfig,
  ) async {
    try {
      final String configString = remoteConfig.getString("app_config");
      return RemoteConfigModel.fromConfigString(configString);
    } catch (e) {
      return RemoteConfigModel.defaults();
    }
  }

  /// Parse from a raw JSON config string (synchronous).
  factory RemoteConfigModel.fromConfigString(String configString) {
    try {
      if (configString.isEmpty || configString == '{}') {
        return RemoteConfigModel.defaults();
      }

      final Map<String, dynamic> configMap = jsonDecode(configString);
      final defaults = RemoteConfigModel.defaults();

      // final String rawBaseUrl = kDebugMode
      //     ? 'https://api.dev.example.com' //(configMap['DEV_BASE_URL'] ?? '')
      //     : 'https://api.staging.example.com'; // (configMap['STAGGING_BASE_URL'] ?? '');

      // SOCKET IS ALWAYS rawBaseUrl
      // final String rawSocketUrl = rawBaseUrl;

      return RemoteConfigModel(
        addressSearchV2Enabled: configMap['addressSearchV2Enabled'] == true,
        baseUrlDev: configMap['BASE_URL_DEV'] ?? defaults.baseUrlDev,
        baseUrlStaging:
            configMap['BASE_URL_STAGING'] ?? defaults.baseUrlStaging,
        baseUrlProd: configMap['BASE_URL_PROD'] ?? defaults.baseUrlProd,
        // socketUrl: rawSocketUrl.isNotEmpty ? rawSocketUrl : defaults.socketUrl,
        mapApiKey: _nonEmpty(configMap['MapApiKey'], defaults.mapApiKey),
        stripePublishableKey: _isDevOrStaging()
            ? stripeTestKey
            : _nonEmpty(
                configMap['stripePublishableKey'] ??
                    configMap['stripe_publishable_key'],
                defaults.stripePublishableKey,
              ),
        termsURL: _nonEmpty(configMap['termsURL'], defaults.termsURL),
        privacyURL: _nonEmpty(configMap['privacyURL'], defaults.privacyURL),
        supportEmail: _nonEmpty(
          configMap['supportEmail'],
          defaults.supportEmail,
        ),
        appDomain: _nonEmpty(configMap['appDomain'], defaults.appDomain),
        websiteURL: _nonEmpty(configMap['websiteURL'], defaults.websiteURL),
        useOsrmInDebug: configMap['useOsrmInDebug'] ?? true,
        serviceRegionId: _nonEmpty(
          configMap['serviceRegionId'] ?? configMap['service_region_id'],
          defaults.serviceRegionId,
        ),
        updateTitle: _nonEmpty(configMap['updateTitle'], defaults.updateTitle),
        updateMessage: _nonEmpty(
          configMap['updateMessage'],
          defaults.updateMessage,
        ),
        minRequiredVersion: _nonEmpty(
          configMap['minRequiredVersion'] ?? configMap['force_update_version'],
          defaults.minRequiredVersion,
        ),
        latestVersion: _nonEmpty(
          configMap['latestVersion'] ?? configMap['latest_app_version'],
          defaults.latestVersion,
        ),
        // minAppVersion: _nonEmpty(
        //   configMap['minAppVersion'] ??
        //       configMap['minRequiredVersion'] ??
        //       configMap['force_update_version'],
        //   defaults.minAppVersion,
        // ),

        // latestAppVersion: _nonEmpty(
        //   configMap['latestAppVersion'] ??
        //       configMap['latestVersion'] ??
        //       configMap['latest_app_version'],
        //   defaults.latestAppVersion,
        // ),
        // minAppVersion: _nonEmpty(
        //   configMap['minAppVersion'],
        //   defaults.minAppVersion,
        // ),
        // latestAppVersion: _nonEmpty(
        //   configMap['latestAppVersion'],
        //   defaults.latestAppVersion,
        // ),
        appStoreUrl: _nonEmpty(
          configMap['userAppStoreUrl'],
          defaults.appStoreUrl,
        ),
        playStoreUrl: _nonEmpty(
          configMap['userPlayStoreUrl'],
          defaults.playStoreUrl,
        ),
      );
    } catch (e) {
      return RemoteConfigModel.defaults();
    }
  }

  /// Returns [value] if it is a non-null, non-empty string; otherwise [fallback].
  static String _nonEmpty(dynamic value, String fallback) {
    if (value is String && value.isNotEmpty) return value;
    return fallback;
  }

  /// Factory constructor with hardcoded default values
  factory RemoteConfigModel.defaults() {
    return RemoteConfigModel(
      baseUrlDev: 'https://api.dev.example.com',
      baseUrlStaging: 'https://api.staging.example.com',
      baseUrlProd: 'https://api.example.com',
      // socketUrl: kDebugMode
      //     ? 'https://api.dev.example.com'
      //     : 'https://api.staging.example.com',
      mapApiKey: 'YOUR_GOOGLE_MAPS_API_KEY',
      stripePublishableKey: stripeTestKey,
      termsURL: 'https://example.com/terms-of-service',
      privacyURL: 'https://example.com/privacy-policy',
      supportEmail: 'support@example.com',
      appDomain: 'example.com',
      websiteURL: 'https://example.com',
      useOsrmInDebug: true,
      serviceRegionId: (kDebugMode || _isDevOrStaging()) ? 'global' : 'florida',
      updateTitle: "New Update Available",
      updateMessage:
          "A new version of Ride App is available. Please update for the best experience.",
      minRequiredVersion: '1.0.1',
      latestVersion: '1.0.1',
      // minAppVersion: "1.0.0",
      // latestAppVersion: "1.0.0",
      appStoreUrl: "https://apps.apple.com/app/id0000000000",
      playStoreUrl:
          "https://play.google.com/store/apps/details?id=com.example.rideapp",
    );
  }

  RemoteConfigModel copyWith({
    bool? addressSearchV2Enabled,
    String? baseUrlDev,
    String? baseUrlStaging,
    String? baseUrlProd,
    String? socketUrl,
    String? mapApiKey,
    String? stripePublishableKey,
    String? termsURL,
    String? privacyURL,
    String? supportEmail,
    String? appDomain,
    String? websiteURL,
    bool? useOsrmInDebug,
    String? serviceRegionId,
    String? updateTitle,
    String? updateMessage,
    String? minRequiredVersion,
    String? latestVersion,
    String? appStoreUrl,
    String? playStoreUrl,
  }) {
    return RemoteConfigModel(
      addressSearchV2Enabled:
          addressSearchV2Enabled ?? this.addressSearchV2Enabled,
      baseUrlDev: baseUrlDev ?? this.baseUrlDev,
      baseUrlStaging: baseUrlStaging ?? this.baseUrlStaging,
      baseUrlProd: baseUrlProd ?? this.baseUrlProd,
      // socketUrl: socketUrl ?? this.socketUrl,
      mapApiKey: mapApiKey ?? this.mapApiKey,
      stripePublishableKey: stripePublishableKey ?? this.stripePublishableKey,
      termsURL: termsURL ?? this.termsURL,
      privacyURL: privacyURL ?? this.privacyURL,
      supportEmail: supportEmail ?? this.supportEmail,
      appDomain: appDomain ?? this.appDomain,
      websiteURL: websiteURL ?? this.websiteURL,
      useOsrmInDebug: useOsrmInDebug ?? this.useOsrmInDebug,
      serviceRegionId: serviceRegionId ?? this.serviceRegionId,
      updateTitle: updateTitle ?? this.updateTitle,
      updateMessage: updateMessage ?? this.updateMessage,
      minRequiredVersion: minRequiredVersion ?? this.minRequiredVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      appStoreUrl: appStoreUrl ?? this.appStoreUrl,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
    );
  }

  @override
  String toString() =>
      'RemoteConfigModel(serviceRegionId: $serviceRegionId, addressSearchV2Enabled: $addressSearchV2Enabled)';
}
