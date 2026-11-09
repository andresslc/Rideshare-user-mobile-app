import 'package:fpdart/fpdart.dart';
import 'package:ride_app/features/settings/data/datasources/change_language_datasource.dart';
import 'package:ride_app/features/settings/domain/repositories/change_language_reposiotry.dart';
import '../../../../core/errors/failure.dart';

class ChangeLanguageRepositoryImpl implements ChangeLanguageRepository {
  final ChangeLanguageDatasource dataSource;

  const ChangeLanguageRepositoryImpl(this.dataSource);

  /// ---------------------------------
  /// CHANGE LANGUAGE
  /// ---------------------------------
  @override
  Future<Either<Failure, String>> changeLanguage({
    required String languageCode,
  }) async {
    final response = await dataSource.changeLanguage(languageCode);

    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (message) => Right(message),
    );
  }
}

