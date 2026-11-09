import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/location_params.dart';
import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

abstract class SavedLocationsRepository {
  Future<Either<Failure, (List<SavedLocationEntity>, Pagination?)>>
      getSavedLocations({int page, int limit});

  Future<Either<Failure, SavedLocationEntity>> saveLocation(
    SaveLocationParams params,
  );

  Future<Either<Failure, SavedLocationEntity>> updateLocation(
    String locationId,
    SaveLocationParams params,
  );

  Future<Either<Failure, ApiResponse>> deleteLocation(String locationId);

  Future<Either<Failure, ApiResponse>> reorderSavedLocations(
    List<String> locationIds,
  );
}

