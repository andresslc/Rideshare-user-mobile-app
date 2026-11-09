import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/params/apply_promo_code_params.dart';
import 'package:ride_app/core/params/cancel_ride_params.dart';
import 'package:ride_app/core/params/complete_carpool_ride_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/apply_promo_code_entity.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/cancel_carpool_request_params.dart';
import '../../../../core/params/current_location_params.dart';
import '../../../../core/params/find_carpool_ride_params.dart';
import '../../../../core/params/find_ride_params.dart';
import '../../../../core/services/socket_service.dart';
import '../entities/carpool_booking_status_entity.dart';
import '../entities/carpool_passenger_picked_up_entity.dart';
import '../entities/carpool_resume_entity.dart';
import '../entities/carpool_ride_completed_entity.dart';
import '../entities/carpool_ride_response_entity.dart';
import '../entities/carpool_ride_started_entity.dart';
import '../entities/carpool_route_update_entity.dart';
import '../entities/carpool_stop_arrived_entity.dart';
import '../entities/complete_carpool_ride_entity.dart';
import '../entities/driver_location_entity.dart';
import '../entities/joined_carpool_entity.dart';
import '../entities/payment_verification_entity.dart';
import '../entities/ride_response_entity.dart';
import '../entities/ride_search_exhausted_entity.dart';
import '../entities/ride_search_status_entity.dart';
import '../entities/ride_upgrade_entity.dart';
import '../entities/share_ride_entity.dart';

abstract class RideSocketRepository {
  Future<Either<Failure, void>> connect();
  Future<Either<Failure, void>> disconnect();
  Future<Either<Failure, RideResponseEntity>> getRideById(String rideId);

  Stream<Either<Failure, RideResponseEntity>> rideResumeUpdates();
  Stream<Either<Failure, DriverLocationEntity>> driverLocationUpdates();
  Stream<Either<Failure, RideResponseEntity>> rideStatusUpdates();
  Stream<Either<Failure, RideSearchStatusEntity>> rideSearchStatusUpdates();
  Stream<Either<Failure, RideSearchExhaustedEntity>>
  rideSearchExhaustedUpdates();
  Stream<Either<Failure, RideUpgradeOfferEntity>> rideUpgradeOfferUpdates();
  Stream<Either<Failure, RideUpgradeResultEntity>> rideUpgradeResultUpdates();
  Future<Either<Failure, RideUpgradeDecisionEntity>> decideUpgrade({
    required String rideId,
    required RideUpgradeDecision decision,
  });
  Stream<Either<Failure, PaymentVerificationEntity>>
  ridePaymentVerificationUpdates();
  Stream<Either<Failure, CarpoolBookingStatusEntity>>
  carpoolBookingStatusUpdates();
  Stream<Either<Failure, CarpoolRideStartedEntity>> carpoolRideStartedUpdates();
  Stream<Either<Failure, CarpoolPassengerPickedUpEntity>>
  carpoolPassengerPickedUpUpdates();
  Stream<Either<Failure, CarpoolRideCompletedEntity>>
  carpoolRideCompletedUpdates();
  Stream<Either<Failure, CarpoolStopArrivedEntity>> carpoolStopArrivedUpdates();
  Stream<Either<Failure, PaymentVerificationEntity>>
  carpoolPaymentVerificationUpdates();
  Stream<Either<Failure, CarpoolResumeEntity>> carpoolResumeUpdates();
  Stream<Either<Failure, CarpoolRouteUpdateEntity>> carpoolRouteUpdateUpdates();
  Stream<Either<Failure, String>> socketErrors();
  Stream<Either<Failure, SocketConnectionStatus>> watchSocketStatus();

  Future<Either<Failure, RideResponseEntity>> findRide(FindRideParams params);
  Future<Either<Failure, CarpoolRideResponseEntity>> findCarpoolRides(
    FindCarpoolRideParams params,
  );
  Future<Either<Failure, JoinedCarpoolEntity>> joinCarpoolRide(
    FindCarpoolRideParams params,
  );
  Future<Either<Failure, JoinedCarpoolEntity>> cancelCarpoolRideRequest(
    CancelCarpoolRequestParams params,
  );
  Future<Either<Failure, CompleteCarpoolRideEntity>> completeCarpoolRide(
    CompleteCarpoolRideParams params,
  );
  Future<Either<Failure, ShareRideEntity>> getShareRideUrl(String rideId);
  Future<Either<Failure, ShareRideEntity>> getShareCarpoolRideUrl(
    String rideId,
  );
  Future<Either<Failure, void>> sendCurrentLocation({
    required CurrentLocationParams params,
  });
  Future<Either<Failure, RideResponseEntity>> cancelRide(
    CancelRideParams params,
  );
  Future<Either<Failure, PromoCodeEntity>> applyPromoCode(
    ApplyPromoCodeParams params,
  );
}
