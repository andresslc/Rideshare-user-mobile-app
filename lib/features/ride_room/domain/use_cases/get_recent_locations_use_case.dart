import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/location_repository.dart';

class GetRecentLocationsUseCase {
  final LocationRepository _repository;

  GetRecentLocationsUseCase(this._repository);

  Future<List<LocationEntity>> call() {
    return _repository.getRecentLocations();
  }
}
