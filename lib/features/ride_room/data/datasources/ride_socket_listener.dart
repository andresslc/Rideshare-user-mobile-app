import 'dart:async';
import 'dart:convert';

import 'package:ride_app/core/constants/socket_event.dart';
import 'package:ride_app/core/services/socket_service.dart';
import 'package:ride_app/core/utils/app_log.dart';
import 'package:ride_app/features/chat/data/models/chat_message_model.dart';
import 'package:ride_app/features/chat/data/models/message_delivery_status.dart';
import 'package:ride_app/features/ride_room/data/models/carpool_booking_status_model.dart';
import 'package:ride_app/features/ride_room/data/models/carpool_passenger_picked_up_model.dart';
import 'package:ride_app/features/ride_room/data/models/carpool_resume_model.dart';
import 'package:ride_app/features/ride_room/data/models/carpool_ride_completed_model.dart';
import 'package:ride_app/features/ride_room/data/models/carpool_ride_started_model.dart';
import 'package:ride_app/features/ride_room/data/models/carpool_route_update_model.dart';
import 'package:ride_app/features/ride_room/data/models/carpool_stop_arrived_model.dart';
import 'package:ride_app/features/ride_room/data/models/driver_location_model.dart';
import 'package:ride_app/features/ride_room/data/models/ride_search_exhausted_model.dart';
import 'package:ride_app/features/ride_room/data/models/ride_search_status_model.dart';
import 'package:ride_app/features/ride_room/data/models/ride_upgrade_model.dart';

import '../models/payment_verification_model.dart';
import '../models/ride_response.model.dart';

class RideSocketListener {
  final SocketService socketService;

  final StreamController<DriverLocationModel> _driverLocationUpdateController =
      StreamController<DriverLocationModel>.broadcast();
  final StreamController<RideResponseModel> _rideStatusUpdateController =
      StreamController<RideResponseModel>.broadcast();
  final StreamController<RideResponseModel> _rideResumeController =
      StreamController<RideResponseModel>.broadcast();
  RideResponseModel? _lastRideResume;
  final StreamController<RideSearchStatusModel> _rideSearchStatusController =
      StreamController<RideSearchStatusModel>.broadcast();
  final StreamController<RideSearchExhaustedModel>
  _rideSearchExhaustedController =
      StreamController<RideSearchExhaustedModel>.broadcast();
  final StreamController<RideUpgradeOfferModel> _rideUpgradeOfferController =
      StreamController<RideUpgradeOfferModel>.broadcast();
  final StreamController<RideUpgradeResultModel> _rideUpgradeResultController =
      StreamController<RideUpgradeResultModel>.broadcast();
  final StreamController<PaymentVerificationModel>
  _ridePaymentVerificationController =
      StreamController<PaymentVerificationModel>.broadcast();

  final StreamController<CarpoolBookingStatusModel>
  _carpoolBookingStatusController =
      StreamController<CarpoolBookingStatusModel>.broadcast();

  final StreamController<CarpoolRideStartedModel>
  _carpoolRideStartedController =
      StreamController<CarpoolRideStartedModel>.broadcast();

  final StreamController<CarpoolPassengerPickedUpModel>
  _carpoolPassengerPickedUpController =
      StreamController<CarpoolPassengerPickedUpModel>.broadcast();

  final StreamController<CarpoolRideCompletedModel>
  _carpoolRideCompletedController =
      StreamController<CarpoolRideCompletedModel>.broadcast();

  final StreamController<CarpoolStopArrivedModel>
  _carpoolStopArrivedController =
      StreamController<CarpoolStopArrivedModel>.broadcast();

  final StreamController<PaymentVerificationModel>
  _carpoolPaymentVerificationController =
      StreamController<PaymentVerificationModel>.broadcast();

  final StreamController<CarpoolResumeModel> _carpoolResumeController =
      StreamController<CarpoolResumeModel>.broadcast();
  CarpoolResumeModel? _lastCarpoolResume;
  final StreamController<CarpoolRouteUpdateModel>
  _carpoolRouteUpdateController =
      StreamController<CarpoolRouteUpdateModel>.broadcast();

  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<ChatMessageModel> _chatReceiveController =
      StreamController<ChatMessageModel>.broadcast();
  final StreamController<ChatStatusUpdate> _chatStatusUpdateController =
      StreamController<ChatStatusUpdate>.broadcast();

