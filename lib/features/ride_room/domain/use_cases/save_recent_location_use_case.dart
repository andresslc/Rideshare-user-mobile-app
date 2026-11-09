import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/location_repository.dart';

class SaveRecentLocationUseCase {
  final LocationRepository _repository;

  SaveRecentLocationUseCase(this._repository);

  Future<void> call(LocationEntity location) {
    return _repository.saveRecentLocation(location);
  }
}
