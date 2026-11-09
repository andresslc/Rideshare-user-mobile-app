import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_profile_entity.dart';
import '../../../../core/errors/failure.dart';

abstract class UserProfileRepository {
  Future<Either<Failure, UserProfileEntity>> getProfile();
  Future<Either<Failure, UserProfileEntity>> updateProfile({
    required UpdateProfileParams params,
  });
}

