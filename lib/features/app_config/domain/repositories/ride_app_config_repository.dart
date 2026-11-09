import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/app_config/domain/entities/ride_app_config_entity.dart';

abstract class RideAppConfigRepository {
  /// Fetches the configuration and caches it. On failure returns the cached
  /// one when there is any, so the caller still has something to render.
  Future<Either<Failure, RideAppConfigEntity>> getRideAppConfig({
    required String locale,
  });

  /// The last configuration served, without touching the network.
  RideAppConfigEntity? cached();
}
