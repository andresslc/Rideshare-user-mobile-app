import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/params/ride_history_detail_params.dart';
import '../enitities/ride_history_detail_entities.dart';
import '../repositories/ride_history_repository.dart';

class RideHistoryDetailUsecase {
  final RideHistoryRepository _repository;

  RideHistoryDetailUsecase(this._repository);

  Future<Either<Failure, RideDetailResponseEntity>> call({
    required RideHistoryDetailParams params,
  }) async {
    return _repository.getRideDetail(params: params);
  }
}
