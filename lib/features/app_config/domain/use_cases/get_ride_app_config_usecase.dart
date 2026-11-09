import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/app_config/domain/entities/ride_app_config_entity.dart';
import 'package:ride_app/features/app_config/domain/repositories/ride_app_config_repository.dart';

class GetRideAppConfigUseCase {
  final RideAppConfigRepository repository;

  GetRideAppConfigUseCase(this.repository);

  Future<Either<Failure, RideAppConfigEntity>> call({required String locale}) {
    return repository.getRideAppConfig(locale: locale);
  }

  RideAppConfigEntity? cached() => repository.cached();
}