  //

  void Function(dynamic payload)? _driverLocationUpdateHandler;
  void Function(dynamic payload)? _rideStatusUpdateHandler;
  void Function(dynamic payload)? _rideResumeHandler;
  void Function(dynamic payload)? _rideSearchStatusHandler;
  void Function(dynamic payload)? _rideSearchExhaustedHandler;
  void Function(dynamic payload)? _rideUpgradeOfferHandler;
  void Function(dynamic payload)? _rideUpgradeResultHandler;
  void Function(dynamic payload)? _ridePaymentVerificationHandler;

  // Carpool event handlers

  void Function(dynamic payload)? _carpoolBookingStatusHandler;
  void Function(dynamic payload)? _carpoolRideStartedHandler;
  void Function(dynamic payload)? _carpoolPassengerPickedUpHandler;
  void Function(dynamic payload)? _carpoolRideCompletedHandler;
  void Function(dynamic payload)? _carpoolStopArrivedHandler;
  void Function(dynamic payload)? _carpoolPaymentVerificationHandler;
  void Function(dynamic payload)? _carpoolResumeHandler;
  void Function(dynamic payload)? _carpoolRouteUpdateHandler;
  void Function(dynamic payload)? _errorHandler;
  void Function(dynamic payload)? _chatReceiveHandler;
  void Function(dynamic payload)? _chatStatusUpdateHandler;

  StreamSubscription<String>? _serviceErrorSubscription;

  RideSocketListener({required this.socketService});

  Stream<RideResponseModel> get rideStatusStream =>
      _rideStatusUpdateController.stream;
  Stream<DriverLocationModel> get rideLocationStream =>
      _driverLocationUpdateController.stream;
  Stream<RideResponseModel> get rideResumeStream async* {
    final RideResponseModel? cached = _lastRideResume;
    if (cached != null) {
      yield cached;
    }
    yield* _rideResumeController.stream;
  }

  Stream<RideSearchStatusModel> get rideSearchStatusStream =>
      _rideSearchStatusController.stream;
  Stream<RideSearchExhaustedModel> get rideSearchExhaustedStream =>
      _rideSearchExhaustedController.stream;
  Stream<RideUpgradeOfferModel> get rideUpgradeOfferStream =>
      _rideUpgradeOfferController.stream;
  Stream<RideUpgradeResultModel> get rideUpgradeResultStream =>
      _rideUpgradeResultController.stream;
  Stream<PaymentVerificationModel> get ridePaymentVerificationStream =>
      _ridePaymentVerificationController.stream;

  Stream<CarpoolBookingStatusModel> get carpoolBookingStatusStream =>
      _carpoolBookingStatusController.stream;
  Stream<CarpoolRideStartedModel> get carpoolRideStartedStream =>
      _carpoolRideStartedController.stream;
  Stream<CarpoolPassengerPickedUpModel> get carpoolPassengerPickedUpStream =>
      _carpoolPassengerPickedUpController.stream;
  Stream<CarpoolRideCompletedModel> get carpoolRideCompletedStream =>
      _carpoolRideCompletedController.stream;
  Stream<CarpoolStopArrivedModel> get carpoolStopArrivedStream =>
      _carpoolStopArrivedController.stream;
  Stream<PaymentVerificationModel> get carpoolPaymentVerificationStream =>
      _carpoolPaymentVerificationController.stream;
  Stream<CarpoolResumeModel> get carpoolResumeStream async* {
    final CarpoolResumeModel? cached = _lastCarpoolResume;
    if (cached != null) {
      yield cached;
    }
    yield* _carpoolResumeController.stream;
  }

  Stream<CarpoolRouteUpdateModel> get carpoolRouteUpdateStream =>
      _carpoolRouteUpdateController.stream;

