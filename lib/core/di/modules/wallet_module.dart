import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:ride_app/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:ride_app/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:ride_app/features/wallet/domain/use_cases/add_funds_usecase.dart';
import 'package:ride_app/features/wallet/domain/use_cases/get_cards_usecase.dart';
import 'package:ride_app/features/wallet/domain/use_cases/get_transaction_history_usecase.dart';

void registerWalletModule() {
  locator.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(),
  );

  locator.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(locator<WalletRemoteDataSource>()),
  );

  // Use cases
  locator.registerLazySingleton(
    () => GetTransactionHistoryUseCase(locator<WalletRepository>()),
  );
  locator.registerLazySingleton(
    () => AddFundsUseCase(locator<WalletRepository>()),
  );
  locator.registerLazySingleton(
    () => GetCardsUseCase(locator<WalletRepository>()),
  );
}
