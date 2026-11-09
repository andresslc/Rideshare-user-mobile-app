import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/ride_history_param.dart';
import '../enitities/ride_history_entites.dart';
import '../repositories/ride_history_repository.dart';

class GetRideHistoryUseCase {
  final RideHistoryRepository _repository;

  GetRideHistoryUseCase(this._repository);

  Future<Either<Failure, RideHistoryResponseEntity>> call({
    required RideHistoryRequestParams params,
  }) async {
    return _repository.getRideHistory(params: params);
  }
}
