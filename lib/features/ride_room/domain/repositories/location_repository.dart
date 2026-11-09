import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';

abstract class LocationRepository {
  Future<List<LocationEntity>> getRecentLocations();

  Future<void> saveRecentLocation(LocationEntity location);

  Future<List<LocationEntity>> getPopularLocations(LatLng currentLocation);
}
