import 'package:fpdart/fpdart.dart';
import 'package:ride_app/features/auth/domain/repositories/auth_repositories.dart';
import 'package:ride_app/features/user_profile/data/models/user_model.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/auth_params.dart';

class CreateProfileUseCase {
  final AuthRepository repository;

  CreateProfileUseCase(this.repository);

  Future<Either<Failure, UserModel>> call(CreateProfileParams params) async {
    return repository.createProfile(params: params);
  }
}
