import 'package:ride_app/features/auth/data/datasources/auth_datasources.dart';
import 'package:ride_app/features/auth/data/repositories/auth_repositories_impl.dart';
import 'package:ride_app/features/auth/domain/repositories/auth_repositories.dart';
import 'package:ride_app/features/auth/domain/use_cases/create_profile_usecase.dart.dart';
import 'package:ride_app/features/auth/domain/use_cases/delete_account_usecase.dart';
import 'package:ride_app/features/auth/domain/use_cases/logout_usecase.dart';
import 'package:ride_app/features/auth/domain/use_cases/send_otp_usecase.dart';
import 'package:ride_app/features/auth/domain/use_cases/verify_otp_usecase.dart';

import '../service_locator.dart';

/// Registers auth feature dependencies.
void registerAuthModule() {
  // Data source
  locator.registerLazySingleton<AuthDatasource>(() => AuthDatasourceImpl());

  // // Repository
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(locator<AuthDatasource>()),
  );

  // // Use cases
  locator.registerLazySingleton(
    () => SendOtpUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(
    () => CreateProfileUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(
    () => VerifyOtpUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(
    () => DeleteAccountUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(() => LogoutUseCase(locator<AuthRepository>()));
}
