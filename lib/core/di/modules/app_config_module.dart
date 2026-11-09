import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/features/app_config/data/datasources/ride_app_config_local_data_source.dart';
import 'package:ride_app/features/app_config/data/datasources/ride_app_config_remote_data_source.dart';
import 'package:ride_app/features/app_config/data/repository_impl/ride_app_config_repository_impl.dart';
import 'package:ride_app/features/app_config/domain/repositories/ride_app_config_repository.dart';
import 'package:ride_app/features/app_config/domain/use_cases/get_ride_app_config_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerAppConfigModule() {
  locator.registerLazySingleton<RideAppConfigRemoteDataSource>(
    () => RideAppConfigRemoteDataSourceImpl(),
  );

  locator.registerLazySingleton<RideAppConfigLocalDataSource>(
    () => RideAppConfigLocalDataSourceImpl(prefs: locator<SharedPreferences>()),
  );

  locator.registerLazySingleton<RideAppConfigRepository>(
    () => RideAppConfigRepositoryImpl(
      remoteDataSource: locator<RideAppConfigRemoteDataSource>(),
      localDataSource: locator<RideAppConfigLocalDataSource>(),
    ),
  );

  locator.registerLazySingleton(
    () => GetRideAppConfigUseCase(locator<RideAppConfigRepository>()),
  );
}
