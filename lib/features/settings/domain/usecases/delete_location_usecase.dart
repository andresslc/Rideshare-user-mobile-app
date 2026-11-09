import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/settings/domain/repositories/saved_locations_repository.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

class DeleteLocationUseCase {
  final SavedLocationsRepository _repository;

  DeleteLocationUseCase(this._repository);

  Future<Either<Failure, ApiResponse>> call(String locationId) {
    return _repository.deleteLocation(locationId);
  }
}

