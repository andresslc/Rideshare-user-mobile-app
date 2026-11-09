import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/params/cancel_carpool_request_params.dart';
import 'package:ride_app/core/params/complete_carpool_ride_params.dart';
import 'package:ride_app/core/params/find_carpool_ride_params.dart';
import 'package:ride_app/core/params/find_ride_params.dart';
import 'package:ride_app/core/services/sound_service.dart';
import 'package:ride_app/core/utils/stripe_helper.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_booking_status_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_passenger_picked_up_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_resume_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_completed_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_started_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_route_update_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_stop_arrived_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/driver_location_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/joined_carpool_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/payment_verification_entity.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/cancel_carpool_ride_request_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_booking_status_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_passenger_picked_up_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_payment_verification_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_resume_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_ride_completed_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_ride_started_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_route_update_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/carpool_stop_arrived_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/complete_carpool_ride_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/driver_location_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/find_carpool_rides_by_api_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/find_carpool_rides_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_carpool_ride_by_id_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/join_carpool_ride_usecase.dart';
import 'package:ride_app/features/ride_room/enums/ride_enum.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/carpool_state.dart';

final carpoolProvider = NotifierProvider<CarpoolController, CarpoolState>(
  CarpoolController.new,
);

class CarpoolController extends Notifier<CarpoolState> {
  late FindCarpoolRidesUseCase _findCarpoolRidesUseCase;
  late FindCarpoolRidesByApiUseCase _findCarpoolRidesByApiUseCase;
  late JoinCarpoolRideUseCase _joinCarpoolRideUseCase;
  late CancelCarpoolRideRequestUseCase _cancelCarpoolRideRequestUseCase;
  late CompleteCarpoolRideUseCase _completeCarpoolRideUseCase;
  late CarpoolBookingStatusUpdatesUseCase _carpoolBookingStatusUpdatesUseCase;
  late CarpoolPassengerPickedUpUpdatesUseCase
  _carpoolPassengerPickedUpUpdatesUseCase;
  late CarpoolPaymentVerificationUpdatesUseCase
  _carpoolPaymentVerificationUpdatesUseCase;
  late CarpoolRideCompletedUpdatesUseCase _carpoolRideCompletedUpdatesUseCase;
  late CarpoolRideStartedUpdatesUseCase _carpoolRideStartedUpdatesUseCase;
  late CarpoolStopArrivedUpdatesUseCase _carpoolStopArrivedUpdatesUseCase;
  late CarpoolResumeUpdatesUseCase _carpoolResumeUpdatesUseCase;
  late DriverLocationUpdatesUseCase _driverLocationUpdatesUseCase;
  late CarpoolRouteUpdateUpdatesUseCase _carpoolRouteUpdateUpdatesUseCase;
  late GetCarpoolRideByIdUseCase _getCarpoolRideByIdUseCase;
  StreamSubscription? _carpoolBookingStatusSub;
  StreamSubscription? _carpoolPassengerPickedUpSub;
  StreamSubscription? _carpoolPaymentVerificationSub;
  StreamSubscription? _carpoolRideCompletedSub;
  StreamSubscription? _carpoolRideStartedSub;
  StreamSubscription? _carpoolStopArrivedSub;
  StreamSubscription? _carpoolResumeSub;
  StreamSubscription? _driverLocationSub;
  StreamSubscription? _carpoolRouteUpdateSub;
  int _requestToken = 0;
  final Set<String> _confirmedPaymentIntentIds = <String>{};

