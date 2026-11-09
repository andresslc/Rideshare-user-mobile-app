import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/location_repository.dart';

class GetPopularLocationsUseCase {
  final LocationRepository _repository;

  GetPopularLocationsUseCase(this._repository);

  Future<List<LocationEntity>> call(LatLng currentLocation) {
    return _repository.getPopularLocations(currentLocation);
  }
}
