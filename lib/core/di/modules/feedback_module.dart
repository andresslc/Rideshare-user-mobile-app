import 'package:ride_app/core/di/service_locator.dart';

import '../../../features/reviews/data/datasources/feed_back_datasource.dart';
import '../../../features/reviews/data/repositories/feed_back_repository_impl.dart';
import '../../../features/reviews/domain/repositories/feed_back_repository.dart';
import '../../../features/reviews/domain/use_case/feedback_usecase.dart';
import '../../../features/reviews/domain/use_case/get_review_usecase.dart';
import '../../../features/reviews/domain/use_case/report_usecase.dart';
import '../../services/api_service.dart';

void registerFeedBackModule() {
  locator.registerLazySingleton<FeedbackRemoteDataSource>(
    () => FeedbackRemoteDataSourceImpl(locator<ApiService>()),
  );
  locator.registerLazySingleton<FeedBackRepository>(
    () => FeedBackRepositoryImpl(locator<FeedbackRemoteDataSource>()),
  );

  locator.registerLazySingleton(
    () => FeedBackUseCase(locator<FeedBackRepository>()),
  );
  locator.registerLazySingleton(
    () => GetReviewUsecase(locator<FeedBackRepository>()),
  );
  locator.registerLazySingleton(
    () => ReportUsecase(locator<FeedBackRepository>()),
  );
}
