import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';
import 'package:ride_app/features/settings/domain/repositories/saved_locations_repository.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

class GetSavedLocationsUseCase {
  final SavedLocationsRepository _repository;

  GetSavedLocationsUseCase(this._repository);

  Future<Either<Failure, (List<SavedLocationEntity>, Pagination?)>> call({
    int page = 1,
    int limit = 50,
  }) {
    return _repository.getSavedLocations(page: page, limit: limit);
  }
}

