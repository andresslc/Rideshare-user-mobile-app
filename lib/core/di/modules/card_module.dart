import 'package:ride_app/features/card/data/datasources/card_datascource.dart';
import 'package:ride_app/features/card/data/repositories/card_repositories_impl.dart';
import 'package:ride_app/features/card/domain/repositories/card_repositories.dart';
import 'package:ride_app/features/card/domain/usecase/add_card_usecase.dart';
import 'package:ride_app/features/card/domain/usecase/delete_card_usecase.dart';
import 'package:ride_app/features/card/domain/usecase/get_card_usecase.dart';
import 'package:ride_app/features/card/domain/usecase/set_default_card_usecase.dart';

import '../service_locator.dart';

/// Registers auth feature dependencies.
void registerCardModule() {
  // Data source
  locator.registerLazySingleton<CardDatasource>(() => CardDatasourceImpl());

  // // Repository
  locator.registerLazySingleton<CardRepository>(
    () => CardRepositoryImpl(locator<CardDatasource>()),
  );

  // // Use cases
  locator.registerLazySingleton(
    () => AddCardUsecase(locator<CardRepository>()),
  );
  locator.registerLazySingleton(
    () => CardListUsecase(locator<CardRepository>()),
  );
  locator.registerLazySingleton(
    () => DeleteCardUsecase(locator<CardRepository>()),
  );
  locator.registerLazySingleton(
    () => SetDefaultCardUsecase(locator<CardRepository>()),
  );
}
