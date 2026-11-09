import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/features/ride_room/data/datasources/location_local_data_source.dart';
import 'package:ride_app/features/ride_room/data/models/location_model.dart';
import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationLocalDataSource _localDataSource;

  LocationRepositoryImpl(this._localDataSource);

  @override
  Future<List<LocationEntity>> getRecentLocations() async {
    final models = await _localDataSource.getRecentLocations();
    return List<LocationEntity>.from(models);
  }

  @override
  Future<void> saveRecentLocation(LocationEntity location) async {
    await _localDataSource.saveRecentLocation(
      LocationModel.fromEntity(location),
    );
  }

  @override
  Future<List<LocationEntity>> getPopularLocations(
    LatLng currentLocation,
  ) async {
    final now = DateTime.now();
    final baseLat = currentLocation.latitude;
    final baseLng = currentLocation.longitude;

    return <LocationEntity>[
      LocationModel(
        id: 'popular-airport',
        name: 'Nearest Airport',
        address: 'Airport terminal near you',
        latitude: baseLat + 0.032,
        longitude: baseLng - 0.018,
        type: RideLocationType.dropoff,
        timestamp: now,
      ),
      LocationModel(
        id: 'popular-station',
        name: 'Central Station',
        address: 'Main transit station nearby',
        latitude: baseLat - 0.021,
        longitude: baseLng + 0.014,
        type: RideLocationType.dropoff,
        timestamp: now.subtract(const Duration(minutes: 1)),
      ),
      LocationModel(
        id: 'popular-mall',
        name: 'City Mall',
        address: 'Popular shopping destination',
        latitude: baseLat + 0.017,
        longitude: baseLng + 0.019,
        type: RideLocationType.dropoff,
        timestamp: now.subtract(const Duration(minutes: 2)),
      ),
      LocationModel(
        id: 'popular-downtown',
        name: 'Downtown',
        address: 'City center hotspot',
        latitude: baseLat - 0.012,
        longitude: baseLng - 0.013,
        type: RideLocationType.dropoff,
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
    ];
  }
}