  Stream<String> get errorStream => _errorController.stream;
  Stream<ChatMessageModel> get chatReceiveStream =>
      _chatReceiveController.stream;
  Stream<ChatStatusUpdate> get chatStatusUpdateStream =>
      _chatStatusUpdateController.stream;

  RideResponseModel? get lastRideResume => _lastRideResume;

  void publishRideResumeFromPayload(dynamic payload) {
    try {
      log('ride resume ack payload: $payload', name: 'ride socket');
      final Map<String, dynamic> data = _toMap(payload);
      final RideResponseModel model = RideResponseModel.fromJson(data);
      _lastRideResume = model;
      _rideResumeController.add(model);
    } catch (e, st) {
      log("❌ Error processing rideResume ack: $e\n$st", name: "ride resume");
      _rideResumeController.addError('Invalid ride resume response');
    }
  }

  bool publishLastRideResumeAsCompleted() {
    final RideResponseModel? cached = _lastRideResume;
    if (cached == null) {
      log(
        'No cached ride resume available to publish as completed',
        name: 'ride socket',
      );
      return false;
    }

    final RideResponseModel completed = RideResponseModel(
      type: 'completed',
      message: cached.message,
      ride: cached.ride,
      rideOtp: cached.rideOtp,
      rideId: cached.rideId,
    );
    _lastRideResume = completed;
    _rideResumeController.add(completed);
    log('Republished cached ride resume as completed', name: 'ride socket');
    return true;
  }

