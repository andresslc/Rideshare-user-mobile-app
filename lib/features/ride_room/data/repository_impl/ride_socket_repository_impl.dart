import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/params/apply_promo_code_params.dart';
import 'package:ride_app/core/params/cancel_ride_params.dart';
import 'package:ride_app/core/params/complete_carpool_ride_params.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_details_remote_data_source.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_socket_datasource.dart';
import 'package:ride_app/features/ride_room/data/models/apply_promo_code_model.dart';
import 'package:ride_app/features/ride_room/data/models/share_ride_model.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_search_exhausted_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_search_status_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_upgrade_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/share_ride_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/cancel_carpool_request_params.dart';
import '../../../../core/params/current_location_params.dart';
import '../../../../core/params/find_carpool_ride_params.dart';
import '../../../../core/params/find_ride_params.dart';
import '../../../../core/services/socket_service.dart';
import '../../domain/entities/carpool_booking_status_entity.dart';
import '../../domain/entities/carpool_passenger_picked_up_entity.dart';
import '../../domain/entities/carpool_resume_entity.dart';
import '../../domain/entities/carpool_ride_completed_entity.dart';
import '../../domain/entities/carpool_ride_response_entity.dart';
import '../../domain/entities/carpool_ride_started_entity.dart';
import '../../domain/entities/carpool_route_update_entity.dart';
import '../../domain/entities/carpool_stop_arrived_entity.dart';
import '../../domain/entities/complete_carpool_ride_entity.dart';
import '../../domain/entities/driver_location_entity.dart';
import '../../domain/entities/joined_carpool_entity.dart';
import '../../domain/entities/payment_verification_entity.dart';
import '../models/ride_response.model.dart';

class RideSocketRepositoryImpl implements RideSocketRepository {
  final RideSocketDataSource dataSource;
  final RideDetailsRemoteDataSource rideDetailsRemoteDataSource;

  RideSocketRepositoryImpl(this.dataSource, this.rideDetailsRemoteDataSource);

