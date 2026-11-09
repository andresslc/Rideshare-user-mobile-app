import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/auth/data/session/auth_session_manager.dart';
import 'package:ride_app/features/user_profile/data/datasources/user_profile_datasource.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_profile_entity.dart';
import 'package:ride_app/features/user_profile/domain/repositories/user_repositories.dart';

import '../../../../core/errors/failure.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileDatasource dataSource;
  final AuthSessionManager sessionManager;

  const UserProfileRepositoryImpl(this.dataSource, this.sessionManager);

  @override
  Future<Either<Failure, UserProfileEntity>> getProfile() async {
    final response = await dataSource.getProfile();

    return await response.fold((failure) async {
      return Left(ServerFailure(message: failure.message));
    }, (model) async {
      final entity = model;
      await sessionManager.persistProfile(entity.user);
      return Right(entity);
    });
  }

  @override
  Future<Either<Failure, UserProfileEntity>> updateProfile({
    required UpdateProfileParams params,
  }) async {
    final response = await dataSource.updateProfile(params);

    return await response.fold((failure) async {
      return Left(ServerFailure(message: failure.message));
    }, (model) async {
      final entity = model;
      await sessionManager.persistProfile(entity.user);
      return Right(entity);
    });
  }
}