  void start() {
    stop(); // always clear previous listeners first
    log('registering ride socket listeners', name: 'ride socket');
    _driverLocationUpdateHandler ??= (dynamic payload) {
      try {
        log('driver location payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _driverLocationUpdateController.add(DriverLocationModel.fromJson(data));
      } catch (e, st) {
        log(
          "❌ Error processing rideLocationUpdate: $e\n$st",
          name: "ride location update",
        );
        _driverLocationUpdateController.addError(
          'Invalid ride location response',
        );
      }
    };

    _rideStatusUpdateHandler ??= (dynamic payload) {
      try {
        log('ride status payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        final RideResponseModel model = RideResponseModel.fromJson(data);
        _lastRideResume = model;
        _rideStatusUpdateController.add(model);
      } catch (e, st) {
        log(
          "❌ Error processing rideStatusUpdate: $e\n$st",
          name: "ride status update",
        );
        _rideStatusUpdateController.addError('Invalid ride status response');
      }
    };

    _rideResumeHandler ??= (dynamic payload) {
      publishRideResumeFromPayload(payload);
    };

    _rideSearchStatusHandler ??= (dynamic payload) {
      try {
        log('ride search status payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _rideSearchStatusController.add(RideSearchStatusModel.fromJson(data));
      } catch (e, st) {
        log(
          "❌ Error processing ride:search:status: $e\n$st",
          name: "ride search status",
        );
        _rideSearchStatusController.addError(
          'Invalid ride search status response',
        );
      }
    };

    _rideSearchExhaustedHandler ??= (dynamic payload) {
      try {
        log('ride search exhausted payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _rideSearchExhaustedController.add(
          RideSearchExhaustedModel.fromJson(data),
        );
      } catch (e, st) {
        log(
          "❌ Error processing ride:search:exhausted: $e\n$st",
          name: "ride search exhausted",
        );
        _rideSearchExhaustedController.addError(
          'Invalid ride search exhausted response',
        );
      }
    };

    _rideUpgradeOfferHandler ??= (dynamic payload) {
      try {
        log('ride upgrade offer payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _rideUpgradeOfferController.add(RideUpgradeOfferModel.fromJson(data));
      } catch (e, st) {
        log(
          "❌ Error processing ride:upgrade:offer: $e\n$st",
          name: "ride upgrade offer",
        );
        _rideUpgradeOfferController.addError(
          'Invalid ride upgrade offer response',
        );
      }
    };

    _rideUpgradeResultHandler ??= (dynamic payload) {
      try {
        log('ride upgrade result payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _rideUpgradeResultController.add(
          RideUpgradeResultModel.fromJson(data),
        );
      } catch (e, st) {
        log(
          "❌ Error processing ride:upgrade:result: $e\n$st",
          name: "ride upgrade result",
        );
        _rideUpgradeResultController.addError(
          'Invalid ride upgrade result response',
        );
      }
    };

    _ridePaymentVerificationHandler ??= (dynamic payload) {
      try {
        log('ride payment verification payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _ridePaymentVerificationController.add(
          PaymentVerificationModel.fromJson(data),
        );
      } catch (e, st) {
        log(
          "❌ Error processing ridePaymentVerification: $e\n$st",
          name: "ride payment verification",
        );
        _ridePaymentVerificationController.addError(
          'Invalid ride payment verification response',
        );
      }
    };

    _carpoolBookingStatusHandler ??= (dynamic payload) {
      try {
        log('carpool booking status payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _carpoolBookingStatusController.add(
          CarpoolBookingStatusModel.fromJson(data),
        );
      } catch (e, st) {
        log(
          "❌ Error processing carpoolBookingStatus: $e\n$st",
          name: "carpool booking status",
        );
        _carpoolBookingStatusController.addError(
          'Invalid carpool booking status response',
        );
      }
    };

    _carpoolRideStartedHandler ??= (dynamic payload) {
      try {
        log('carpool ride started payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _carpoolRideStartedController.add(
          CarpoolRideStartedModel.fromJson(data),
        );
      } catch (e, st) {
        log(
          "❌ Error processing carpoolRideStarted: $e\n$st",
          name: "carpool ride started",
        );
        _carpoolRideStartedController.addError(
          'Invalid carpool ride started response',
        );
      }
    };

    _carpoolPassengerPickedUpHandler ??= (dynamic payload) {
      try {
        log(
          'carpool passenger picked up payload: $payload',
          name: 'ride socket',
        );
        final Map<String, dynamic> data = _toMap(payload);
        _carpoolPassengerPickedUpController.add(
          CarpoolPassengerPickedUpModel.fromJson(data),
        );
      } catch (e, st) {
        log(
          "❌ Error processing carpoolPassengerPickedUp: $e\n$st",
          name: "carpool passenger picked up",
        );
        _carpoolPassengerPickedUpController.addError(
          'Invalid carpool passenger picked up response',
        );
      }
    };

    _carpoolRideCompletedHandler ??= (dynamic payload) {
      try {
        log('carpool ride completed payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _carpoolRideCompletedController.add(
          CarpoolRideCompletedModel.fromJson(data),
        );
      } catch (e, st) {
        log(
          "❌ Error processing carpoolRideCompleted: $e\n$st",
          name: "carpool ride completed",
        );
        _carpoolRideCompletedController.addError(
          'Invalid carpool ride completed response',
        );
      }
    };

    _carpoolStopArrivedHandler ??= (dynamic payload) {
      try {
        log('carpool stop arrived payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _carpoolStopArrivedController.add(
          CarpoolStopArrivedModel.fromJson(data),
        );
      } catch (e, st) {
        log(
          "❌ Error processing carpoolStopArrived: $e\n$st",
          name: "carpool stop arrived",
        );
        _carpoolStopArrivedController.addError(
          'Invalid carpool stop arrived response',
        );
      }
    };

    _carpoolResumeHandler ??= (dynamic payload) {
      try {
        log('carpool resume payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        final CarpoolResumeModel model = CarpoolResumeModel.fromJson(data);
        _lastCarpoolResume = model;
        _carpoolResumeController.add(model);
      } catch (e, st) {
        log(
          "❌ Error processing carpoolResume: $e\n$st",
          name: "carpool resume",
        );
        _carpoolResumeController.addError('Invalid carpool resume response');
      }
    };

    _carpoolPaymentVerificationHandler ??= (dynamic payload) {
      try {
        log(
          'carpool payment verification payload: $payload',
          name: 'ride socket',
        );
        final Map<String, dynamic> data = _toMap(payload);
        _carpoolPaymentVerificationController.add(
          PaymentVerificationModel.fromJson(data),
        );
      } catch (e, st) {
        log(
          "❌ Error processing carpoolPaymentVerification: $e\n$st",
          name: "carpool payment verification",
        );
        _carpoolPaymentVerificationController.addError(
          'Invalid carpool payment verification response',
        );
      }
    };

    _carpoolRouteUpdateHandler ??= (dynamic payload) {
      try {
        log('carpool route update payload: $payload', name: 'ride socket');
        final Map<String, dynamic> data = _toMap(payload);
        _carpoolRouteUpdateController.add(
          CarpoolRouteUpdateModel.fromJson(data),
        );
      } catch (e, st) {
        log(
          "❌ Error processing carpoolRouteUpdate: $e\n$st",
          name: "carpool route update",
        );
        _carpoolRouteUpdateController.addError(
          'Invalid carpool route update response',
        );
      }
    };

    _errorHandler ??= (dynamic payload) {
      final String message = _normalizeErrorMessage(payload);
      _errorController.add(message);
    };

    _chatReceiveHandler ??= (dynamic payload) {
      try {
        log('chat receive payload: $payload', name: 'ride socket');
        if (payload == null) return;
        if (payload is! Map) return;
        final Map<dynamic, dynamic> raw = Map<dynamic, dynamic>.from(payload);
        // Do not use raw['message'] — it is the text body, not the envelope.
        final dynamic nested = raw['data'];
        final Map<String, dynamic> map;
        if (nested is Map) {
          map = Map<String, dynamic>.from(Map<dynamic, dynamic>.from(nested));
        } else if (raw.containsKey('sender') ||
            raw.containsKey('conversationId')) {
          map = Map<String, dynamic>.from(raw);
        } else {
          return;
        }
        _chatReceiveController.add(ChatMessageModel.fromJson(map));
      } catch (e, st) {
        log('❌ Error processing chat:receive: $e\n$st', name: 'ride socket');
        _chatReceiveController.addError('Invalid chat:receive payload');
      }
    };

    _chatStatusUpdateHandler ??= (dynamic payload) {
      try {
        log('chat status update payload: $payload', name: 'ride socket');
        if (payload == null) return;
        final Map<String, dynamic> map = _toMap(payload);
        final dynamic nested = map['data'];
        final Map<String, dynamic> body = nested is Map
            ? Map<String, dynamic>.from(Map<dynamic, dynamic>.from(nested))
            : map;
        final ChatStatusUpdate? update = ChatStatusUpdate.fromJson(body);
        if (update == null) return;
        _chatStatusUpdateController.add(update);
      } catch (e, st) {
        log(
          '❌ Error processing chat:status_updated: $e\n$st',
          name: 'ride socket',
        );
        _chatStatusUpdateController.addError(
          'Invalid chat:status_updated payload',
        );
      }
    };

    // if (!kDebugMode) {
    socketService.on(SocketEvent.rideStatusUpdate, _rideStatusUpdateHandler!);
    // }
    socketService.on(
      SocketEvent.driverLocationUpdate,
      _driverLocationUpdateHandler!,
    );
    socketService.on(SocketEvent.rideResume, _rideResumeHandler!);
    socketService.on(SocketEvent.rideSearchStatus, _rideSearchStatusHandler!);
    socketService.on(
      SocketEvent.rideSearchExhausted,
      _rideSearchExhaustedHandler!,
    );
    socketService.on(SocketEvent.rideUpgradeOffer, _rideUpgradeOfferHandler!);
    socketService.on(SocketEvent.rideUpgradeResult, _rideUpgradeResultHandler!);
    socketService.on(
      SocketEvent.ridePaymentVerification,
      _ridePaymentVerificationHandler!,
    );
    socketService.on(
      SocketEvent.carpoolBookingStatus,
      _carpoolBookingStatusHandler!,
    );
    socketService.on(
      SocketEvent.carpoolRideStarted,
      _carpoolRideStartedHandler!,
    );
    socketService.on(
      SocketEvent.carpoolPassengerPickedUp,
      _carpoolPassengerPickedUpHandler!,
    );
    socketService.on(
      SocketEvent.carpoolRideCompleted,
      _carpoolRideCompletedHandler!,
    );
    socketService.on(
      SocketEvent.carpoolStopArrived,
      _carpoolStopArrivedHandler!,
    );
    socketService.on(
      SocketEvent.carpoolPaymentVerification,
      _carpoolPaymentVerificationHandler!,
    );
    socketService.on(SocketEvent.carpoolResume, _carpoolResumeHandler!);
    socketService.on(
      SocketEvent.carpoolRouteUpdate,
      _carpoolRouteUpdateHandler!,
    );

    socketService.on(SocketEvent.socketError, _errorHandler!);
    _serviceErrorSubscription = socketService.errorStream.listen((
      String error,
    ) {
      _errorController.add(error);
    });
    log('listening on event: ${SocketEvent.rideResume}', name: 'ride socket');
    socketService.on(SocketEvent.chatReceive, _chatReceiveHandler!);
    socketService.on(SocketEvent.chatStatusUpdated, _chatStatusUpdateHandler!);
    log(
      'listening on ride + chat events (incl. ${SocketEvent.chatReceive}, ${SocketEvent.chatStatusUpdated})',
      name: 'ride socket',
    );
  }

  void stop() {
    _serviceErrorSubscription?.cancel();
    _serviceErrorSubscription = null;
    if (_rideStatusUpdateHandler != null) {
      socketService.off(
        SocketEvent.rideStatusUpdate,
        _rideStatusUpdateHandler!,
      );
    }
    if (_driverLocationUpdateHandler != null) {
      socketService.off(
        SocketEvent.driverLocationUpdate,
        _driverLocationUpdateHandler!,
      );
    }
    if (_rideResumeHandler != null) {
      socketService.off(SocketEvent.rideResume, _rideResumeHandler!);
    }
    if (_rideSearchStatusHandler != null) {
      socketService.off(
        SocketEvent.rideSearchStatus,
        _rideSearchStatusHandler!,
      );
    }
    if (_rideSearchExhaustedHandler != null) {
      socketService.off(
        SocketEvent.rideSearchExhausted,
        _rideSearchExhaustedHandler!,
      );
    }
    if (_rideUpgradeOfferHandler != null) {
      socketService.off(SocketEvent.rideUpgradeOffer, _rideUpgradeOfferHandler!);
    }
    if (_rideUpgradeResultHandler != null) {
      socketService.off(
        SocketEvent.rideUpgradeResult,
        _rideUpgradeResultHandler!,
      );
    }
    if (_ridePaymentVerificationHandler != null) {
      socketService.off(
        SocketEvent.ridePaymentVerification,
        _ridePaymentVerificationHandler!,
      );
    }
    if (_carpoolBookingStatusHandler != null) {
      socketService.off(
        SocketEvent.carpoolBookingStatus,
        _carpoolBookingStatusHandler!,
      );
    }
    if (_carpoolRideStartedHandler != null) {
      socketService.off(
        SocketEvent.carpoolRideStarted,
        _carpoolRideStartedHandler!,
      );
    }
    if (_carpoolPassengerPickedUpHandler != null) {
      socketService.off(
        SocketEvent.carpoolPassengerPickedUp,
        _carpoolPassengerPickedUpHandler!,
      );
    }
    if (_carpoolRideCompletedHandler != null) {
      socketService.off(
        SocketEvent.carpoolRideCompleted,
        _carpoolRideCompletedHandler!,
      );
    }
    if (_carpoolStopArrivedHandler != null) {
      socketService.off(
        SocketEvent.carpoolStopArrived,
        _carpoolStopArrivedHandler!,
      );
    }
    if (_carpoolPaymentVerificationHandler != null) {
      socketService.off(
        SocketEvent.carpoolPaymentVerification,
        _carpoolPaymentVerificationHandler!,
      );
    }
    if (_carpoolResumeHandler != null) {
      socketService.off(SocketEvent.carpoolResume, _carpoolResumeHandler!);
    }
    if (_carpoolRouteUpdateHandler != null) {
      socketService.off(
        SocketEvent.carpoolRouteUpdate,
        _carpoolRouteUpdateHandler!,
      );
    }

    if (_errorHandler != null) {
      socketService.off(SocketEvent.socketError, _errorHandler!);
    }
    if (_chatReceiveHandler != null) {
      socketService.off(SocketEvent.chatReceive, _chatReceiveHandler!);
    }
    if (_chatStatusUpdateHandler != null) {
      socketService.off(
        SocketEvent.chatStatusUpdated,
        _chatStatusUpdateHandler!,
      );
    }

    _rideStatusUpdateHandler = null;
    _driverLocationUpdateHandler = null;
    _rideResumeHandler = null;
    _rideSearchStatusHandler = null;
    _rideSearchExhaustedHandler = null;
    _rideUpgradeOfferHandler = null;
    _rideUpgradeResultHandler = null;
    _ridePaymentVerificationHandler = null;

    _carpoolBookingStatusHandler = null;
    _carpoolRideStartedHandler = null;
    _carpoolPassengerPickedUpHandler = null;
    _carpoolRideCompletedHandler = null;
    _carpoolStopArrivedHandler = null;
    _carpoolPaymentVerificationHandler = null;
    _carpoolResumeHandler = null;
    _carpoolRouteUpdateHandler = null;
    _lastCarpoolResume = null;

    _errorHandler = null;
    _chatReceiveHandler = null;
    _chatStatusUpdateHandler = null;
  }

  void dispose() {
    stop();
    if (!_rideStatusUpdateController.isClosed) {
      _rideStatusUpdateController.close();
    }
    if (!_driverLocationUpdateController.isClosed) {
      _driverLocationUpdateController.close();
    }
    if (!_rideResumeController.isClosed) {
      _rideResumeController.close();
    }
    if (!_rideSearchStatusController.isClosed) {
      _rideSearchStatusController.close();
    }
    if (!_rideSearchExhaustedController.isClosed) {
      _rideSearchExhaustedController.close();
    }
    if (!_rideUpgradeOfferController.isClosed) {
      _rideUpgradeOfferController.close();
    }
    if (!_rideUpgradeResultController.isClosed) {
      _rideUpgradeResultController.close();
    }
    if (!_ridePaymentVerificationController.isClosed) {
      _ridePaymentVerificationController.close();
    }
    if (!_carpoolBookingStatusController.isClosed) {
      _carpoolBookingStatusController.close();
    }
    if (!_carpoolResumeController.isClosed) {
      _carpoolResumeController.close();
    }
    if (!_carpoolRouteUpdateController.isClosed) {
      _carpoolRouteUpdateController.close();
    }
    if (!_errorController.isClosed) {
      _errorController.close();
    }
    if (!_chatReceiveController.isClosed) {
      _chatReceiveController.close();
    }
    if (!_chatStatusUpdateController.isClosed) {
      _chatStatusUpdateController.close();
    }
  }

  Map<String, dynamic> _toMap(dynamic payload) {
    if (payload is List) {
      if (payload.isEmpty) return <String, dynamic>{};
      return _toMap(payload.first);
    }
    if (payload is String) {
      final dynamic decoded = _tryParseJson(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw const FormatException('String payload is not valid JSON object');
    }
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    throw FormatException(
      'Unexpected socket payload type: ${payload.runtimeType}',
    );
  }

  dynamic _tryParseJson(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      return null;
    }
  }

  String _normalizeErrorMessage(dynamic payload) {
    if (payload == null) return 'Socket error';
    if (payload is String) {
      final String normalized = payload.trim();
      return normalized.isEmpty ? 'Socket error' : normalized;
    }

    final dynamic decoded = payload is Map || payload is List
        ? payload
        : _tryParseJson(payload.toString());

    if (decoded is Map<String, dynamic>) {
      return _messageFromMap(decoded);
    }
    if (decoded is Map) {
      return _messageFromMap(Map<String, dynamic>.from(decoded));
    }

    final String fallback = payload.toString().trim();
    return fallback.isEmpty ? 'Socket error' : fallback;
  }

  String _messageFromMap(Map<String, dynamic> data) {
    for (final String key in <String>['message', 'error', 'reason']) {
      final String value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return 'Socket error';
  }
}
