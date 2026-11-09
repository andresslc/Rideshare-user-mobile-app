import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repositories.dart';

class DeleteAccountUseCase {
  final AuthRepository repository;
  DeleteAccountUseCase(this.repository);

  Future<Either<Failure, bool>> call(String otp) => repository.deleteAccount(otp);
}
