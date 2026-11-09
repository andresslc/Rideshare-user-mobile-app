import 'package:ride_app/features/auth/data/session/auth_session_manager.dart';
import 'package:ride_app/features/user_profile/data/datasources/user_profile_datasource.dart';
import 'package:ride_app/features/user_profile/data/repositories/user_profile_repository_impl.dart';
import 'package:ride_app/features/user_profile/domain/repositories/user_repositories.dart';
import 'package:ride_app/features/user_profile/domain/usecase/update_profile_usecase.dart';
import 'package:ride_app/features/user_profile/domain/usecase/user_profile_usecase.dart';

import '../service_locator.dart';

/// Registers auth feature dependencies.
void registerUserProfileModule() {
  // Data source
  locator.registerLazySingleton<UserProfileDatasource>(
    () => UserProfileDatasourceImpl(),
  );

  // // Repository
  locator.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(
      locator<UserProfileDatasource>(),
      locator<AuthSessionManager>(),
    ),
  );

  // // Use cases
  locator.registerLazySingleton(
    () => UserProfileUseCase(locator<UserProfileRepository>()),
  );
  locator.registerLazySingleton(
    () => UpdateProfileUseCase(locator<UserProfileRepository>()),
  );
}
