import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/location_params.dart';
import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';
import 'package:ride_app/features/settings/domain/repositories/saved_locations_repository.dart';

class UpdateLocationUseCase {
  final SavedLocationsRepository _repository;

  UpdateLocationUseCase(this._repository);

  Future<Either<Failure, SavedLocationEntity>> call(
    String locationId,
    SaveLocationParams params,
  ) {
    return _repository.updateLocation(locationId, params);
  }
}

