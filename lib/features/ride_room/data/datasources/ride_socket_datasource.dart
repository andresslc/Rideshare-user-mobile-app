import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/socket_event.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/params/cancel_carpool_request_params.dart';
import 'package:ride_app/core/params/cancel_ride_params.dart';
import 'package:ride_app/core/params/complete_carpool_ride_params.dart';
import 'package:ride_app/features/chat/data/models/chat_message_model.dart';
import 'package:ride_app/features/chat/data/models/message_delivery_status.dart';
import 'package:ride_app/features/ride_room/data/models/driver_location_model.dart';

import '../../../../core/params/current_location_params.dart';
import '../../../../core/params/find_carpool_ride_params.dart';
import '../../../../core/params/find_ride_params.dart';
import '../../domain/entities/ride_upgrade_entity.dart';
import '../models/carpool_booking_status_model.dart';
import '../models/carpool_passenger_picked_up_model.dart';
import '../models/carpool_resume_model.dart';
import '../models/carpool_ride_completed_model.dart';
import '../models/carpool_ride_response_model.dart';
import '../models/carpool_ride_started_model.dart';
import '../models/carpool_route_update_model.dart';
import '../models/carpool_stop_arrived_model.dart';
import '../models/complete_carpool_ride_model.dart';
import '../models/joined_carpool_model.dart';
import '../models/payment_verification_model.dart';
import '../models/ride_response.model.dart';
import '../models/ride_search_exhausted_model.dart';
import '../models/ride_search_status_model.dart';
import '../models/ride_upgrade_model.dart';
import 'ride_socket_listener.dart';

abstract class RideSocketDataSource {
  /// When [forceReconnect] is true, tears down the socket and listeners, opens a
  /// fresh connection, and re-registers all ride + chat handlers (use e.g. when
  /// opening chat to avoid a stale session).
  Future<void> connect({bool forceReconnect = false});
  Future<void> disconnect();
  FutureEither<Unit> sendCurrentLocation(CurrentLocationParams params);

  FutureEither<RideResponseModel> findRide(FindRideParams rideId);
  FutureEither<CarpoolRideResponseModel> findCarpoolRides(
    FindCarpoolRideParams params,
  );
  FutureEither<JoinedCarpoolModel> joinCarpoolRide(
    FindCarpoolRideParams params,
  );
  FutureEither<JoinedCarpoolModel> cancelCarpoolRideRequest(
    CancelCarpoolRequestParams params,
  );
  FutureEither<CompleteCarpoolRideModel> completeCarpoolRide(
    CompleteCarpoolRideParams params,
  );

  FutureEither<RideResponseModel> cancelRide(CancelRideParams params);

  Stream<RideResponseModel> rideResumeUpdate();
  Stream<DriverLocationModel> driverLocationUpdate();
  Stream<RideResponseModel> rideStatusUpdate();

  /// One event per ring of the escalating driver search.
  Stream<RideSearchStatusModel> rideSearchStatusUpdate();

  /// The ladder finished without a driver taking the ride.
  Stream<RideSearchExhaustedModel> rideSearchExhaustedUpdate();

  /// The Economy ladder ran out and the backend offers a Luxury search.
  Stream<RideUpgradeOfferModel> rideUpgradeOfferUpdate();

  /// How an upgrade offer ended.
  Stream<RideUpgradeResultModel> rideUpgradeResultUpdate();

  /// Answers an upgrade offer. Returns the ack even when the backend refuses,
  /// so the caller can act on its `reason`; only transport errors are a Left.
  FutureEither<RideUpgradeDecisionModel> decideUpgrade({
    required String rideId,
    required RideUpgradeDecision decision,
  });
  Stream<PaymentVerificationModel> ridePaymentVerificationUpdate();
  Stream<CarpoolBookingStatusModel> carpoolBookingStatusUpdate();
  Stream<CarpoolRideStartedModel> carpoolRideStartedUpdate();
  Stream<CarpoolPassengerPickedUpModel> carpoolPassengerPickedUpUpdate();
  Stream<CarpoolRideCompletedModel> carpoolRideCompletedUpdate();
  Stream<CarpoolStopArrivedModel> carpoolStopArrivedUpdate();
  Stream<PaymentVerificationModel> carpoolPaymentVerificationUpdate();
  Stream<CarpoolResumeModel> carpoolResumeUpdate();
  Stream<CarpoolRouteUpdateModel> carpoolRouteUpdateUpdate();
  Stream<ChatMessageModel> chatReceiveUpdates();
  Stream<ChatStatusUpdate> chatStatusUpdates();
  Stream<String> watchErrors();
  Stream<SocketConnectionStatus> watchSocketStatus();

