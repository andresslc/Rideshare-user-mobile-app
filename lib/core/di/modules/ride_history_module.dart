import 'package:ride_app/core/di/service_locator.dart';

import '../../../features/ride_history/data/datasources/ride _history_datasource.dart';
import '../../../features/ride_history/data/repositories/ride_history_repository_impl.dart';
import '../../../features/ride_history/domain/repositories/ride_history_repository.dart';
import '../../../features/ride_history/domain/use_case/carpool_history_detail_usecase.dart';
import '../../../features/ride_history/domain/use_case/carpool_history_usecase.dart';
import '../../../features/ride_history/domain/use_case/ride_history_detail_usecase.dart';
import '../../../features/ride_history/domain/use_case/ride_history_usecase.dart';
import '../../services/api_service.dart';

void registerRideHistoryModule() {
  // 🔹 Remote Data Source
  locator.registerLazySingleton<RideHistoryRemoteDataSource>(
    () => RideHistoryRemoteDataSourceImpl(locator<ApiService>()),
  );

  // 🔹 Repository
  locator.registerLazySingleton<RideHistoryRepository>(
    () => RideHistoryRepositoryImpl(locator<RideHistoryRemoteDataSource>()),
  );

  // 🔹 UseCase
  locator.registerLazySingleton(
    () => GetRideHistoryUseCase(locator<RideHistoryRepository>()),
  );

  locator.registerLazySingleton(
    () => RideHistoryDetailUsecase(locator<RideHistoryRepository>()),
  );

  locator.registerLazySingleton(
    () => GetCarpoolUseCase(locator<RideHistoryRepository>()),
  );

  locator.registerLazySingleton(
    () => CarpoolHistoryDetailUsecase(locator<RideHistoryRepository>()),
  );
}