  @override
  CarpoolState build() {
    _findCarpoolRidesUseCase = locator<FindCarpoolRidesUseCase>();
    _findCarpoolRidesByApiUseCase = locator<FindCarpoolRidesByApiUseCase>();
    _joinCarpoolRideUseCase = locator<JoinCarpoolRideUseCase>();
    _cancelCarpoolRideRequestUseCase =
        locator<CancelCarpoolRideRequestUseCase>();
    _completeCarpoolRideUseCase = locator<CompleteCarpoolRideUseCase>();
    _carpoolBookingStatusUpdatesUseCase =
        locator<CarpoolBookingStatusUpdatesUseCase>();
    _carpoolPassengerPickedUpUpdatesUseCase =
        locator<CarpoolPassengerPickedUpUpdatesUseCase>();
    _carpoolPaymentVerificationUpdatesUseCase =
        locator<CarpoolPaymentVerificationUpdatesUseCase>();
    _carpoolRideCompletedUpdatesUseCase =
        locator<CarpoolRideCompletedUpdatesUseCase>();
    _carpoolRideStartedUpdatesUseCase =
        locator<CarpoolRideStartedUpdatesUseCase>();
    _carpoolStopArrivedUpdatesUseCase =
        locator<CarpoolStopArrivedUpdatesUseCase>();
    _carpoolResumeUpdatesUseCase = locator<CarpoolResumeUpdatesUseCase>();
    _driverLocationUpdatesUseCase = locator<DriverLocationUpdatesUseCase>();
    _carpoolRouteUpdateUpdatesUseCase =
        locator<CarpoolRouteUpdateUpdatesUseCase>();
    _getCarpoolRideByIdUseCase = locator<GetCarpoolRideByIdUseCase>();
    _startListeners();
    ref.onDispose(() async {
      await _carpoolBookingStatusSub?.cancel();
      await _carpoolPassengerPickedUpSub?.cancel();
      await _carpoolPaymentVerificationSub?.cancel();
      await _carpoolRideCompletedSub?.cancel();
      await _carpoolRideStartedSub?.cancel();
      await _carpoolStopArrivedSub?.cancel();
      await _carpoolResumeSub?.cancel();
      await _driverLocationSub?.cancel();
      await _carpoolRouteUpdateSub?.cancel();
    });
    return const CarpoolState();
  }

  void _startListeners() {
    _carpoolBookingStatusSub?.cancel();
    _carpoolBookingStatusSub = _carpoolBookingStatusUpdatesUseCase
        .call()
        .listen((either) {
          either.fold(
            (failure) {
              state = state.copyWith(errorMessage: failure.message);
            },
            (event) {
              unawaited(_handleBookingStatusEvent(event));
            },
          );
        });

    _carpoolPassengerPickedUpSub?.cancel();
    _carpoolPassengerPickedUpSub = _carpoolPassengerPickedUpUpdatesUseCase
        .call()
        .listen((either) {
          either.fold(
            (failure) {
              state = state.copyWith(errorMessage: failure.message);
            },
            (event) {
              unawaited(_handlePassengerPickedUpEvent(event));
            },
          );
        });

    _carpoolPaymentVerificationSub?.cancel();
    _carpoolPaymentVerificationSub = _carpoolPaymentVerificationUpdatesUseCase
        .call()
        .listen((either) {
          either.fold(
            (failure) {
              state = state.copyWith(errorMessage: failure.message);
            },
            (event) {
              unawaited(_handleCarpoolPaymentVerification(event));
            },
          );
        });

    _carpoolRideCompletedSub?.cancel();
    _carpoolRideCompletedSub = _carpoolRideCompletedUpdatesUseCase
        .call()
        .listen((either) {
          either.fold(
            (failure) {
              state = state.copyWith(errorMessage: failure.message);
            },
            (event) {
              unawaited(_handleRideCompletedEvent(event));
            },
          );
        });

    _carpoolRideStartedSub?.cancel();
    _carpoolRideStartedSub = _carpoolRideStartedUpdatesUseCase.call().listen((
      either,
    ) {
      either.fold(
        (failure) {
          state = state.copyWith(errorMessage: failure.message);
        },
        (event) {
          unawaited(_handleRideStartedEvent(event));
        },
      );
    });

    _carpoolStopArrivedSub?.cancel();
    _carpoolStopArrivedSub = _carpoolStopArrivedUpdatesUseCase.call().listen((
      either,
    ) {
      either.fold(
        (failure) {
          state = state.copyWith(errorMessage: failure.message);
        },
        (event) {
          _handleStopArrivedEvent(event);
        },
      );
    });

    _carpoolResumeSub?.cancel();
    _carpoolResumeSub = _carpoolResumeUpdatesUseCase.call().listen((either) {
      either.fold(
        (failure) {
          state = state.copyWith(errorMessage: failure.message);
        },
        (event) {
          unawaited(restoreRequestedRideFromResume(event));
        },
      );
    });

    _driverLocationSub?.cancel();
    _driverLocationSub = _driverLocationUpdatesUseCase.call().listen((either) {
      either.fold(
        (failure) {
          state = state.copyWith(errorMessage: failure.message);
        },
        (event) {
          _handleDriverLocationEvent(event);
        },
      );
    });

    _carpoolRouteUpdateSub?.cancel();
    _carpoolRouteUpdateSub = _carpoolRouteUpdateUpdatesUseCase.call().listen((
      either,
    ) {
      either.fold(
        (failure) {
          state = state.copyWith(errorMessage: failure.message);
        },
        (event) {
          unawaited(_handleRouteUpdateEvent(event));
        },
      );
    });
  }

