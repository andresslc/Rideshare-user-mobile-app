import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/location_params.dart';
import 'package:ride_app/features/settings/data/datasources/saved_locations_remote_data_source.dart';
import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';
import 'package:ride_app/features/settings/domain/repositories/saved_locations_repository.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

class SavedLocationsRepositoryImpl implements SavedLocationsRepository {
  final SavedLocationsRemoteDataSource _remoteDataSource;

  SavedLocationsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, (List<SavedLocationEntity>, Pagination?)>>
      getSavedLocations({int page = 1, int limit = 50}) async {
    return _remoteDataSource.getSavedLocations(page: page, limit: limit);
  }

  @override
  Future<Either<Failure, SavedLocationEntity>> saveLocation(
    SaveLocationParams params,
  ) async {
    return _remoteDataSource.saveLocation(params);
  }

  @override
  Future<Either<Failure, SavedLocationEntity>> updateLocation(
    String locationId,
    SaveLocationParams params,
  ) async {
    return _remoteDataSource.updateLocation(locationId, params);
  }

  @override
  Future<Either<Failure, ApiResponse>> deleteLocation(String locationId) async {
    return _remoteDataSource.deleteLocation(locationId);
  }

  @override
  Future<Either<Failure, ApiResponse>> reorderSavedLocations(
    List<String> locationIds,
  ) async {
    return _remoteDataSource.reorderSavedLocations(locationIds);
  }
}