  /// Marks inbound messages as read while the viewer is on the chat screen.
  /// Backend expects: `chat:read` with `{ conversationId }`.
  Future<void> markConversationRead(String conversationId);

  // Stream<RideSocketEventModel> watchRideLocation();

  // FutureEither<RideSocketEventModel> joinRideRoom(String rideId);
  // FutureEither<RideSocketEventModel> leaveRideRoom(String rideId);
  // FutureEither<RideSocketEventModel> sendRideLocation({
  //   required String rideId,
  //   required double latitude,
  //   required double longitude,
  // });
}

class RideSocketDataSourceImpl implements RideSocketDataSource {
  final SocketService socketService;
  final RideSocketListener listener;

  RideSocketDataSourceImpl({
    required this.socketService,
    required this.listener,
  });

  bool _isInitialized = false;

  @override
  Future<void> connect({bool forceReconnect = false}) async {
    final bool wasConnected = socketService.isConnected;

    if (forceReconnect) {
      listener.stop();
      await socketService.connect(forceReconnect: true);
      listener.start();
      _isInitialized = true;
      return;
    }

    if (!socketService.isConnected) {
      await socketService.connect();
    }

    // Rebind listeners whenever we actually had to reconnect, because a fresh
    // socket instance loses any handlers that were attached to the old one.
    if (!_isInitialized || !wasConnected) {
      listener.start();
      _isInitialized = true;
    }
  }

  @override
  Future<void> disconnect() async {
    socketService.disconnect();
    listener.stop();
    _isInitialized = false;
  }

