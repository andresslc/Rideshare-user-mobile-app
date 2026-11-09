import 'package:fpdart/fpdart.dart';
import 'package:ride_app/features/auth/domain/repositories/auth_repositories.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/params/auth_params.dart';

class SendOtpUseCase {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  Future<Either<Failure, String>> call(SendOtpParams params) async {
    return repository.login(params: params);
  }
}

