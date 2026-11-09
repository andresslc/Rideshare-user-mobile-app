import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/settings/domain/repositories/saved_locations_repository.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

class ReorderSavedLocationsUseCase {
  final SavedLocationsRepository _repository;

  ReorderSavedLocationsUseCase(this._repository);

  Future<Either<Failure, ApiResponse>> call(List<String> locationIds) {
    return _repository.reorderSavedLocations(locationIds);
  }
}

