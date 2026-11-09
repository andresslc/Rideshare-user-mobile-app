import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/settings/domain/repositories/change_language_reposiotry.dart';

class ChangeLanguageUseCase {
  final ChangeLanguageRepository repository;

  ChangeLanguageUseCase(this.repository);

  Future<Either<Failure, String>> call(String languageCode) async {
    return repository.changeLanguage(languageCode: languageCode);
  }
}