  Future<void> restoreRequestedRideFromResume(CarpoolResumeEntity event) async {
    final String bookingId = event.bookingId.trim();
    final String carpoolId = event.carpoolId.trim();
    final String type = event.type.trim().toLowerCase();
    final String role = event.role.trim().toLowerCase();

    if (role != 'passenger') return;
    if (type != 'pending' && type != 'accepted' && type != 'in_progress') {
      return;
    }
    if (bookingId.isEmpty || carpoolId.isEmpty) return;

    final CarpoolRideEntity? ride = await _getRequestedRideById(carpoolId);
    if (ride == null) return;

    state = state.copyWith(
      currentCarpoolId: ride.id,
      requestedRide: ride,
      joinedCarpool: JoinedCarpoolEntity(
        bookingId: bookingId,
        message: event.message,
      ),
      requestStatus: event.otpVerified
          ? CarpoolRequestStatus.inProgress
          : _requestStatusFromType(type),
      otpVerified: event.otpVerified,
      rideOtp: type == 'pending'
          ? ''
          : (ride.otp.trim().isNotEmpty ? ride.otp.trim() : state.rideOtp),
      clearError: true,
    );
    ref
        .read(rideRoomProvider.notifier)
        .applyPersistedRideChatBadge(currentScopeKey: 'carpool:$bookingId');
  }

  Future<void> _handleBookingStatusEvent(
    CarpoolBookingStatusEntity event,
  ) async {
    final String bookingId = event.bookingId.trim();
    final String status = event.status.trim().toLowerCase();
    if (bookingId.isEmpty) return;
    if (state.bookingId.trim().isNotEmpty && state.bookingId != bookingId) {
      return;
    }

    if (status == 'rejected' || status == 'cancelled') {
      locator<SoundService>().playRideCancelledSound();
      final String fallbackMessage = status == 'cancelled'
          ? 'Carpool request was cancelled.'
          : 'Carpool request was rejected by the driver.';
      final String reason = event.reason.trim();
      state = state.copyWith(
        actionMessage: reason.isNotEmpty ? reason : fallbackMessage,
        clearRequestedRide: true,
        clearError: true,
      );
      ref
          .read(rideRoomProvider.notifier)
          .updateCurrentSheet(RideSheetsType.whereToGoSheet);
      ref.read(mapProvider.notifier).clearRideMapData();
      ref.read(rideRoomProvider.notifier).clearRideChatBadgePersistence();
      return;
    }

    if (status != 'accepted') return;

    locator<SoundService>().playRideAcceptedSound();

    final String carpoolId = state.currentCarpoolId.trim().isNotEmpty
        ? state.currentCarpoolId.trim()
        : (state.requestedRide?.id.trim() ?? '');
    CarpoolRideEntity? ride;
    if (carpoolId.isNotEmpty) {
      ride = await _getRequestedRideById(carpoolId);
    }
    ride ??= state.requestedRide;
    if (ride == null) return;

    state = state.copyWith(
      currentCarpoolId: ride.id,
      requestedRide: ride,
      joinedCarpool:
          state.joinedCarpool ??
          JoinedCarpoolEntity(bookingId: bookingId, message: ''),
      requestStatus: CarpoolRequestStatus.accepted,
      otpVerified: false,
      rideOtp: event.otp.trim(),
      actionMessage: 'Carpool request accepted.',
      clearError: true,
    );
  }

