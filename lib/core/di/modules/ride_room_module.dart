import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/core/services/socket_service.dart';
import 'package:ride_app/features/ride_room/data/datasources/carpool_ride_data_source.dart';
import 'package:ride_app/features/ride_room/data/datasources/location_local_data_source.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_details_remote_data_source.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_fare_remote_data_source.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_socket_datasource.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_socket_listener.dart';
import 'package:ride_app/features/ride_room/data/repository_impl/carpool_ride_repository_impl.dart';
import 'package:ride_app/features/ride_room/data/repository_impl/location_repository_impl.dart';
import 'package:ride_app/features/ride_room/data/repository_impl/ride_fare_repository_impl.dart';
import 'package:ride_app/features/ride_room/data/repository_impl/ride_socket_repository_impl.dart';
import 'package:ride_app/features/ride_room/domain/repositories/carpool_ride_repository.dart';
import 'package:ride_app/features/ride_room/domain/repositories/location_repository.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_fare_repository.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/apply_promo_code_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/calculate_fare_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/cancel_carpool_ride_request_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/cancel_ride_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_booking_status_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_passenger_picked_up_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_payment_verification_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_resume_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_ride_completed_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_ride_started_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_route_update_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_stop_arrived_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/complete_carpool_ride_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/connect_ride_socket_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/disconnect_ride_socket_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/driver_location_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/find_carpool_rides_by_api_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/find_carpool_rides_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/find_ride_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_carpool_ride_by_id_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_carpool_ride_url_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_popular_locations_use_case.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_recent_locations_use_case.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_ride_by_id_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/join_carpool_ride_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_resume_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_search_exhausted_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_search_status_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_status_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_upgrade_usecases.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/save_recent_location_use_case.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/socket_errors_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/ride_room/domain/use_cases/get_ride_url_usecase.dart';
import '../../../features/ride_room/domain/use_cases/get_socket_status_usecase.dart';
import '../../../features/ride_room/domain/use_cases/ride_payment_updates_usecase.dart';
import '../../../features/ride_room/domain/use_cases/send_location_usecase.dart';

void registerRideRoomModule() {
  locator.registerLazySingleton<RideSocketListener>(
    () => RideSocketListener(socketService: locator<SocketService>()),
  );

  locator.registerLazySingleton<RideSocketDataSource>(
    () => RideSocketDataSourceImpl(
      socketService: locator<SocketService>(),
      listener: locator<RideSocketListener>(),
    ),
  );

  locator.registerLazySingleton<CarpoolRideDataSource>(
    () => CarpoolRideDataSourceImpl(apiService: locator<ApiService>()),
  );

  locator.registerLazySingleton<RideSocketRepository>(
    () => RideSocketRepositoryImpl(
      locator<RideSocketDataSource>(),
      locator<RideDetailsRemoteDataSource>(),
    ),
  );
  locator.registerLazySingleton<CarpoolRideRepository>(
    () => CarpoolRideRepositoryImpl(locator<CarpoolRideDataSource>()),
  );
  locator.registerLazySingleton<RideDetailsRemoteDataSource>(
    () => RideDetailsRemoteDataSourceImpl(),
  );

  locator.registerLazySingleton<LocationLocalDataSource>(
    () => LocationLocalDataSourceImpl(
      read: (key) async => locator<SharedPreferences>().getString(key),
      write: (key, value) async =>
          locator<SharedPreferences>().setString(key, value),
    ),
  );

  locator.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(locator<LocationLocalDataSource>()),
  );
  locator.registerLazySingleton<RideFareRemoteDataSource>(
    () => RideFareRemoteDataSourceImpl(),
  );
  locator.registerLazySingleton<RideFareRepository>(
    () => RideFareRepositoryImpl(locator<RideFareRemoteDataSource>()),
  );

  locator.registerLazySingleton<GetRecentLocationsUseCase>(
    () => GetRecentLocationsUseCase(locator<LocationRepository>()),
  );

  locator.registerLazySingleton<SaveRecentLocationUseCase>(
    () => SaveRecentLocationUseCase(locator<LocationRepository>()),
  );

  locator.registerLazySingleton<GetPopularLocationsUseCase>(
    () => GetPopularLocationsUseCase(locator<LocationRepository>()),
  );
  locator.registerLazySingleton<CalculateFareUseCase>(
    () => CalculateFareUseCase(locator<RideFareRepository>()),
  );
  // Use cases
  locator.registerLazySingleton(
    () => ConnectRideSocketUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => DisconnectRideSocketUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => FindRideUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => FindCarpoolRidesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => JoinCarpoolRideUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => CancelCarpoolRideRequestUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => CompleteCarpoolRideUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => FindCarpoolRidesByApiUseCase(locator<CarpoolRideRepository>()),
  );
  locator.registerLazySingleton(
    () => GetCarpoolRideByIdUseCase(locator<CarpoolRideRepository>()),
  );
  locator.registerLazySingleton(
    () => CancelRideUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => ApplyPromoCodeUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => RideStatusUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => DriverLocationUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => GetSocketStatusUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => RideResumeUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => RideSearchStatusUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => RideSearchExhaustedUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => RideUpgradeOfferUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => RideUpgradeResultUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => DecideRideUpgradeUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => RidePaymentUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => CarpoolBookingStatusUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => CarpoolRouteUpdateUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => CarpoolRideStartedUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () =>
        CarpoolPassengerPickedUpUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => CarpoolRideCompletedUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => CarpoolStopArrivedUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => CarpoolPaymentVerificationUpdatesUseCase(
      locator<RideSocketRepository>(),
    ),
  );
  locator.registerLazySingleton(
    () => CarpoolResumeUpdatesUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => SocketErrorsUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => GetRideByIdUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => SendCurrentLocationUseCase(locator<RideSocketRepository>()),
  );

  locator.registerLazySingleton(
    () => GetShareRideUrlUseCase(locator<RideSocketRepository>()),
  );
  locator.registerLazySingleton(
    () => GetShareCarpoolRideUrlUseCase(locator<RideSocketRepository>()),
  );
}
