import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_history/domain/repositories/ride_history_repository.dart';

import '../../../../core/params/carpool_detail_params.dart';
import '../enitities/carpool_history_detail_entities.dart';

class CarpoolHistoryDetailUsecase {
  final RideHistoryRepository _repository;

  CarpoolHistoryDetailUsecase(this._repository);

  Future<Either<Failure, CarpoolEntity>> call({
    required CarpoolDetailParams params,
  }) async {
    return _repository.getCarpoolDetail(params: params);
  }
}
