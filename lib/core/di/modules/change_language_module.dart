import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/features/settings/data/datasources/change_language_datasource.dart';
import 'package:ride_app/features/settings/data/repositories/change_language_repositories_impl.dart';
import 'package:ride_app/features/settings/domain/repositories/change_language_reposiotry.dart';
import 'package:ride_app/features/settings/domain/usecases/change_language_usecase.dart';

void registerLanguageModule() {
  locator.registerLazySingleton<ChangeLanguageDatasource>(
    () => ChangeLanguageDatasourceImpl(),
  );
  locator.registerLazySingleton<ChangeLanguageRepository>(
    () => ChangeLanguageRepositoryImpl(locator<ChangeLanguageDatasource>()),
  );

  locator.registerLazySingleton(
    () => ChangeLanguageUseCase(locator<ChangeLanguageRepository>()),
  );
}
