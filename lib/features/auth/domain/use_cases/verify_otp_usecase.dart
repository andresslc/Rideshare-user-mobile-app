import 'package:fpdart/fpdart.dart';
import 'package:ride_app/features/auth/domain/entities/auth_entity.dart';
import 'package:ride_app/features/auth/domain/repositories/auth_repositories.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/params/auth_params.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<Either<Failure, AuthResponseEntity>> call(VerifyOtpParams params) async {
    return repository.verifyOtp(params: params);
  }
}

