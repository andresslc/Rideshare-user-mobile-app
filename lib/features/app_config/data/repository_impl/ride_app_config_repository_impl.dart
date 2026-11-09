import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/app_config/data/datasources/ride_app_config_local_data_source.dart';
import 'package:ride_app/features/app_config/data/datasources/ride_app_config_remote_data_source.dart';
import 'package:ride_app/features/app_config/data/models/ride_app_config_model.dart';
import 'package:ride_app/features/app_config/domain/entities/ride_app_config_entity.dart';
import 'package:ride_app/features/app_config/domain/repositories/ride_app_config_repository.dart';

class RideAppConfigRepositoryImpl implements RideAppConfigRepository {
  final RideAppConfigRemoteDataSource remoteDataSource;
  final RideAppConfigLocalDataSource localDataSource;

  RideAppConfigRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, RideAppConfigEntity>> getRideAppConfig({
    required String locale,
  }) async {
    final result = await remoteDataSource.fetch(locale: locale);

    final RideAppConfigModel? fetched = result.toNullable();
    if (fetched != null) {
      await localDataSource.write(fetched);
      return Right(fetched);
    }

    // A backend that is down must not blank the search screen: serve the last
    // configuration instead, and only report the failure when there is nothing
    // cached to fall back to.
    final RideAppConfigModel? cachedConfig = localDataSource.read();
    if (cachedConfig != null) return Right(cachedConfig);

    return Left(
      result.getLeft().getOrElse(
        () => const NetworkFailure(message: 'Ride configuration unavailable.'),
      ),
    );
  }

  @override
  RideAppConfigEntity? cached() => localDataSource.read();
}
