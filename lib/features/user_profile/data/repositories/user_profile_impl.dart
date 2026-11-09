import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/user_profile/data/datasources/user_profile_datasource.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_profile_entity.dart';
import 'package:ride_app/features/user_profile/domain/repositories/user_repositories.dart';

import '../../../../core/errors/failure.dart';

abstract class UserProfileRepositoryInternal implements UserProfileRepository {}

class UserProfileRepositoryImpl implements UserProfileRepositoryInternal {
  final dataSource = UserProfileDatasourceImpl();

  UserProfileRepositoryImpl(UserProfileDatasource profileDatasource);
  @override
  Future<Either<Failure, UserProfileEntity>> getProfile() async {
    final response = await dataSource.getProfile();
    return response.fold(
      (left) => Left(ServerFailure(message: left.message)),
      (right) => Right(right),
    );
  }

  @override
  Future<Either<Failure, UserProfileEntity>> updateProfile({
    required UpdateProfileParams params,
  }) async {
    final updateProfileResponse = await dataSource.updateProfile(params);
    return updateProfileResponse.fold(
      (left) => Left(ServerFailure(message: left.message)),
      (right) => Right(right),
    );
  }
}

