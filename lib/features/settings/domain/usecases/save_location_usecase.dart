import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/location_params.dart';
import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';
import 'package:ride_app/features/settings/domain/repositories/saved_locations_repository.dart';

class SaveLocationUseCase {
  final SavedLocationsRepository _repository;

  SaveLocationUseCase(this._repository);

  Future<Either<Failure, SavedLocationEntity>> call(SaveLocationParams params) {
    return _repository.saveLocation(params);
  }
}

