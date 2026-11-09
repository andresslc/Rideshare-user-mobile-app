import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:ride_app/core/config/app_config.dart';
import 'package:ride_app/core/constants/constants_data.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_log.dart';

enum UpdateStatus { noUpdate, optionalUpdate, forceUpdate }

class AppUpdateService {
  AppUpdateService._();

  /// Compares current app version with remote config versions.
  // static Future<UpdateStatus> checkUpdateStatus() async {
  //   try {
  //     final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //     final String currentVersion = packageInfo.version;
  //           // final latest = remoteConfigModel.latestVersion;

  //     log("Current Version: $currentVersion", name: "AppUpdateService");
  //     log("Min Version: ${remoteConfigModel.minAppVersion}", name: "AppUpdateService");
  //     log("Latest Version: ${remoteConfigModel.latestAppVersion}", name: "AppUpdateService");

  //     if (_isVersionGreaterThan(remoteConfigModel.latestAppVersion, currentVersion)) {
  //       if (_isVersionGreaterThan(remoteConfigModel.minAppVersion, currentVersion)) {
  //         return UpdateStatus.forceUpdate;
  //       }
  //       return UpdateStatus.optionalUpdate;
  //     }

  //     return UpdateStatus.noUpdate;
  //   } catch (e) {
  //     log("Error checking update status: $e", name: "AppUpdateService");
  //     return UpdateStatus.noUpdate;
  //   }
  // }
  static Future<UpdateStatus> checkUpdateStatus() async {
    try {
      final config = locator<AppConfig>();
      if (config.flavor == Flavor.dev || config.flavor == Flavor.staging) {
        return UpdateStatus.noUpdate;
      }
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      log("CURRENT VERSION: $currentVersion", name: "AppUpdateService");
      log(
        "MIN VERSION: ${remoteConfigModel.minRequiredVersion}",
        name: "AppUpdateService",
      );

      log(
        "LATEST VERSION: ${remoteConfigModel.latestVersion}",
        name: "AppUpdateService",
      );
      final min = remoteConfigModel.minRequiredVersion;
      final latest = remoteConfigModel.latestVersion;

      if (_isVersionLower(currentVersion, min)) {
        return UpdateStatus.forceUpdate;
      }

      if (_isVersionLower(currentVersion, latest)) {
        return UpdateStatus.optionalUpdate;
      }

      return UpdateStatus.noUpdate;
    } catch (e) {
      return UpdateStatus.noUpdate;
    }
  }

  /// Launches the respective app store.
  static Future<void> launchStore() async {
    final String url = Platform.isAndroid
        ? remoteConfigModel.playStoreUrl
        : remoteConfigModel.appStoreUrl;

    log("Launching Store URL: $url", name: "AppUpdateService");

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      log("Could not launch $url", name: "AppUpdateService");
    }
  }

  static bool _isVersionLower(String current, String target) {
    if (target.isEmpty) return false;

    List<int> currentParts = current
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> targetParts = target
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    // Pad with zeros if necessary
    int maxLength = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;
    while (currentParts.length < maxLength) {
      currentParts.add(0);
    }
    while (targetParts.length < maxLength) {
      targetParts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (currentParts[i] < targetParts[i]) return true;
      if (currentParts[i] > targetParts[i]) return false;
    }
    return false;
  }

  /// Simple semantic version comparison: returns true if v1 > v2
  // static bool _isVersionGreaterThan(String v1, String v2) {
  //   try {
  //     List<int> v1Components = v1.split('.').map(int.parse).toList();
  //     List<int> v2Components = v2.split('.').map(int.parse).toList();

  //     int maxLength = v1Components.length > v2Components.length
  //         ? v1Components.length
  //         : v2Components.length;

  //     for (int i = 0; i < maxLength; i++) {
  //       int v1c = i < v1Components.length ? v1Components[i] : 0;
  //       int v2c = i < v2Components.length ? v2Components[i] : 0;
  //       if (v1c > v2c) return true;
  //       if (v1c < v2c) return false;
  //     }
  //   } catch (e) {
  //     log("Error comparing versions: $e", name: "AppUpdateService");
  //   }
  //   return false;
  // }
}
