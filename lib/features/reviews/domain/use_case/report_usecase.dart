
import '../../../../core/params/report_params.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/feed_back_repository.dart';

class ReportUsecase {
  final FeedBackRepository _repository;

  ReportUsecase(this._repository);

  FutureEither<String> call(ReportParam params) async {
    return _repository.report(params: params);
  }
}
