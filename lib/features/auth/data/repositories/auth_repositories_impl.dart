import 'package:fpdart/fpdart.dart';
import 'package:ride_app/features/auth/domain/entities/auth_entity.dart';
import 'package:ride_app/features/user_profile/data/models/user_model.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/auth_params.dart';
import '../../domain/repositories/auth_repositories.dart';
import '../datasources/auth_datasources.dart';

/// Internal repository abstraction
abstract class AuthRepositoryInternal implements AuthRepository {}

/// =======================================
/// IMPLEMENTATION
/// =======================================
class AuthRepositoryImpl implements AuthRepositoryInternal {
  final AuthDatasource dataSource;

  const AuthRepositoryImpl(this.dataSource);

  /// ---------------------------------
  /// LOGIN
  /// ---------------------------------
  @override
  Future<Either<Failure, UserModel>> createProfile({
    required CreateProfileParams params,
  }) async {
    final response = await dataSource.createProfile(params);

    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (user) => Right(user),
    );
  }

  /// ---------------------------------
  /// CREATE PROFILE (SIGNUP)
  /// ---------------------------------
  @override
  Future<Either<Failure, String>> login({required SendOtpParams params}) async {
    final response = await dataSource.sendOtp(params);

    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (message) => Right(message),
    );
  }

  /// ---------------------------------
  /// VERIFY OTP
  /// ---------------------------------
  @override
  Future<Either<Failure, AuthResponseEntity>> verifyOtp({
    required VerifyOtpParams params,
  }) async {
    final response = await dataSource.verifyOtp(params);

    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (authResponse) => Right(authResponse),
    );
  }

  @override
  Future<Either<Failure, String>> logout() async {
    final response = await dataSource.logout();
    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (message) => Right(message),
    );
  }

  @override
  Future<Either<Failure, bool>> deleteAccount(String otp) async {
    final response = await dataSource.deleteAccount(otp);
    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (success) => Right(success),
    );
  }
}