  @override
  Future<Either<Failure, void>> connect() async {
    try {
      await dataSource.connect();
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await dataSource.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, RideResponseEntity>> rideStatusUpdates() {
    return dataSource
        .rideStatusUpdate()
        .map<Either<Failure, RideResponseEntity>>(
          (RideResponseEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, DriverLocationEntity>> driverLocationUpdates() {
    return dataSource
        .driverLocationUpdate()
        .map<Either<Failure, DriverLocationEntity>>(
          (DriverLocationEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, RideResponseEntity>> rideResumeUpdates() {
    return dataSource
        .rideResumeUpdate()
        .map<Either<Failure, RideResponseEntity>>(
          (RideResponseEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, RideSearchStatusEntity>> rideSearchStatusUpdates() {
    return dataSource
        .rideSearchStatusUpdate()
        .map<Either<Failure, RideSearchStatusEntity>>(
          (RideSearchStatusEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, RideSearchExhaustedEntity>>
  rideSearchExhaustedUpdates() {
    return dataSource
        .rideSearchExhaustedUpdate()
        .map<Either<Failure, RideSearchExhaustedEntity>>(
          (RideSearchExhaustedEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, RideUpgradeOfferEntity>> rideUpgradeOfferUpdates() {
    return dataSource
        .rideUpgradeOfferUpdate()
        .map<Either<Failure, RideUpgradeOfferEntity>>(
          (RideUpgradeOfferEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, RideUpgradeResultEntity>> rideUpgradeResultUpdates() {
    return dataSource
        .rideUpgradeResultUpdate()
        .map<Either<Failure, RideUpgradeResultEntity>>(
          (RideUpgradeResultEntity event) => Right(event),
        );
  }

  @override
  Future<Either<Failure, RideUpgradeDecisionEntity>> decideUpgrade({
    required String rideId,
    required RideUpgradeDecision decision,
  }) async {
    final response = await dataSource.decideUpgrade(
      rideId: rideId,
      decision: decision,
    );
    return response.fold((failure) => Left(failure), (data) => Right(data));
  }

  @override
  Stream<Either<Failure, PaymentVerificationEntity>>
  ridePaymentVerificationUpdates() {
    return dataSource
        .ridePaymentVerificationUpdate()
        .map<Either<Failure, PaymentVerificationEntity>>(
          (PaymentVerificationEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, CarpoolBookingStatusEntity>>
  carpoolBookingStatusUpdates() {
    return dataSource
        .carpoolBookingStatusUpdate()
        .map<Either<Failure, CarpoolBookingStatusEntity>>(
          (CarpoolBookingStatusEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, CarpoolRideStartedEntity>>
  carpoolRideStartedUpdates() {
    return dataSource
        .carpoolRideStartedUpdate()
        .map<Either<Failure, CarpoolRideStartedEntity>>(
          (CarpoolRideStartedEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, CarpoolPassengerPickedUpEntity>>
  carpoolPassengerPickedUpUpdates() {
    return dataSource
        .carpoolPassengerPickedUpUpdate()
        .map<Either<Failure, CarpoolPassengerPickedUpEntity>>(
          (CarpoolPassengerPickedUpEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, CarpoolRideCompletedEntity>>
  carpoolRideCompletedUpdates() {
    return dataSource
        .carpoolRideCompletedUpdate()
        .map<Either<Failure, CarpoolRideCompletedEntity>>(
          (CarpoolRideCompletedEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, CarpoolStopArrivedEntity>>
  carpoolStopArrivedUpdates() {
    return dataSource
        .carpoolStopArrivedUpdate()
        .map<Either<Failure, CarpoolStopArrivedEntity>>(
          (CarpoolStopArrivedEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, CarpoolRouteUpdateEntity>>
  carpoolRouteUpdateUpdates() {
    return dataSource
        .carpoolRouteUpdateUpdate()
        .map<Either<Failure, CarpoolRouteUpdateEntity>>(
          (CarpoolRouteUpdateEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, PaymentVerificationEntity>>
  carpoolPaymentVerificationUpdates() {
    return dataSource
        .carpoolPaymentVerificationUpdate()
        .map<Either<Failure, PaymentVerificationEntity>>(
          (PaymentVerificationEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, CarpoolResumeEntity>> carpoolResumeUpdates() {
    return dataSource
        .carpoolResumeUpdate()
        .map<Either<Failure, CarpoolResumeEntity>>(
          (CarpoolResumeEntity event) => Right(event),
        );
  }

  @override
  Stream<Either<Failure, String>> socketErrors() {
    return dataSource.watchErrors().map<Either<Failure, String>>(
      (String error) => Left(NetworkFailure(message: error)),
    );
  }

  Stream<Either<Failure, SocketConnectionStatus>> watchSocketStatus() {
    return dataSource.watchSocketStatus().map<Either<Failure, SocketConnectionStatus>>(
      (SocketConnectionStatus status) => Right(status),
    );
  }

  @override
  Future<Either<Failure, RideResponseModel>> findRide(
    FindRideParams params,
  ) async {
    final response = await dataSource.findRide(params);
    return response.fold((failure) => Left(failure), (data) => Right(data));
  }

  @override
  Future<Either<Failure, CarpoolRideResponseEntity>> findCarpoolRides(
    FindCarpoolRideParams params,
  ) async {
    final response = await dataSource.findCarpoolRides(params);
    return response.fold((failure) => Left(failure), (data) => Right(data));
  }

  @override
  Future<Either<Failure, JoinedCarpoolEntity>> joinCarpoolRide(
    FindCarpoolRideParams params,
  ) async {
    final response = await dataSource.joinCarpoolRide(params);
    return response.fold((failure) => Left(failure), (data) => Right(data));
  }

  @override
  Future<Either<Failure, JoinedCarpoolEntity>> cancelCarpoolRideRequest(
    CancelCarpoolRequestParams params,
  ) async {
    final response = await dataSource.cancelCarpoolRideRequest(params);
    return response.fold((failure) => Left(failure), (data) => Right(data));
  }

  @override
  Future<Either<Failure, CompleteCarpoolRideEntity>> completeCarpoolRide(
    CompleteCarpoolRideParams params,
  ) async {
    final response = await dataSource.completeCarpoolRide(params);
    return response.fold((failure) => Left(failure), (data) => Right(data));
  }

  @override
  Future<Either<Failure, RideResponseModel>> cancelRide(
    CancelRideParams params,
  ) async {
    final response = await dataSource.cancelRide(params);
    return response.fold((failure) => Left(failure), (data) => Right(data));
  }

  @override
  Future<Either<Failure, RideResponseEntity>> getRideById(String rideId) async {
    final response = await rideDetailsRemoteDataSource.getRideById(rideId);
    return response.fold(
      (failure) => Left(failure),
      (ride) => Right(RideResponseModel(rideId: ride.id, ride: ride)),
    );
  }

  @override
  Future<Either<Failure, void>> sendCurrentLocation({
    required CurrentLocationParams params,
  }) async {
    final response = await dataSource.sendCurrentLocation(params);
    return response.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, ShareRideEntity>> getShareRideUrl(
    String rideId,
  ) async {
    final response = await rideDetailsRemoteDataSource.getShareRideUrl(rideId);
    return response.fold(
      (failure) => Left(failure),
      (ride) => Right(ShareRideModel(url: ride.url)),
    );
  }

  @override
  Future<Either<Failure, PromoCodeModel>> applyPromoCode(
    ApplyPromoCodeParams params,
  ) async {
    final response = await rideDetailsRemoteDataSource.applyPromoCode(params);
    return response.fold((failure) => Left(failure), (ride) => Right(ride));
  }

  @override
  Future<Either<Failure, ShareRideEntity>> getShareCarpoolRideUrl(
    String rideId,
  ) async {
    final response = await rideDetailsRemoteDataSource.getShareCarpoolRideUrl(
      rideId,
    );
    return response.fold(
      (failure) => Left(failure),
      (ride) => Right(ShareRideModel(url: ride.url)),
    );
  }
}