  Future<void> _handleRouteUpdateEvent(CarpoolRouteUpdateEntity event) async {
    final String carpoolId = event.carpoolId.trim();
    final String status = event.status.trim().toLowerCase();
    if (carpoolId.isEmpty) return;
    if (state.currentCarpoolId.trim().isNotEmpty &&
        state.currentCarpoolId != carpoolId) {
      return;
    }

    if (status == 'cancelled') {
      locator<SoundService>().playRideCancelledSound();
      state = state.copyWith(
        actionMessage: 'Carpool was cancelled by the driver',
        clearRequestedRide: true,
        clearError: true,
      );
      ref
          .read(rideRoomProvider.notifier)
          .updateCurrentSheet(RideSheetsType.whereToGoSheet);
      ref.read(mapProvider.notifier).clearRideMapData();
      ref.read(rideRoomProvider.notifier).clearRideChatBadgePersistence();
    }
  }

  Future<void> _handlePassengerPickedUpEvent(
    CarpoolPassengerPickedUpEntity event,
  ) async {
    if (!event.otpVerified) return;
    if (event.bookingId.trim().isNotEmpty &&
        event.bookingId.trim() != state.bookingId.trim()) {
      return;
    }

    final String carpoolId = event.carpoolId.trim();
    if (carpoolId.isEmpty) return;

    CarpoolRideEntity? ride = state.requestedRide;
    if (ride == null || ride.id != carpoolId) {
      ride = await _getRequestedRideById(carpoolId);
    }
    if (ride == null) return;

    locator<SoundService>().playRideStartedSound();
    state = state.copyWith(
      currentCarpoolId: ride.id,
      requestedRide: ride,
      requestStatus: CarpoolRequestStatus.inProgress,
      otpVerified: true,
      rideOtp: ride.otp.trim().isNotEmpty ? ride.otp.trim() : state.rideOtp,
      clearError: true,
    );
  }

  Future<void> _handleCarpoolPaymentVerification(
    PaymentVerificationEntity event,
  ) async {
    if (!event.requiresAction) return;

    final String clientSecret = event.clientSecret.trim();
    if (clientSecret.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Carpool payment verification is required, but client secret is missing.',
      );
      return;
    }

    final String paymentIntentId = event.paymentIntentId.trim();
    if (paymentIntentId.isNotEmpty &&
        _confirmedPaymentIntentIds.contains(paymentIntentId)) {
      return;
    }
    if (paymentIntentId.isNotEmpty) {
      _confirmedPaymentIntentIds.add(paymentIntentId);
    }

    String? failureMessage;
    await StripeHelper.confirmWalletTopUp(
      clientSecret: clientSecret,
      paymentMethodId: paymentIntentId,
      onSuccess: () {},
      onFailure: (String error) {
        failureMessage = error;
      },
    );

