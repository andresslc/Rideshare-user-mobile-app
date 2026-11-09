import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_profile_entity.dart';
import 'package:ride_app/features/user_profile/domain/repositories/user_repositories.dart';
import '../../../../core/errors/failure.dart';

class UpdateProfileUseCase {
  final UserProfileRepository repository;
  UpdateProfileUseCase(this.repository);
  Future<Either<Failure, UserProfileEntity>> call(UpdateProfileParams params) async {
    return repository.updateProfile(params: params);
  }
}

