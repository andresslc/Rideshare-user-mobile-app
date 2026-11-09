
import '../../../../core/params/feedback_params.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/feed_back_repository.dart';

class FeedBackUseCase {
  final FeedBackRepository _repository;

  FeedBackUseCase(this._repository);

  FutureEither<String> call(FeedbackParam params) async {
    return _repository.feedback(params: params);
  }
}