  @override
  FutureEither<Unit> sendCurrentLocation(CurrentLocationParams params) async {
    try {
      final SocketAckResponse res = await socketService.emitWithAckResponse(
        SocketEvent.userLocationUpdate,
        params.toJson(),
      );

      if (!res.success) {
        return Left(
          NetworkFailure(
            message: res.message.isEmpty
                ? 'Socket ack returned unsuccessful response.'
                : res.message,
          ),
        );
      }
      log(res.message, name: 'RideSocketDataSourceImpl - sendCurrentLocation');
      return const Right(unit);
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Stream<SocketConnectionStatus> watchSocketStatus() =>
      socketService.statusStream;
  // @override
  // Future<void> connect({bool forceReconnect = false}) async {
  //   if (forceReconnect) {
  //     listener.stop();
  //     await socketService.connect(forceReconnect: true);
  //     listener.start();
  //     _isInitialized = true;
  //     return;
  //   }

  //   if (!socketService.isConnected) {
  //     await socketService.connect();
  //   }

  //   if (!_isInitialized) {
  //     listener.start();
  //     _isInitialized = true;
  //   }
  // }

  // @override
  // Future<void> disconnect() async {
  //   socketService.disconnect();
  //   listener.stop();
  //   _isInitialized = false;
  // }

  @override
  Stream<RideResponseModel> rideResumeUpdate() => listener.rideResumeStream;

  @override
  Stream<RideSearchStatusModel> rideSearchStatusUpdate() =>
      listener.rideSearchStatusStream;

  @override
  Stream<RideSearchExhaustedModel> rideSearchExhaustedUpdate() =>
      listener.rideSearchExhaustedStream;

  @override
  Stream<RideUpgradeOfferModel> rideUpgradeOfferUpdate() =>
      listener.rideUpgradeOfferStream;

  @override
  Stream<RideUpgradeResultModel> rideUpgradeResultUpdate() =>
      listener.rideUpgradeResultStream;

  @override
  FutureEither<RideUpgradeDecisionModel> decideUpgrade({
    required String rideId,
    required RideUpgradeDecision decision,
  }) async {
    try {
      final SocketAckResponse res = await socketService.emitWithAckResponse(
        SocketEvent.rideUpgradeDecide,
        <String, dynamic>{'rideId': rideId, 'decision': decision.value},
      );
      log("$res", name: 'RideSocketDataSourceImpl - decideUpgrade');
      return Right(
        RideUpgradeDecisionModel.fromAck(
          success: res.success,
          message: res.message,
          data: res.data,
        ),
      );
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Stream<DriverLocationModel> driverLocationUpdate() =>
      listener.rideLocationStream;

  @override
  Stream<RideResponseModel> rideStatusUpdate() => listener.rideStatusStream;

  @override
  Stream<PaymentVerificationModel> ridePaymentVerificationUpdate() =>
      listener.ridePaymentVerificationStream;

  @override
  Stream<CarpoolBookingStatusModel> carpoolBookingStatusUpdate() =>
      listener.carpoolBookingStatusStream;

  @override
  Stream<CarpoolRideStartedModel> carpoolRideStartedUpdate() =>
      listener.carpoolRideStartedStream;

  @override
  Stream<CarpoolPassengerPickedUpModel> carpoolPassengerPickedUpUpdate() =>
      listener.carpoolPassengerPickedUpStream;

  @override
  Stream<CarpoolRideCompletedModel> carpoolRideCompletedUpdate() =>
      listener.carpoolRideCompletedStream;

  @override
  Stream<CarpoolStopArrivedModel> carpoolStopArrivedUpdate() =>
      listener.carpoolStopArrivedStream;

  @override
  Stream<PaymentVerificationModel> carpoolPaymentVerificationUpdate() =>
      listener.carpoolPaymentVerificationStream;

  @override
  Stream<CarpoolResumeModel> carpoolResumeUpdate() =>
      listener.carpoolResumeStream;

  @override
  Stream<CarpoolRouteUpdateModel> carpoolRouteUpdateUpdate() =>
      listener.carpoolRouteUpdateStream;
  @override
  Stream<ChatMessageModel> chatReceiveUpdates() => listener.chatReceiveStream;

  @override
  Stream<ChatStatusUpdate> chatStatusUpdates() =>
      listener.chatStatusUpdateStream;

  @override
  Future<void> markConversationRead(String conversationId) async {
    final String id = conversationId.trim();
    if (id.isEmpty) return;
    if (!socketService.isConnected) return;
    try {
      await socketService.emitWithAckResponse(
        SocketEvent.chatRead,
        <String, dynamic>{'conversationId': id},
      );
      log(
        'emitted ${SocketEvent.chatRead} conversationId=$id',
        name: 'RideSocketDataSourceImpl',
      );
    } catch (e, st) {
      log(
        'failed ${SocketEvent.chatRead}: $e\n$st',
        name: 'RideSocketDataSourceImpl',
      );
    }
  }

  @override
  Stream<String> watchErrors() => listener.errorStream;

  @override
  FutureEither<RideResponseModel> findRide(FindRideParams params) async {
    try {
      final SocketAckResponse res = await socketService.emitWithAckResponse(
        SocketEvent.rideRequest,
        params.toJson(),
      );
      log("${params.toJson()}~~~~~~~~~~~~");
      if (res.data == null) {
        return Left(
          NetworkFailure(
            message: res.message.isEmpty
                ? 'Socket ack returned no data.'
                : res.message,
          ),
        );
      }
      // final RideResponseModel model = RideResponseModel.fromJson(res.data);
      log("$res", name: 'RideSocketDataSourceImpl - findRide');

      if (!res.success) {
        return Left(
          NetworkFailure(
            message: res.message.isEmpty
                ? 'Socket ack returned unsuccessful response.'
                : res.message,
          ),
        );
      }
      // final RideResponseModel model = RideResponseModel.fromJson (res.data);
      final dynamic payload = res.data;
      if (payload is Map<String, dynamic>) {
        return Right(RideResponseModel.fromJson(payload));
      }
      if (payload is Map) {
        return Right(
          RideResponseModel.fromJson(Map<String, dynamic>.from(payload)),
        );
      }

      return const Left(
        NetworkFailure(message: 'Unexpected response format from socket ack.'),
      );

      // return Right(model);
      //  return Right(
      //   RideResponseModel(rideId: params., type: 'cancelled', ride: null),
      // );
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  FutureEither<CarpoolRideResponseModel> findCarpoolRides(
    FindCarpoolRideParams params,
  ) async {
    try {
      final SocketAckResponse res = await socketService.emitWithAckResponse(
        SocketEvent.carpoolIncomingMatches,
        params.toJson(),
      );

      if (res.data == null) {
        return Left(
          NetworkFailure(
            message: res.message.isEmpty
                ? 'Socket ack returned no data.'
                : res.message,
          ),
        );
      }

      if (!res.success) {
        return Left(
          NetworkFailure(
            message: res.message.isEmpty
                ? 'Socket ack returned unsuccessful response.'
                : res.message,
          ),
        );
      }

      final dynamic payload = res.data;
      if (payload is Map<String, dynamic>) {
        return Right(CarpoolRideResponseModel.fromJson(payload));
      }
      if (payload is Map) {
        return Right(
          CarpoolRideResponseModel.fromJson(Map<String, dynamic>.from(payload)),
        );
      }

      return const Left(
        NetworkFailure(message: 'Unexpected response format from socket ack.'),
      );
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  FutureEither<JoinedCarpoolModel> joinCarpoolRide(
    FindCarpoolRideParams params,
  ) async {
    try {
      final SocketAckResponse res = await socketService.emitWithAckResponse(
        SocketEvent.carpoolJoin,
        params.toJson(),
      );

      final Map<String, dynamic> payload = <String, dynamic>{
        'message': res.message,
        'data': res.data,
      };

      if (!res.success) {
        return Left(
          NetworkFailure(
            message: res.message.isEmpty
                ? 'Socket ack returned unsuccessful response.'
                : res.message,
          ),
        );
      }

      return Right(JoinedCarpoolModel.fromJson(payload));
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  FutureEither<JoinedCarpoolModel> cancelCarpoolRideRequest(
    CancelCarpoolRequestParams params,
  ) async {
    try {
      final SocketAckResponse res = await socketService.emitWithAckResponse(
        SocketEvent.carpoolCancelRequest,
        params.toJson(),
      );

      final Map<String, dynamic> payload = <String, dynamic>{
        'message': res.message,
        'data': res.data,
      };

      if (!res.success) {
        return Left(
          NetworkFailure(
            message: res.message.isEmpty
                ? 'Socket ack returned unsuccessful response.'
                : res.message,
          ),
        );
      }

      return Right(JoinedCarpoolModel.fromJson(payload));
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  FutureEither<CompleteCarpoolRideModel> completeCarpoolRide(
    CompleteCarpoolRideParams params,
  ) async {
    try {
      final SocketAckResponse res = await socketService.emitWithAckResponse(
        SocketEvent.carpoolComplete,
        params.toJson(),
      );

      final Map<String, dynamic> payload = <String, dynamic>{
        'message': res.message,
        'data': res.data,
      };

      if (!res.success) {
        return Left(
          NetworkFailure(
            message: res.message.isEmpty
                ? 'Socket ack returned unsuccessful response.'
                : res.message,
          ),
        );
      }

      return Right(CompleteCarpoolRideModel.fromJson(payload));
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }

  @override
  FutureEither<RideResponseModel> cancelRide(CancelRideParams params) async {
    try {
      final SocketAckResponse res = await socketService.emitWithAckResponse(
        SocketEvent.rideCancel,
        params.toJson(),
      );

      if (!res.success) {
        return Left(
          NetworkFailure(
            message: res.message.isEmpty
                ? 'Socket ack returned unsuccessful response.'
                : res.message,
          ),
        );
      }

      final dynamic payload = res.data;
      if (payload is Map<String, dynamic>) {
        return Right(
          RideResponseModel.fromJson({"message": res.message, ...payload}),
        );
      }
      if (payload is Map) {
        return Right(
          RideResponseModel.fromJson(Map<String, dynamic>.from(payload)),
        );
      }

      return Right(
        RideResponseModel(rideId: params.rideId, type: 'cancelled', ride: null),
      );
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }
}
