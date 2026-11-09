import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/carpool_param.dart';
import '../enitities/carpool_history_entities.dart';
import '../repositories/ride_history_repository.dart';

class GetCarpoolUseCase {
  final RideHistoryRepository _repository;

  GetCarpoolUseCase(this._repository);

  Future<Either<Failure, CarpoolHistoryEntity>> call({
    required CarpoolParam params,
  }) async {
    return _repository.getCarpoolHistory(params: params);
  }
}
