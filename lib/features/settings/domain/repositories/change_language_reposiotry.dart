import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';

abstract class ChangeLanguageRepository {
  Future<Either<Failure, String>> changeLanguage({
    required String languageCode,
  });
}

