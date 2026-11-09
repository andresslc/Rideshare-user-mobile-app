import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/features/settings/data/datasources/saved_locations_remote_data_source.dart';
import 'package:ride_app/features/settings/data/repositories/saved_locations_repository_impl.dart';
import 'package:ride_app/features/settings/domain/repositories/saved_locations_repository.dart';
import 'package:ride_app/features/settings/domain/usecases/delete_location_usecase.dart';
import 'package:ride_app/features/settings/domain/usecases/get_saved_locations_usecase.dart';
import 'package:ride_app/features/settings/domain/usecases/reorder_saved_locations_usecase.dart';
import 'package:ride_app/features/settings/domain/usecases/save_location_usecase.dart';
import 'package:ride_app/features/settings/domain/usecases/update_location_usecase.dart';

void registerSettingsModule() {
  locator.registerLazySingleton<SavedLocationsRemoteDataSource>(
    () => SavedLocationsRemoteDataSourceImpl(),
  );

  locator.registerLazySingleton<SavedLocationsRepository>(
    () =>
        SavedLocationsRepositoryImpl(locator<SavedLocationsRemoteDataSource>()),
  );

  locator.registerLazySingleton(
    () => GetSavedLocationsUseCase(locator<SavedLocationsRepository>()),
  );
  locator.registerLazySingleton(
    () => SaveLocationUseCase(locator<SavedLocationsRepository>()),
  );
  locator.registerLazySingleton(
    () => UpdateLocationUseCase(locator<SavedLocationsRepository>()),
  );
  locator.registerLazySingleton(
    () => DeleteLocationUseCase(locator<SavedLocationsRepository>()),
  );
  locator.registerLazySingleton(
    () => ReorderSavedLocationsUseCase(locator<SavedLocationsRepository>()),
  );
}