    if (failureMessage != null) {
      state = state.copyWith(errorMessage: failureMessage);
    }
  }

  Future<void> _handleRideStartedEvent(CarpoolRideStartedEntity event) async {
    final String carpoolId = event.carpoolId.trim();
    final String status = event.status.trim().toLowerCase();
    if (status != 'in_progress' || carpoolId.isEmpty) return;

    CarpoolRideEntity? ride = state.requestedRide;
    if (ride == null || ride.id != carpoolId) {
      ride = await _getRequestedRideById(carpoolId);
    }
    if (ride == null) return;

    locator<SoundService>().playRideStartedSound();
    state = state.copyWith(
      currentCarpoolId: ride.id,
      requestedRide: ride,
      requestStatus: CarpoolRequestStatus.inProgress,
      otpVerified: false,
      rideOtp: ride.otp.trim().isNotEmpty ? ride.otp.trim() : state.rideOtp,
      actionMessage: event.message.trim().isEmpty
          ? 'Your carpool ride has started!'
          : event.message,
      clearError: true,
    );
  }

  Future<void> _handleRideCompletedEvent(
    CarpoolRideCompletedEntity event,
  ) async {
    final String currentBookingId = state.bookingId.trim();
    final String eventBookingId = event.bookingId.trim();
    if (currentBookingId.isNotEmpty &&
        eventBookingId.isNotEmpty &&
        currentBookingId != eventBookingId) {
      return;
    }

    final String carpoolId = event.carpoolId.trim();
    if (carpoolId.isEmpty) return;

    CarpoolRideEntity? ride = state.requestedRide;
    if (ride == null || ride.id != carpoolId) {
      ride = await _getRequestedRideById(carpoolId);
    }
    if (ride == null) return;

    locator<SoundService>().playRideCompletedSound();
    state = state.copyWith(
      currentCarpoolId: ride.id,
      requestedRide: ride,
      requestStatus: CarpoolRequestStatus.completed,
      completedRide: event,
      isCompletingRide: false,
      clearError: true,
    );
    ref.read(rideRoomProvider.notifier).clearRideChatBadgePersistence();
    final mapNotifier = ref.read(mapProvider.notifier);
    mapNotifier.clearRideMapData();
    unawaited(mapNotifier.refreshCurrentLocation(moveCamera: true));
  }

  void _handleStopArrivedEvent(CarpoolStopArrivedEntity event) {
    final CarpoolRideEntity? ride = state.requestedRide;
    final CarpoolRideStopEntity? arrivedStop = event.arrivedStop;
    if (ride == null || arrivedStop == null) return;

    final String carpoolId = event.carpoolId.trim();
    if (carpoolId.isEmpty || ride.id != carpoolId) return;

    locator<SoundService>().playDriverArrivedSound();

    final CarpoolRideStopEntity? nextStop = event.nextStop;
    final List<CarpoolRideStopEntity> updatedRoutes = ride.routes.map((
      CarpoolRideStopEntity stop,
    ) {
      if (stop.id == arrivedStop.id) {
        return stop.copyWith(
          placeName: arrivedStop.placeName,
          location: arrivedStop.location,
          status: arrivedStop.status,
          order: arrivedStop.order,
        );
      }
      if (nextStop != null && stop.id == nextStop.id) {
        return stop.copyWith(
          placeName: nextStop.placeName,
          location: nextStop.location,
          status: nextStop.status,
          order: nextStop.order,
        );
      }
      return stop;
    }).toList();

    state = state.copyWith(
      requestedRide: ride.copyWith(routes: updatedRoutes),
      clearError: true,
    );
  }

  void _handleDriverLocationEvent(DriverLocationEntity event) {
    final CarpoolRideEntity? ride = state.requestedRide;
    final String driverId = ride?.driver?.id.trim() ?? '';
    if (driverId.isEmpty) return;
    if (event.driver.trim().isNotEmpty && event.driver.trim() != driverId) {
      return;
    }

    state = state.copyWith(latestDriverLocation: event, clearError: true);
  }

  Future<CarpoolRideEntity?> _getRequestedRideById(String carpoolId) async {
    final result = await _getCarpoolRideByIdUseCase.call(carpoolId);
    return result.fold((failure) {
      state = state.copyWith(errorMessage: failure.message);
      return null;
    }, (ride) => ride);
  }

  Future<void> searchBySocket(FindRideParams params) async {
    final int token = ++_requestToken;
    state = state.copyWith(
      status: CarpoolSearchStatus.searchingSocket,
      params: params,
      clearError: true,
      clearRides: true,
    );

    final result = await _findCarpoolRidesUseCase.call(
      _toCarpoolParams(params),
    );
    if (token != _requestToken) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          status: CarpoolSearchStatus.error,
          errorMessage: failure.message,
          clearRides: true,
        );
      },
      (response) {
        if (response.rides.isNotEmpty) {
          locator<SoundService>().playOfferReceivedSound();
        }
        state = state.copyWith(
          status: response.rides.isEmpty
              ? CarpoolSearchStatus.empty
              : CarpoolSearchStatus.loaded,
          params: params,
          rides: response.rides,
          clearError: true,
          clearActionMessage: true,
        );
      },
    );
  }

  Future<void> refreshByApi() async {
    final FindRideParams? params = state.params;
    if (params == null || state.hasRides) return;

    final int token = ++_requestToken;
    state = state.copyWith(
      status: CarpoolSearchStatus.searchingApi,
      clearError: true,
    );

    final result = await _findCarpoolRidesByApiUseCase.call(
      _toCarpoolParams(params),
    );
    if (token != _requestToken) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          status: CarpoolSearchStatus.error,
          errorMessage: failure.message,
        );
      },
      (response) {
        if (response.rides.isNotEmpty) {
          locator<SoundService>().playOfferReceivedSound();
        }
        state = state.copyWith(
          status: response.rides.isEmpty
              ? CarpoolSearchStatus.empty
              : CarpoolSearchStatus.loaded,
          rides: response.rides,
          clearError: true,
          clearActionMessage: true,
        );
      },
    );
  }

  Future<bool> joinRide(CarpoolRideEntity ride) async {
    final FindRideParams? params = state.params;
    if (params == null || state.isJoiningRequest) return false;

    state = state.copyWith(
      isJoiningRequest: true,
      clearError: true,
      clearActionMessage: true,
    );

    final result = await _joinCarpoolRideUseCase.call(
      _toCarpoolParams(params, carpoolId: ride.id),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isJoiningRequest: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (joined) {
        state = state.copyWith(
          isJoiningRequest: false,
          currentCarpoolId: ride.id,
          requestedRide: ride,
          joinedCarpool: joined,
          requestStatus: CarpoolRequestStatus.pending,
          otpVerified: false,
          rideOtp: '',
          actionMessage: joined.message,
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<bool> cancelRequestedRide() async {
    if (state.isCancellingRequest || state.bookingId.trim().isEmpty) {
      return false;
    }

    state = state.copyWith(
      isCancellingRequest: true,
      clearError: true,
      clearActionMessage: true,
    );

    final result = await _cancelCarpoolRideRequestUseCase.call(
      CancelCarpoolRequestParams(bookingId: state.bookingId),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isCancellingRequest: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (response) {
        ref.read(rideRoomProvider.notifier).clearRideChatBadgePersistence();
        state = state.copyWith(
          isCancellingRequest: false,
          clearRequestedRide: true,
          actionMessage: response.message,
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<bool> completeRide() async {
    if (state.isCompletingRide ||
        state.bookingId.trim().isEmpty ||
        !state.otpVerified ||
        state.isCompleted) {
      return false;
    }

    state = state.copyWith(
      isCompletingRide: true,
      clearError: true,
      clearActionMessage: true,
    );

    final result = await _completeCarpoolRideUseCase.call(
      CompleteCarpoolRideParams(bookingId: state.bookingId),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isCompletingRide: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (response) {
        state = state.copyWith(
          isCompletingRide: false,
          actionMessage: response.message,
          clearError: true,
        );
        return true;
      },
    );
  }

  void reset() {
    _requestToken++;
    _confirmedPaymentIntentIds.clear();
    ref.read(rideRoomProvider.notifier).clearRideChatBadgePersistence();
    final mapNotifier = ref.read(mapProvider.notifier);
    mapNotifier.clearRideMapData();
    unawaited(mapNotifier.refreshCurrentLocation(moveCamera: true));
    state = const CarpoolState();
  }

  void clearCompletedRide() {
    _requestToken++;
    _confirmedPaymentIntentIds.clear();
    ref.read(rideRoomProvider.notifier).clearRideChatBadgePersistence();
    final mapNotifier = ref.read(mapProvider.notifier);
    mapNotifier.clearRideMapData();
    unawaited(mapNotifier.refreshCurrentLocation(moveCamera: true));
    state = const CarpoolState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  FindCarpoolRideParams _toCarpoolParams(
    FindRideParams params, {
    String carpoolId = '',
  }) {
    return FindCarpoolRideParams(
      carpoolId: carpoolId,
      pickupPoint: FindRidePointParams(
        placeName: params.pickupPoint.placeName,
        location: FindRideLocationParams(
          type: params.pickupPoint.location.type,
          coordinates: params.pickupPoint.location.coordinates,
        ),
      ),
      dropOffPoint: FindRidePointParams(
        placeName: params.dropOffPoint.placeName,
        location: FindRideLocationParams(
          type: params.dropOffPoint.location.type,
          coordinates: params.dropOffPoint.location.coordinates,
        ),
      ),
      requiredSeats: params.requiredSeats,
      avgTime: params.averageTime,
      distance: params.rideDistance,
      fare: params.rideFare,
      // Carpool always books against a payment method; a free ride only skips
      // the rail on the normal dispatch flow.
      paymentMethod: params.paymentMethod ?? PaymentMethod.attached_card.name,
      codeId: params.codeId,
      campaignId: params.campaignId,
      originalFare: params.originalRideFare,
      discountAmount: params.discountAmount,
    );
  }

  CarpoolRequestStatus _requestStatusFromType(String type) {
    switch (type) {
      case 'accepted':
        return CarpoolRequestStatus.accepted;
      case 'in_progress':
        return CarpoolRequestStatus.inProgress;
      case 'completed':
        return CarpoolRequestStatus.completed;
      default:
        return CarpoolRequestStatus.pending;
    }
  }
}
