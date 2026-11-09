import 'dart:async';
import 'dart:developer';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'remote_config_model.dart';

/// Service class to interact with Firebase Remote Config.
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  final void Function(RemoteConfigModel config)? onConfigChanged;

  RemoteConfigService(this._remoteConfig, {this.onConfigChanged});

  /// Initialize Remote Config, fetch values, and start listening for updates.
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 12),
        ),
      );

      await _remoteConfig.setDefaults({'app_config': '{}'});

      // Attempt initial fetch — if offline this silently fails
      try {
        await _remoteConfig.fetchAndActivate();
        debugPrint('✅ Remote Config: initial fetch succeeded');
      } catch (e) {
        debugPrint('⚠️ Remote Config: initial fetch failed (offline?): $e');
      }

      // Push whatever we have (fetched values or defaults) to consumers
      _applyConfig();

      // Listen for real-time updates (fires when device comes online / values change)
      _remoteConfig.onConfigUpdated.listen(
        (event) async {
          debugPrint('🔄 Remote Config updated in background');
          await _remoteConfig.activate();
          _applyConfig();
        },
        onError: (error) {
          debugPrint('❌ Remote Config listener error: $error');
        },
      );

      debugPrint('🔧 Remote Config initialized');
    } catch (e) {
      debugPrint('❌ Remote Config init error: $e');
      // Still apply defaults so the app can function
      _applyConfig();
    }
  }

  /// Manually fetch and activate new values.
  Future<bool> fetchAndActivate() async {
    try {
      final activated = await _remoteConfig.fetchAndActivate();
      debugPrint(
        activated
            ? '✅ Remote Config fetched & activated'
            : 'ℹ️ Remote Config fetched (no changes)',
      );
      _applyConfig();
      return activated;
    } catch (e) {
      debugPrint('❌ Remote Config fetch error: $e');
      return false;
    }
  }

  /// Build model from current Remote Config values and notify consumer.
  void _applyConfig() {
    final config = _buildConfig();
    debugPrint('Config applied: baseUrl=${config.baseUrlDev}');
    log('Config applied: ${config.toString()}');
    onConfigChanged?.call(config);
  }

  /// Synchronously build [RemoteConfigModel] from current cached values.
  RemoteConfigModel _buildConfig() {
    try {
      return RemoteConfigModel.fromConfigString(
        _remoteConfig.getString('app_config'),
      );
    } catch (_) {
      return RemoteConfigModel.defaults();
    }
  }

  void dispose() {
    // nothing to clean up — stream listeners are GC'd with this instance
  }
}
