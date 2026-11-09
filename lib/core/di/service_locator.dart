import 'package:get_it/get_it.dart';
import 'package:ride_app/core/config/app_config.dart';
import 'package:ride_app/core/di/modules/app_config_module.dart';
import 'package:ride_app/core/di/modules/card_module.dart';
import 'package:ride_app/core/di/modules/change_language_module.dart';
import 'package:ride_app/core/di/modules/chat_module.dart';
import 'package:ride_app/core/di/modules/feedback_module.dart';
import 'package:ride_app/core/di/modules/notification_module.dart';
import 'package:ride_app/core/di/modules/ride_room_module.dart';
import 'package:ride_app/core/di/modules/settings_module.dart';
import 'package:ride_app/core/di/modules/user_profile_module.dart';
import 'package:ride_app/core/services/device_info_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/image_service.dart';
import '../services/notification_route_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import 'modules/auth_module.dart';
import 'modules/core_module.dart';
import 'modules/ride_history_module.dart';
import 'modules/wallet_module.dart';

/// Global service-locator instance.
final GetIt locator = GetIt.instance;

/// Initialise all dependency injection modules.
///
/// Call this once in `main()` before running the app.
Future<void> setupLocator() async {
  // ── Async singletons ──────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(prefs);
  locator.registerLazySingleton(() => ImageService());
  locator.registerLazySingleton(() => NotificationServices());
  locator.registerLazySingleton(() => NotificationRouteService());
  locator.registerLazySingleton(() => SoundService());
  locator.registerSingleton(DeviceInfoService());

  // ── Core services ─────────────────────
  // ────────────────────────────────
  registerCoreModule();
  registerObservabilityModule();

  // ── Feature modules ───────────────────────────────────────────────────
  registerAuthModule();
  registerUserProfileModule();
  registerCardModule();
  registerWalletModule();
  registerNotificationModule();
  registerSettingsModule();
  registerRideRoomModule();
  registerChatModule();
  registerLanguageModule();
  registerFeedBackModule();
  registerRideHistoryModule();
  registerAppConfigModule();
}

Future<void> setup(AppConfig config) async {
  locator.registerSingleton<AppConfig>(config);
}
