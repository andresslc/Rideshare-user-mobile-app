import 'dart:convert';

import 'package:ride_app/core/utils/app_log.dart';
import 'package:ride_app/features/app_config/data/models/ride_app_config_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the last configuration the backend served.
///
/// The search screen has to render even when the request fails, so the app
/// falls back to this before falling back to its own strings.
abstract class RideAppConfigLocalDataSource {
  RideAppConfigModel? read();
  Future<void> write(RideAppConfigModel config);
}

class RideAppConfigLocalDataSourceImpl implements RideAppConfigLocalDataSource {
  static const String _key = 'ride_app_config';

  final SharedPreferences prefs;

  RideAppConfigLocalDataSourceImpl({required this.prefs});

  @override
  RideAppConfigModel? read() {
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return RideAppConfigModel.fromJson(decoded);
      }
      if (decoded is Map) {
        return RideAppConfigModel.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      // A cache we cannot read is no worse than no cache at all.
      log('cached ride config is unreadable: $e', name: 'ride config');
    }
    return null;
  }

  @override
  Future<void> write(RideAppConfigModel config) async {
    try {
      await prefs.setString(_key, jsonEncode(config.toJson()));
    } catch (e) {
      log('could not cache ride config: $e', name: 'ride config');
    }
  }
}
