import 'package:fpdart/fpdart.dart';
import 'package:ride_app/features/auth/domain/repositories/auth_repositories.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_entity.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/auth_params.dart';

class CreateProfileUseCase {
  final AuthRepository repository;

  CreateProfileUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(CreateProfileParams params) async {
    return repository.createProfile(params: params);
  }
}
