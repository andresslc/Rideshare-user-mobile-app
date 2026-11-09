import 'package:fpdart/fpdart.dart';
import 'package:ride_app/features/user_profile/domain/entites/user_profile_entity.dart';
import 'package:ride_app/features/user_profile/domain/repositories/user_repositories.dart';
import '../../../../core/errors/failure.dart';

class UserProfileUseCase {
  final UserProfileRepository repository;
  UserProfileUseCase(this.repository);
  Future<Either<Failure, UserProfileEntity>> call() async {
    return repository.getProfile();
  }
}

