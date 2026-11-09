import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/l10n/current_app_localizations.dart';
import 'package:ride_app/core/params/cancel_ride_params.dart';
import 'package:ride_app/core/params/current_location_params.dart';
import 'package:ride_app/core/params/find_ride_params.dart';
import 'package:ride_app/core/services/location_service.dart';
import 'package:ride_app/core/services/sound_service.dart';
import 'package:ride_app/core/utils/stripe_helper.dart';
import 'package:ride_app/features/chat/data/models/chat_message_model.dart';
import 'package:ride_app/features/ride_room/domain/entities/driver_location_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/payment_verification_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_search_exhausted_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_search_status_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_upgrade_entity.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/cancel_ride_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/connect_ride_socket_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/disconnect_ride_socket_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/driver_location_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/find_ride_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_carpool_ride_url_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_ride_by_id_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_ride_url_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_payment_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_resume_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_search_exhausted_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_search_status_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_status_updates_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/ride_upgrade_usecases.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/send_location_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/socket_errors_usecase.dart';
import 'package:ride_app/features/ride_room/enums/ride_enum.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_eta_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';
import 'package:ride_app/l10n/app_localizations.dart';

import '../../../../core/services/socket_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/use_cases/get_socket_status_usecase.dart';

final rideRoomProvider = NotifierProvider<RideRoomController, RideRoomState>(
  RideRoomController.new,
);

class RideRoomController extends Notifier<RideRoomState> {
  late ConnectRideSocketUseCase _connectRideSocketUseCase;
  late DisconnectRideSocketUseCase _disconnectRideSocketUseCase;
  late FindRideUseCase _findRideUseCase;
  late CancelRideUseCase _cancelRideUseCase;
  late RideStatusUpdatesUseCase _rideStatusUpdatesUseCase;
  late DriverLocationUpdatesUseCase _driverLocationUpdatesUseCase;
  late RideResumeUpdatesUseCase _rideResumeUpdatesUseCase;
  late RidePaymentUpdatesUseCase _ridePaymentUpdatesUseCase;
  late GetShareRideUrlUseCase _getShareRideUrlUseCase;
  late GetShareCarpoolRideUrlUseCase _getShareCarpoolRideUrlUseCase;
  late RideSearchStatusUpdatesUseCase _rideSearchStatusUpdatesUseCase;
  late RideSearchExhaustedUpdatesUseCase _rideSearchExhaustedUpdatesUseCase;
  late RideUpgradeOfferUpdatesUseCase _rideUpgradeOfferUpdatesUseCase;
  late RideUpgradeResultUpdatesUseCase _rideUpgradeResultUpdatesUseCase;
  late DecideRideUpgradeUseCase _decideRideUpgradeUseCase;
  late SocketErrorsUseCase _socketErrorsUseCase;
  late GetRideByIdUseCase _getRideByIdUseCase;
  late SendCurrentLocationUseCase _sendCurrentLocationUseCase;
  late GetSocketStatusUseCase _getSocketStatusUseCase;

  StreamSubscription? _rideStatusSub;
  StreamSubscription? _driverLocationSub;
  StreamSubscription? _rideResumeSub;
  StreamSubscription? _rideSearchStatusSub;
  StreamSubscription? _rideSearchExhaustedSub;
  StreamSubscription? _rideUpgradeOfferSub;
  StreamSubscription? _rideUpgradeResultSub;
  StreamSubscription? _ridePaymentSub;
  StreamSubscription? _socketErrorSub;
  StreamSubscription? _socketStatusSub;
  StreamSubscription? _userLocationSub;

  Position? _lastSentPosition;
  DateTime? _lastSentTime;
  Timer? _permissionCheckTimer;

  final Set<String> _confirmedPaymentIntentIds = <String>{};
  FindRideParams? _lastFindRideParams;
  bool _isRetryingFindRideAfterDriverCancel = false;
  bool _isUserCancelInProgress = false;
  int _mapSyncToken = 0;
  int? _carpoolDummyRunId;

  AppLocalizations get _l10n => currentAppLocalizations();

  @override
  RideRoomState build() {
    _connectRideSocketUseCase = locator<ConnectRideSocketUseCase>();
    _disconnectRideSocketUseCase = locator<DisconnectRideSocketUseCase>();
    _findRideUseCase = locator<FindRideUseCase>();
    _cancelRideUseCase = locator<CancelRideUseCase>();
    _rideStatusUpdatesUseCase = locator<RideStatusUpdatesUseCase>();
    _driverLocationUpdatesUseCase = locator<DriverLocationUpdatesUseCase>();
    _rideResumeUpdatesUseCase = locator<RideResumeUpdatesUseCase>();
    _ridePaymentUpdatesUseCase = locator<RidePaymentUpdatesUseCase>();
    _getShareRideUrlUseCase = locator<GetShareRideUrlUseCase>();
    _getShareCarpoolRideUrlUseCase = locator<GetShareCarpoolRideUrlUseCase>();
    _rideSearchStatusUpdatesUseCase = locator<RideSearchStatusUpdatesUseCase>();
    _rideSearchExhaustedUpdatesUseCase =
        locator<RideSearchExhaustedUpdatesUseCase>();
    _rideUpgradeOfferUpdatesUseCase = locator<RideUpgradeOfferUpdatesUseCase>();
    _rideUpgradeResultUpdatesUseCase =
        locator<RideUpgradeResultUpdatesUseCase>();
    _decideRideUpgradeUseCase = locator<DecideRideUpgradeUseCase>();
    _socketErrorsUseCase = locator<SocketErrorsUseCase>();
    _getRideByIdUseCase = locator<GetRideByIdUseCase>();
    _getSocketStatusUseCase = locator<GetSocketStatusUseCase>();
    _sendCurrentLocationUseCase = locator<SendCurrentLocationUseCase>();

    ref.onDispose(() {
      unawaited(_cancelSubscriptions());
      unawaited(_disconnectRideSocketUseCase.call());
    });

    return const RideRoomState();
  }

  // update current sheet
  void updateCurrentSheet(RideSheetsType sheet) {
    state = state.copyWith(currentSheet: sheet);
  }

  /// Shows the "Finding rides" sheet for carpool before navigating to available rides.
  void showCarpoolFindingSheet(FindRideParams params) {
    clearRideChatBadgePersistence();
    _resetSearchProgress();
    state = state.copyWith(
      currentSheet: RideSheetsType.findingDriverSheet,
      currentRideType: RideType.requested,
      status: RideRoomStatus.success,
      rideRequestId: 'carpool-finding-${DateTime.now().millisecondsSinceEpoch}',
      pendingCarpoolParams: params,
      clearError: true,
      showBadge: false,
      isChatOpen: false,
    );
  }

  void clearPendingCarpoolParams() {
    state = state.copyWith(clearPendingCarpoolParams: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void setDraftSpecialRequest(String value) {
    state = state.copyWith(draftSpecialRequest: value);
  }

  void clearDraftSpecialRequest() {
    state = state.copyWith(clearDraftSpecialRequest: true);
  }

  Future<void> connectRideSocket() async {
    // if (state.isSocketInitialized) return;

    state = state.copyWith(status: RideRoomStatus.loading, clearError: true);

    final result = await _connectRideSocketUseCase.call();

    result.fold(
      (failure) {
        state = state.copyWith(
          status: RideRoomStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        _startListeners();
        state = state.copyWith(
          status: RideRoomStatus.success,
          isSocketInitialized: true,
          clearError: true,
        );
      },
    );
  }

  Future<void> findRide(FindRideParams params) async {
    _lastFindRideParams = params;
    _resetSearchProgress();
    clearRideChatBadgePersistence();
    ref.read(rideEtaProvider.notifier).clearEta();
    state = state.copyWith(
      status: RideRoomStatus.loading,
      clearError: true,
      showBadge: false,
      isChatOpen: false,
    );

    try {
      final result = await _findRideUseCase.call(params);

      result.fold(
        (failure) {
          debugPrint(locator<StorageService>().getToken);
          state = state.copyWith(
            status: RideRoomStatus.error,
            errorMessage: failure.message,
          );
        },
        (rideRequest) {
          // A brand-new request starts from a clean slate. `copyWith` cannot
          // null a field, so the previous ride's driver, status and location
          // would survive here — and every event names its ride now, so a
          // stale id would make the app drop the new ride's own updates.
          //
          // The ack already carries the first ring, which runs inline with the
          // request, so the search starts on screen with real numbers.
          state = RideRoomState(
            currentSheet: RideSheetsType.findingDriverSheet,
            currentRideType: RideType.requested,
            status: RideRoomStatus.success,
            isSocketInitialized: state.isSocketInitialized,
            rideRequestId: rideRequest.rideId,
            searchStatus: rideRequest.searchStatus,
            searchCategory: params.category,
            searchFare: params.rideFare,
            draftSpecialRequest: state.draftSpecialRequest,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: RideRoomStatus.error,
        errorMessage: _l10n.somethingWentWrong,
      );
    }
  }

  void setStatusToInitial() {
    state = state.copyWith(status: RideRoomStatus.initial);
  }

  /// Starts a carpool flow using dummy data (no sockets). Progresses through:
  /// Finding driver → Accepted (driver on the way) → Arrived → In progress → Completed.
  Future<void> startCarpoolDummyFlow(FindRideParams params) async {
    final runId = DateTime.now().millisecondsSinceEpoch;
    _carpoolDummyRunId = runId;

    final String rideRequestId = 'carpool-dummy-$runId';
    clearRideChatBadgePersistence();
    state = state.copyWith(
      currentSheet: RideSheetsType.findingDriverSheet,
      currentRideType: RideType.requested,
      status: RideRoomStatus.success,
      rideRequestId: rideRequestId,
      clearError: true,
      showBadge: false,
      isChatOpen: false,
    );

    RideEntity dummyRide = _buildDummyRideEntity(
      params,
      rideRequestId,
      'requested',
    );

    const stepDelay = Duration(seconds: 5);

    await Future.delayed(stepDelay);
    if (_carpoolDummyRunId != runId ||
        state.currentRideType == RideType.cancelled ||
        state.currentSheet == RideSheetsType.whereToGoSheet) {
      return;
    }

    dummyRide = _buildDummyRideEntity(params, rideRequestId, 'accepted');
    final acceptedResponse = RideResponseEntity(
      type: 'accepted',
      message: _l10n.ride_accepted_successfully,
      ride: dummyRide,
      rideOtp: '1234',
      rideId: rideRequestId,
    );
    state = state.copyWith(
      currentRideType: RideType.accepted,
      currentSheet: RideSheetsType.onGoingRideStatusSheet,
      status: RideRoomStatus.success,
      activeRide: dummyRide,
      latestRideStatus: acceptedResponse,
      rideOTP: '1234',
      clearError: true,
    );
    unawaited(_syncActiveRideMapState());

    await Future.delayed(stepDelay);
    if (_carpoolDummyRunId != runId ||
        state.currentRideType == RideType.cancelled ||
        state.currentSheet == RideSheetsType.whereToGoSheet) {
      return;
    }

    dummyRide = _buildDummyRideEntity(params, rideRequestId, 'arrived');
    final arrivedResponse = RideResponseEntity(
      type: 'arrived',
      message: _l10n.driver_arrived_at_pickup,
      ride: dummyRide,
      rideOtp: '1234',
      rideId: rideRequestId,
    );
    state = state.copyWith(
      currentRideType: RideType.arrived,
      currentSheet: RideSheetsType.driverArrivedSheet,
      status: RideRoomStatus.success,
      activeRide: dummyRide,
      latestRideStatus: arrivedResponse,
      clearError: true,
    );
    unawaited(_syncActiveRideMapState());

    await Future.delayed(const Duration(seconds: 5));
    if (_carpoolDummyRunId != runId ||
        state.currentRideType == RideType.cancelled ||
        state.currentSheet == RideSheetsType.whereToGoSheet) {
      return;
    }

    dummyRide = _buildDummyRideEntity(params, rideRequestId, 'inprogress');
    final inProgressResponse = RideResponseEntity(
      type: 'inprogress',
      message: _l10n.ride_started,
      ride: dummyRide,
      rideOtp: '1234',
      rideId: rideRequestId,
    );
    state = state.copyWith(
      currentRideType: RideType.inprogress,
      currentSheet: RideSheetsType.onGoingRideStatusSheet,
      status: RideRoomStatus.success,
      activeRide: dummyRide,
      latestRideStatus: inProgressResponse,
      clearError: true,
    );
    unawaited(_syncActiveRideMapState());

    await Future.delayed(const Duration(seconds: 8));
    if (_carpoolDummyRunId != runId ||
        state.currentRideType == RideType.cancelled ||
        state.currentSheet == RideSheetsType.whereToGoSheet) {
      return;
    }

    dummyRide = _buildDummyRideEntity(params, rideRequestId, 'completed');
    final completedResponse = RideResponseEntity(
      type: 'completed',
      message: _l10n.reached_destination,
      ride: dummyRide,
      rideOtp: '1234',
      rideId: rideRequestId,
    );
    state = state.copyWith(
      currentRideType: RideType.completed,
      currentSheet: RideSheetsType.whereToGoSheet,
      status: RideRoomStatus.success,
      activeRide: dummyRide,
      latestRideStatus: completedResponse,
      clearError: true,
    );
    unawaited(_syncActiveRideMapState());
  }

  /// Called when user selects a carpool from Available Carpool Rides screen.
  /// Sets state to accepted (Driver on the way) and runs the rest of the dummy flow.
  // void acceptCarpoolRideFromSelection(
  //   FindRideParams params, {
  //   String? driverName,
  //   String? carName,
  //   String? plate,
  // }) {
  //   final runId = DateTime.now().millisecondsSinceEpoch;
  //   _carpoolDummyRunId = runId;
  //   final String rideRequestId = 'carpool-dummy-$runId';

  //   final dummyRide = _buildDummyRideEntity(
  //     params,
  //     rideRequestId,
  //     'accepted',
  //     driverName: driverName,
  //     carName: carName,
  //     plate: plate,
  //   );
  //   final acceptedResponse = RideResponseEntity(
  //     type: 'accepted',
  //     message: _l10n.ride_accepted_successfully,
  //     ride: dummyRide,
  //     rideOtp: '1234',
  //     rideId: rideRequestId,
  //   );
  //   clearRideChatBadgePersistence();
  //   state = state.copyWith(
  //     currentRideType: RideType.accepted,
  //     currentSheet: RideSheetsType.onGoingRideStatusSheet,
  //     status: RideRoomStatus.success,
  //     rideRequestId: rideRequestId,
  //     activeRide: dummyRide,
  //     latestRideStatus: acceptedResponse,
  //     rideOTP: '1234',
  //     clearError: true,
  //     showBadge: false,
  //     isChatOpen: false,
  //   );
  //   unawaited(_syncActiveRideMapState());
  //   unawaited(
  //     _runCarpoolDummyFlowFromAccepted(
  //       params,
  //       rideRequestId,
  //       driverName: driverName,
  //       carName: carName,
  //       plate: plate,
  //     ),
  //   );
  // }

  // Future<void> _runCarpoolDummyFlowFromAccepted(
  //   FindRideParams params,
  //   String rideRequestId, {
  //   String? driverName,
  //   String? carName,
  //   String? plate,
  // }) async {
  //   final runId = _carpoolDummyRunId;
  //   const stepDelay = Duration(seconds: 5);

  //   await Future.delayed(stepDelay);
  //   if (runId == null ||
  //       _carpoolDummyRunId != runId ||
  //       state.currentRideType == RideType.cancelled ||
  //       state.currentSheet == RideSheetsType.whereToGoSheet) {
  //     return;
  //   }

  //   RideEntity dummyRide = _buildDummyRideEntity(
  //     params,
  //     rideRequestId,
  //     'arrived',
  //     driverName: driverName,
  //     carName: carName,
  //     plate: plate,
  //   );
  //   state = state.copyWith(
  //     currentRideType: RideType.arrived,
  //     currentSheet: RideSheetsType.driverArrivedSheet,
  //     status: RideRoomStatus.success,
  //     activeRide: dummyRide,
  //     latestRideStatus: RideResponseEntity(
  //       type: 'arrived',
  //       message: _l10n.driver_arrived_at_pickup,
  //       ride: dummyRide,
  //       rideOtp: '1234',
  //       rideId: rideRequestId,
  //     ),
  //     clearError: true,
  //   );
  //   unawaited(_syncActiveRideMapState());

  //   await Future.delayed(const Duration(seconds: 5));
  //   if (_carpoolDummyRunId != runId ||
  //       state.currentRideType == RideType.cancelled ||
  //       state.currentSheet == RideSheetsType.whereToGoSheet) {
  //     return;
  //   }

  //   dummyRide = _buildDummyRideEntity(
  //     params,
  //     rideRequestId,
  //     'inprogress',
  //     driverName: driverName,
  //     carName: carName,
  //     plate: plate,
  //   );
  //   state = state.copyWith(
  //     currentRideType: RideType.inprogress,
  //     currentSheet: RideSheetsType.onGoingRideStatusSheet,
  //     status: RideRoomStatus.success,
  //     activeRide: dummyRide,
  //     latestRideStatus: RideResponseEntity(
  //       type: 'inprogress',
  //       message: _l10n.ride_started,
  //       ride: dummyRide,
  //       rideOtp: '1234',
  //       rideId: rideRequestId,
  //     ),
  //     clearError: true,
  //   );
  //   unawaited(_syncActiveRideMapState());

  //   await Future.delayed(const Duration(seconds: 8));
  //   if (_carpoolDummyRunId != runId ||
  //       state.currentRideType == RideType.cancelled ||
  //       state.currentSheet == RideSheetsType.whereToGoSheet) {
  //     return;
  //   }

  //   dummyRide = _buildDummyRideEntity(
  //     params,
  //     rideRequestId,
  //     'completed',
  //     driverName: driverName,
  //     carName: carName,
  //     plate: plate,
  //   );
  //   state = state.copyWith(
  //     currentRideType: RideType.completed,
  //     currentSheet: RideSheetsType.whereToGoSheet,
  //     status: RideRoomStatus.success,
  //     activeRide: dummyRide,
  //     latestRideStatus: RideResponseEntity(
  //       type: 'completed',
  //       message: _l10n.reached_destination,
  //       ride: dummyRide,
  //       rideOtp: '1234',
  //       rideId: rideRequestId,
  //     ),
  //     clearError: true,
  //   );
  //   unawaited(_syncActiveRideMapState());
  // }

  RideEntity _buildDummyRideEntity(
    FindRideParams params,
    String rideId,
    String rideStatus, {
    String? driverName,
    String? carName,
    String? plate,
  }) {
    final coordsPickup = params.pickupPoint.location.coordinates;
    final coordsDrop = params.dropOffPoint.location.coordinates;
    final pickupGeo = GeoLocationEntity(
      longitude: coordsPickup.isNotEmpty ? coordsPickup[0] : 0,
      latitude: coordsPickup.length > 1 ? coordsPickup[1] : 0,
    );
    final dropGeo = GeoLocationEntity(
      longitude: coordsDrop.isNotEmpty ? coordsDrop[0] : 0,
      latitude: coordsDrop.length > 1 ? coordsDrop[1] : 0,
    );
    final pickupPoint = RidePointEntity(
      placeName: params.pickupPoint.placeName,
      location: pickupGeo,
    );
    final dropOffPoint = RidePointEntity(
      placeName: params.dropOffPoint.placeName,
      location: dropGeo,
    );
    final driver = RideUserEntity(
      id: 'carpool-driver-1',
      firstName: driverName?.trim().isNotEmpty == true ? driverName! : 'Demo',
      lastName: driverName?.trim().isNotEmpty == true ? "" : 'Carpool Driver',
      phone: '+1 234 567 8900',
      rating: 4.8,
      profilePicture: '',
    );
    final vehicle = RideVehicleEntity(
      name: (carName?.trim().isNotEmpty == true ? carName! : 'Carpool'),
      model: 'Shared Ride',
      numberPlate: (plate?.trim().isNotEmpty == true ? plate! : 'CPL-001'),
      image: null,
    );
    return RideEntity(
      id: rideId,
      userId: null,
      driverId: 'carpool-driver-1',
      user: null,
      driver: driver,
      vehicle: vehicle,
      rideStatus: rideStatus,
      rideType: 'carpool',
      specialRequest: params.specialRequest,
      rideDistance: params.rideDistance,
      paymentMethod: params.paymentMethod ?? PaymentMethod.attached_card.name,
      rideFare: params.rideFare.toDouble(),
      averageTime: params.averageTime,
      paymentStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      pickupPoint: pickupPoint,
      dropOffPointRequested: dropOffPoint,
      otp: '1234',
    );
  }

  Future<void> disconnectRideSocket() async {
    await _cancelSubscriptions();
    _resetSearchProgress();
    final result = await _disconnectRideSocketUseCase.call();

    result.fold(
      (failure) {
        state = state.copyWith(
          status: RideRoomStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        _confirmedPaymentIntentIds.clear();
        state = state.copyWith(
          status: RideRoomStatus.initial,
          isSocketInitialized: false,
          clearError: true,
        );
      },
    );
  }

  Future<void> cancelRide({
    String? rideId,
    bool isPendingRequestCancelled = false,
    String? cancellationReason,
  }) async {
    final String? resolvedRideId = _resolveRideIdForCancel(
      rideId: rideId,
      isPendingRequestCancelled: isPendingRequestCancelled,
    );
    if (resolvedRideId != null &&
        resolvedRideId.toLowerCase().startsWith('carpool-dummy')) {
      _carpoolDummyRunId = null;
    }
    if (resolvedRideId != null &&
        resolvedRideId.toLowerCase().startsWith('carpool-finding')) {
      clearRideChatBadgePersistence();
      _resetSearchProgress();
      state = RideRoomState(
        currentSheet: RideSheetsType.selectRideSheet,
        status: RideRoomStatus.success,
        isSocketInitialized: state.isSocketInitialized,
        draftSpecialRequest: state.draftSpecialRequest,
        showBadge: false,
        isChatOpen: false,
      );
      return;
    }
    if (resolvedRideId == null) {
      state = _copyWithError(message: _l10n.unable_cancel_ride_missing_id);
      return;
    }

    state = state.copyWith(status: RideRoomStatus.loading, clearError: true);
    _isUserCancelInProgress = true;
    try {
      final result = await _cancelRideUseCase.call(
        CancelRideParams(
          rideId: resolvedRideId,
          isPendingRequestCancelled: isPendingRequestCancelled,
          cancellationReason: cancellationReason,
        ),
      );

      result.fold(
        (failure) {
          state = _copyWithError(message: failure.message);
          // state = state.copyWith(showBadge: false, isChatOpen: false);
        },
        (res) {
          locator<SoundService>().stopRepeatingSound();
          locator<SoundService>().playRideCancelledSound();
          _confirmedPaymentIntentIds.clear();
          clearRideChatBadgePersistence();
          ref.read(rideEtaProvider.notifier).clearEta();
          _resetSearchProgress();
          state = RideRoomState(
            currentSheet: isPendingRequestCancelled
                ? RideSheetsType.selectRideSheet
                : RideSheetsType.whereToGoSheet,
            currentRideType: RideType.cancelled,
            status: RideRoomStatus.success,
            isSocketInitialized: state.isSocketInitialized,
            latestRideStatus: RideResponseEntity(
              type: 'cancelled',
              message: res.message,
              ride: null,
              rideId: resolvedRideId,
            ),
            errorMessage: null,
            draftSpecialRequest: state.draftSpecialRequest,
            showBadge: false,
            isChatOpen: false,
          );
          if (isPendingRequestCancelled) {
            ref.read(mapProvider.notifier).clearDriverLocation();
          } else {
            unawaited(_syncActiveRideMapState());
          }
        },
      );
    } finally {
      _isUserCancelInProgress = false;
    }
  }

  Future<void> hydrateActiveRideDetailsIfNeeded() async {
    final ride = state.activeRide;
    final bool needsHydration = ride == null || !_hasRideDetails(ride);
    if (!needsHydration) return;

    final rideId =
        state.latestRideStatus?.rideId ?? ride?.id ?? state.rideRequestId;
    if (rideId == null || rideId.trim().isEmpty) return;

    final result = await _getRideByIdUseCase.call(rideId);
    result.fold(
      (failure) {
        state = _copyWithError(message: failure.message);
      },
      (response) {
        if (response.ride == null) return;
        state = state.copyWith(
          status: RideRoomStatus.success,
          activeRide: response.ride,
          latestRideStatus: state.latestRideStatus ?? response,
          clearError: true,
        );
        _applyPersistedNormalRideChatBadgeIfAny();
      },
    );
  }

  Future<String?> getShareRideUrl() async {
    final String? rideId = _resolveRideId(null);
    if (rideId == null) {
      state = _copyWithError(message: _l10n.unable_share_ride_missing_id);
      return null;
    }

    final result = await _getShareRideUrlUseCase.call(rideId);
    return result.fold(
      (failure) {
        state = _copyWithError(message: failure.message);
        return null;
      },
      (shareData) {
        final String url = shareData.url.trim();
        if (url.isEmpty) {
          state = _copyWithError(message: _l10n.unable_share_ride_url);
          return null;
        }
        return url;
      },
    );
  }

  Future<String?> getShareCarpoolRideUrl(String rideId) async {
    final String normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty) {
      state = _copyWithError(
        message: _l10n.unable_share_carpool_ride_missing_id,
      );
      return null;
    }

    final result = await _getShareCarpoolRideUrlUseCase.call(normalizedRideId);
    return result.fold(
      (failure) {
        state = _copyWithError(message: failure.message);
        return null;
      },
      (shareData) {
        final String url = shareData.url.trim();
        if (url.isEmpty) {
          state = _copyWithError(message: _l10n.unable_share_carpool_ride_url);
          return null;
        }
        return url;
      },
    );
  }

  void _startListeners() {
    _rideStatusSub?.cancel();
    _driverLocationSub?.cancel();
    _rideResumeSub?.cancel();
    _rideSearchStatusSub?.cancel();
    _rideSearchExhaustedSub?.cancel();
    _rideUpgradeOfferSub?.cancel();
    _rideUpgradeResultSub?.cancel();
    _ridePaymentSub?.cancel();
    _socketErrorSub?.cancel();
    _socketStatusSub?.cancel();
    _userLocationSub?.cancel();

    _socketStatusSub = _getSocketStatusUseCase.call().listen((either) {
      either.fold(
        (failure) {
          debugPrint('Socket status error: ${failure.message}');
        },
        (status) {
          if (status == SocketConnectionStatus.connected) {
            _startUserLocationUpdates();
          } else {
            _stopUserLocationUpdates();
          }
        },
      );
    });

    if (locator<SocketService>().isConnected) {
      _startUserLocationUpdates();
    }

    _rideStatusSub = _rideStatusUpdatesUseCase.call().listen((either) {
      either.fold(
        (failure) {
          state = _copyWithError(message: failure.message);
        },
        (RideResponseEntity event) {
          if (!_isStatusEventForTrackedRide(event)) return;
          final rideType = _resolveRideType(event);
          if (rideType == RideType.cancelled &&
              _locallyExpiredRideId != null &&
              event.rideId == _locallyExpiredRideId) {
            return;
          }
          final RideType? previousRideType = state.currentRideType;
          if (_shouldRetryRideSearchAfterDriverCancel(
            rideType: rideType,
            previousRideType: previousRideType,
          )) {
            unawaited(_retryRideSearchAfterDriverCancel());
            return;
          }
          final bool rideEnded = _isTerminalRideType(rideType);
          state = state.copyWith(
            status: RideRoomStatus.success,
            latestRideStatus: event,
            rideRequestId: event.rideId ?? state.rideRequestId,
            activeRide: _rideFromEvent(event),
            rideOTP: event.ride?.otp ?? event.rideOtp,
            currentRideType: rideType,
            currentSheet: rideType?.toSheet() ?? state.currentSheet,
            clearError: true,
            // The search is over the moment the ride leaves "requested".
            clearSearchProgress: _hasLeftSearch(rideType),
            // An Economy driver can still accept while the upgrade offer is
            // open, and wins. Any status update closes the offer.
            clearUpgradeOffer: true,
            showBadge: rideEnded ? false : state.showBadge,
            isChatOpen: rideEnded ? false : state.isChatOpen,
          );
          if (rideEnded) {
            clearRideChatBadgePersistence();
            ref.read(rideEtaProvider.notifier).clearEta();
          } else {
            _applyPersistedNormalRideChatBadgeIfAny();
          }
          unawaited(_syncActiveRideMapState());
          _triggerRideSoundEffect(rideType, previousRideType);
        },
      );
    });

    _driverLocationSub = _driverLocationUpdatesUseCase.call().listen((either) {
      either.fold(
        (failure) {
          state = _copyWithError(message: failure.message);
        },
        (DriverLocationEntity event) {
          state = state.copyWith(
            status: RideRoomStatus.success,
            latestDriverLocation: event,
            clearError: true,
          );
          ref.read(rideEtaProvider.notifier).setEta(
            eta: event.eta,
            rideId: state.currentRideId,
          );
          unawaited(_syncDriverOnMap());
        },
      );
    });

    _rideResumeSub = _rideResumeUpdatesUseCase.call().listen((either) {
      either.fold(
        (failure) {
          state = _copyWithError(message: failure.message);
        },
        (RideResponseEntity event) {
          final rideType = _resolveRideType(event);
          final RideType? previousRideType = state.currentRideType;
          if (_shouldRetryRideSearchAfterDriverCancel(
            rideType: rideType,
            previousRideType: previousRideType,
          )) {
            unawaited(_retryRideSearchAfterDriverCancel());
            return;
          }
          final bool rideEnded = _isTerminalRideType(rideType);
          // A resume with type "requested" means the backend put the rider back
          // in the ride room mid-search: stay on the search sheet and keep
          // listening for the remaining rings.
          state = state.copyWith(
            status: RideRoomStatus.success,
            latestRideStatus: event,
            rideRequestId: event.rideId ?? state.rideRequestId,
            activeRide: event.ride,
            clearError: true,
            currentRideType: rideType,
            currentSheet: rideType?.toSheet() ?? state.currentSheet,
            clearSearchProgress: _hasLeftSearch(rideType),
            showBadge: rideEnded ? false : state.showBadge,
            isChatOpen: rideEnded ? false : state.isChatOpen,
          );
          if (rideEnded) {
            clearRideChatBadgePersistence();
            ref.read(rideEtaProvider.notifier).clearEta();
          } else {
            _applyPersistedNormalRideChatBadgeIfAny();
          }
          unawaited(_syncActiveRideMapState());
          _triggerRideSoundEffect(rideType, previousRideType);
        },
      );
    });

    _rideSearchStatusSub = _rideSearchStatusUpdatesUseCase.call().listen((
      either,
    ) {
      either.fold(
        (failure) {
          debugPrint('Ride search status stream error: ${failure.message}');
        },
        (RideSearchStatusEntity event) {
          _handleSearchStatus(event);
        },
      );
    });

    _rideSearchExhaustedSub = _rideSearchExhaustedUpdatesUseCase.call().listen((
      either,
    ) {
      either.fold(
        (failure) {
          debugPrint('Ride search exhausted stream error: ${failure.message}');
        },
        (RideSearchExhaustedEntity event) {
          _handleSearchExhausted(event);
        },
      );
    });

    _rideUpgradeOfferSub = _rideUpgradeOfferUpdatesUseCase.call().listen((
      either,
    ) {
      either.fold(
        (failure) {
          debugPrint('Ride upgrade offer stream error: ${failure.message}');
        },
        (RideUpgradeOfferEntity event) {
          _handleUpgradeOffer(event);
        },
      );
    });

    _rideUpgradeResultSub = _rideUpgradeResultUpdatesUseCase.call().listen((
      either,
    ) {
      either.fold(
        (failure) {
          debugPrint('Ride upgrade result stream error: ${failure.message}');
        },
        (RideUpgradeResultEntity event) {
          _handleUpgradeResult(event);
        },
      );
    });

    _ridePaymentSub = _ridePaymentUpdatesUseCase.call().listen((either) {
      either.fold(
        (failure) {
          state = _copyWithError(message: failure.message);
        },
        (PaymentVerificationEntity event) {
          unawaited(_handleRidePaymentVerification(event));
        },
      );
    });

    _socketErrorSub = _socketErrorsUseCase.call().listen((either) {
      either.fold((failure) {
        state = _copyWithError(message: failure.message);
      }, (_) {});
    });
  }

  Future<void> sendCurrentLocation() async {
    try {
      final locationService = locator<LocationService>();
      final hasPermission = await locationService.hasLocationPermission();
      if (!hasPermission) {
        debugPrint('Location permission not granted. Cannot send location.');
        return;
      }

      final position = await locationService.getCurrentLocation(
        requestPermissionIfNeeded: false,
      );

      _lastSentPosition = position;
      _lastSentTime = DateTime.now();

      final params = CurrentLocationParams(
        longitude: position.longitude,
        latitude: position.latitude,
      );

      final result = await _sendCurrentLocationUseCase.call(params: params);
      result.fold(
        (failure) {
          debugPrint('Failed to send current location: ${failure.message}');
        },
        (_) {
          debugPrint('Current location sent successfully.');
        },
      );
    } catch (e) {
      debugPrint('Error sending current location: $e');
    }
  }

  Future<void> _startUserLocationUpdates() async {
    if (_userLocationSub != null) return;

    final locationService = locator<LocationService>();
    final hasPermission = await locationService.hasLocationPermission();

    if (!hasPermission) {
      debugPrint('Location permission not granted. Setting up periodic check.');
      _startPermissionCheckTimer();
      return;
    }

    // Permission is granted, stop the check timer if running
    _stopPermissionCheckTimer();

    // Send immediately when tracking starts
    unawaited(sendCurrentLocation());

    _userLocationSub = locationService
        .getLocationStream(accuracy: LocationAccuracy.high, distanceFilter: 10)
        .listen(
          (position) {
            _onLocationUpdated(position);
          },
          onError: (e) {
            debugPrint('Error in user location updates stream: $e');
            // On error (e.g. permission revoked), stop current stream and watch permission again
            _stopUserLocationUpdates();
            _startPermissionCheckTimer();
          },
        );
  }

  void _startPermissionCheckTimer() {
    if (_permissionCheckTimer != null) return;
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      // Only keep check running if socket is still connected
      if (!locator<SocketService>().isConnected) {
        _stopPermissionCheckTimer();
        return;
      }
      final locationService = locator<LocationService>();
      final hasPermission = await locationService.hasLocationPermission();
      if (hasPermission) {
        debugPrint('Location permission granted. Starting location updates.');
        _stopPermissionCheckTimer();
        unawaited(_startUserLocationUpdates());
      }
    });
  }

  void _stopPermissionCheckTimer() {
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = null;
  }

  void _stopUserLocationUpdates() {
    _userLocationSub?.cancel();
    _userLocationSub = null;
    _lastSentPosition = null;
    _lastSentTime = null;
    _stopPermissionCheckTimer();
  }

  Future<void> _onLocationUpdated(Position position) async {
    final now = DateTime.now();
    if (_lastSentPosition != null && _lastSentTime != null) {
      final double distance = Geolocator.distanceBetween(
        _lastSentPosition!.latitude,
        _lastSentPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      final timeDiff = now.difference(_lastSentTime!);

      // 1. Throttle: Send at most once every 5 seconds to optimize socket traffic
      if (timeDiff.inSeconds < 5) {
        return;
      }

      // 2. Filter: Skip if user has moved less than 10 meters, unless 30 seconds have passed (keep-alive heartbeat)
      if (distance < 10 && timeDiff.inSeconds < 30) {
        return;
      }
    }

    _lastSentPosition = position;
    _lastSentTime = now;

    try {
      final params = CurrentLocationParams(
        longitude: position.longitude,
        latitude: position.latitude,
      );

      final result = await _sendCurrentLocationUseCase.call(params: params);
      result.fold(
        (failure) {
          debugPrint(
            'Failed to send current location update: ${failure.message}',
          );
        },
        (_) {
          debugPrint(
            'Current location update sent successfully: ${position.latitude}, ${position.longitude}',
          );
        },
      );
    } catch (e) {
      debugPrint('Error sending current location update: $e');
    }
  }

  bool _isNormalRide() {
    if (state.pendingCarpoolParams != null) return false;
    final String? rideId =
        state.rideRequestId ??
        state.activeRide?.id ??
        state.latestRideStatus?.rideId;
    if (rideId != null && rideId.trim().toLowerCase().startsWith('carpool')) {
      return false;
    }
    if (state.activeRide?.rideType == 'carpool') return false;
    return true;
  }

  void _triggerRideSoundEffect(RideType? newType, RideType? oldType) {
    if (newType == null || newType == oldType) return;

    final soundService = locator<SoundService>();
    switch (newType) {
      case RideType.accepted:
        soundService.playRideAcceptedSound();
        break;
      case RideType.arrived:
        soundService.playDriverArrivedSound();
        break;
      case RideType.coming:
        soundService.stopRepeatingSound();
        break;
      case RideType.inprogress:
        soundService.playRideStartedSound();
        break;
      case RideType.completed:
        soundService.playRideCompletedSound();
        break;
      case RideType.cancelled:
        soundService.playRideCancelledSound();
        break;
      default:
        break;
    }
  }

  RideRoomState _copyWithError({required String message}) {
    return state.copyWith(status: RideRoomStatus.error, errorMessage: message);
  }

  /// True while the rider is waiting on a normal (non-carpool) dispatch.
  bool _isDispatchSearchInProgress() {
    final String? rideRequestId = state.rideRequestId?.trim();
    return rideRequestId != null &&
        rideRequestId.isNotEmpty &&
        !rideRequestId.toLowerCase().startsWith('carpool-finding');
  }

  /// The search only ends once the ride moves off `requested`. A null type is
  /// an event we could not classify, and is left alone on purpose.
  bool _hasLeftSearch(RideType? rideType) {
    return rideType != null && rideType != RideType.requested;
  }

  void _resetSearchProgress() {
    state = state.copyWith(clearSearchProgress: true);
  }

  /// One ring of the ladder opened. Everything shown to the rider — radius,
  /// ring count, countdown — comes from this event, because the ladder is
  /// configured server-side and the app has no way to read it.
  void _handleSearchStatus(RideSearchStatusEntity event) {
    if (!_isForCurrentRide(event.rideId)) return;
    if (state.searchExhausted != null) return;

    state = state.copyWith(
      status: RideRoomStatus.success,
      currentRideType: state.currentRideType ?? RideType.requested,
      currentSheet: RideSheetsType.findingDriverSheet,
      rideRequestId: event.rideId ?? state.rideRequestId,
      searchStatus: event,
      clearError: true,
    );
  }

  /// The ladder ran out without a driver taking the ride. The backend has
  /// already expired the ride, dropped the pending request and charged
  /// nothing, so the rider can request another one straight away.
  void _handleSearchExhausted(RideSearchExhaustedEntity event) {
    if (!_isForCurrentRide(event.rideId)) return;

    locator<SoundService>().stopRepeatingSound();
    clearRideChatBadgePersistence();
    ref.read(rideEtaProvider.notifier).clearEta();

    state = state.copyWith(
      status: RideRoomStatus.success,
      currentRideType: RideType.expired,
      currentSheet: RideSheetsType.findingDriverSheet,
      rideRequestId: event.rideId ?? state.rideRequestId,
      searchExhausted: event,
      clearError: true,
      clearUpgradeOffer: true,
      showBadge: false,
      isChatOpen: false,
    );

    ref.read(mapProvider.notifier).clearDriverLocation();
  }

  /// The Economy ladder ran out and the backend offers a Luxury search on the
  /// same ride. Also re-sent on resume with the time left. The ride stays
  /// `requested`, so the exhausted event that may follow still gets through.
  ///
  /// The event is trusted over the cached `categoryUpgrade.enabled`: the
  /// backend only sends it when the feature is on.
  void _handleUpgradeOffer(RideUpgradeOfferEntity event) {
    if (!_isForCurrentRide(event.rideId)) return;
    if (state.searchExhausted != null) return;
    // A resumed offer whose window already closed is settled server-side.
    if (event.isExpired()) return;

    state = state.copyWith(
      status: RideRoomStatus.success,
      currentRideType: state.currentRideType ?? RideType.requested,
      currentSheet: RideSheetsType.findingDriverSheet,
      rideRequestId: event.rideId ?? state.rideRequestId,
      upgradeOffer: event,
      isDecidingUpgrade: false,
      searchCategory: state.searchCategory ?? event.from.category,
      searchFare: state.searchFare ?? event.from.fare,
      clearError: true,
    );
  }

  /// How the offer ended. Three outcomes are not replies to a tap
  /// (`timed_out`, `payment_failed`, `superseded`), and a second device in the
  /// room gets all five. `ride:search:exhausted` or `ride:status:update`
  /// follows where needed, so this only closes the offer, except for an
  /// `accepted` that this device did not tap.
  void _handleUpgradeResult(RideUpgradeResultEntity event) {
    if (!_isForCurrentRide(event.rideId)) return;

    if (event.isAccepted) {
      final String? rideType = event.rideType;
      final bool alreadyApplied =
          rideType != null && rideType == state.searchCategory;
      if (!alreadyApplied) {
        _applyAcceptedUpgrade(
          fromCategory: state.upgradeOffer?.from.category,
          category: rideType ?? state.upgradeOffer?.to.category,
          fare: event.rideFare ?? state.upgradeOffer?.to.fare,
          dropPromoCode: state.upgradeOffer?.dropsPromoCode ?? false,
        );
        return;
      }
    }

    if (state.upgradeOffer == null) return;
    state = state.copyWith(clearUpgradeOffer: true);
  }

  /// Answers the pending offer. Returns the ack so the sheet can react to a
  /// refusal (top-up, add card), or null when there is nothing to answer.
  Future<RideUpgradeDecisionEntity?> decideUpgrade(
    RideUpgradeDecision decision,
  ) async {
    final RideUpgradeOfferEntity? offer = state.upgradeOffer;
    if (offer == null || state.isDecidingUpgrade) return null;

    final String rideId = (offer.rideId ?? state.rideRequestId ?? '').trim();
    if (rideId.isEmpty) return null;

    state = state.copyWith(isDecidingUpgrade: true);
    final result = await _decideRideUpgradeUseCase.call(
      rideId: rideId,
      decision: decision,
    );

    return result.fold(
      (failure) {
        // Transport error: the offer is still open, let the rider try again.
        state = state.copyWith(isDecidingUpgrade: false);
        return RideUpgradeDecisionEntity(
          success: false,
          message: failure.message,
        );
      },
      (RideUpgradeDecisionEntity ack) {
        // The offer may already be gone: a status update or a result can land
        // before this ack.
        if (state.upgradeOffer == null) return ack;

        if (ack.success && decision == RideUpgradeDecision.accept) {
          _applyAcceptedUpgrade(
            fromCategory: offer.from.category,
            category: ack.rideType ?? offer.to.category,
            fare: ack.rideFare ?? offer.to.fare,
            dropPromoCode: offer.dropsPromoCode,
            firstRing: ack.search,
          );
          return ack;
        }

        if (!ack.success && ack.reason == RideUpgradeRefusal.notYourRide) {
          debugPrint('ride:upgrade:decide refused as NOT_YOUR_RIDE ($rideId)');
        }

        // Declined, or refused for any reason: the offer is over. What comes
        // next (exhausted, accepted status) arrives on its own.
        state = state.copyWith(clearUpgradeOffer: true);
        return ack;
      },
    );
  }

  /// The same ride now searches the offered category from ring 1. The retry
  /// params follow, so a driver cancel re-requests the ride the rider agreed
  /// to, not the original Economy quote.
  void _applyAcceptedUpgrade({
    required String? fromCategory,
    required String? category,
    required num? fare,
    required bool dropPromoCode,
    RideSearchStatusEntity? firstRing,
  }) {
    final FindRideParams? params = _lastFindRideParams;
    if (params != null && category != null && fare != null) {
      _lastFindRideParams = params.upgradedTo(
        category: category,
        rideFare: fare,
        dropPromoCode: dropPromoCode,
      );
    }

    state = state.copyWith(clearSearchProgress: true);
    state = state.copyWith(
      status: RideRoomStatus.success,
      currentRideType: RideType.requested,
      currentSheet: RideSheetsType.findingDriverSheet,
      searchStatus: firstRing,
      searchCategory: category,
      searchFare: fare,
      upgradedFromCategory: fromCategory ?? state.searchCategory,
      clearError: true,
    );
  }

  /// Ride this app closed itself after its fallback timer ran out. The
  /// backend may echo that cancellation; the echo must not pull the rider off
  /// the "no drivers" panel.
  String? _locallyExpiredRideId;

  /// The fallback timer ran out on a search the backend never closed. The
  /// rider gets the same "no drivers" panel `ride:search:exhausted` shows,
  /// after the pending request is cancelled so nothing keeps searching
  /// server-side and "request another ride" is accepted.
  Future<void> expireSearchLocally() async {
    if (state.currentRideType != RideType.requested) return;
    if (state.searchExhausted != null || state.upgradeOffer != null) return;

    final String rideId = (state.rideRequestId ?? '').trim();
    final RideSearchStatusEntity? lastRing = state.searchStatus;

    if (rideId.isNotEmpty) {
      _locallyExpiredRideId = rideId;
      _isUserCancelInProgress = true;
      try {
        await _cancelRideUseCase.call(
          CancelRideParams(rideId: rideId, isPendingRequestCancelled: true),
        );
      } finally {
        _isUserCancelInProgress = false;
      }
    }

    // A driver may have accepted, or the backend closed the search, while the
    // cancel was in flight: whatever landed first wins.
    if (state.currentRideType != RideType.requested) return;
    if (state.searchExhausted != null) return;

    _handleSearchExhausted(
      RideSearchExhaustedEntity(
        rideId: rideId.isEmpty ? null : rideId,
        radiusReachedMiles: lastRing?.radiusMiles,
        radiusReached: lastRing?.radius,
        distanceUnit: lastRing?.distanceUnit ?? 'mi',
      ),
    );
  }

  /// Re-runs the request the rider just made after the search came up empty.
  Future<void> retryLastRideSearch() async {
    final FindRideParams? params = _lastFindRideParams;
    if (params == null) {
      dismissSearchExhausted();
      return;
    }

    await findRide(params);

    // A request that never left the ground leaves the rider on a search sheet
    // with nothing behind it, so hand them back the ride selection.
    if (state.status == RideRoomStatus.error) {
      state = state.copyWith(
        currentSheet: RideSheetsType.selectRideSheet,
        clearSearchProgress: true,
      );
    }
  }

  /// Closes the "no drivers" panel and returns to the ride selection with the
  /// route intact, so requesting again is one tap away.
  void dismissSearchExhausted() {
    clearRideChatBadgePersistence();
    ref.read(rideEtaProvider.notifier).clearEta();
    state = RideRoomState(
      currentSheet: RideSheetsType.selectRideSheet,
      status: RideRoomStatus.success,
      isSocketInitialized: state.isSocketInitialized,
      draftSpecialRequest: state.draftSpecialRequest,
    );
    ref.read(mapProvider.notifier).clearDriverLocation();
  }

  /// Every lifecycle event now names its ride, so an update for a different one
  /// is a late echo of a trip that already ended. Applying it would drag the
  /// rider back into it.
  ///
  /// `ride:resume` is deliberately exempt: it is the backend telling the app
  /// which ride is really active, so it has to win even when they disagree.
  bool _isStatusEventForTrackedRide(RideResponseEntity event) {
    final String incoming = (event.rideId ?? '').trim();
    final String tracked = (state.currentRideId ?? '').trim();

    // Fail open on anything we cannot compare with confidence. Dropping a
    // legitimate update would freeze the rider mid-trip, which is far worse
    // than letting a stale one through: carpool tracks synthetic ids, and an
    // id that is not a plain document id is not something to reason about.
    if (!_looksLikeRideId(incoming) || !_looksLikeRideId(tracked)) return true;

    return incoming.toLowerCase() == tracked.toLowerCase();
  }

  static final RegExp _rideIdPattern = RegExp(r'^[a-fA-F0-9]{24}$');

  bool _looksLikeRideId(String value) => _rideIdPattern.hasMatch(value);

  /// Dispatch events name the ride they belong to; anything for an older
  /// request is stale and must not paint over the current one.
  bool _isForCurrentRide(String? eventRideId) {
    if (!_isDispatchSearchInProgress()) return false;
    final String incoming = (eventRideId ?? '').trim();
    if (incoming.isEmpty) return true;
    // Match against the request being dispatched, never `currentRideId`: a
    // finished ride leaves `activeRide` and `latestRideStatus` behind, and both
    // win over `rideRequestId` there, so every ring of the next search would be
    // compared against the previous ride and dropped.
    final String current = (state.rideRequestId ?? '').trim();
    if (current.isEmpty) return true;
    return incoming == current;
  }

  Future<void> _cancelSubscriptions() async {
    await _rideStatusSub?.cancel();
    await _driverLocationSub?.cancel();
    await _rideResumeSub?.cancel();
    await _rideSearchStatusSub?.cancel();
    await _rideSearchExhaustedSub?.cancel();
    await _rideUpgradeOfferSub?.cancel();
    await _rideUpgradeResultSub?.cancel();
    await _ridePaymentSub?.cancel();
    await _socketErrorSub?.cancel();
    await _socketStatusSub?.cancel();
    await _userLocationSub?.cancel();
    _stopPermissionCheckTimer();
    _rideStatusSub = null;
    _driverLocationSub = null;
    _rideResumeSub = null;
    _rideSearchStatusSub = null;
    _rideSearchExhaustedSub = null;
    _rideUpgradeOfferSub = null;
    _rideUpgradeResultSub = null;
    _ridePaymentSub = null;
    _socketErrorSub = null;
    _socketStatusSub = null;
    _userLocationSub = null;
    _lastSentPosition = null;
    _lastSentTime = null;
  }

  bool _hasRideDetails(RideEntity ride) {
    return (ride.driver?.fullName.trim().isNotEmpty ?? false) ||
        (ride.driver?.phone.trim().isNotEmpty ?? false) ||
        (ride.vehicle?.numberPlate?.trim().isNotEmpty ?? false) ||
        (ride.pickupPoint?.placeName.trim().isNotEmpty ?? false) ||
        (ride.dropOffPointRequested?.placeName.trim().isNotEmpty ?? false);
  }

  String? _resolveRideId(String? rideId) {
    final String? value =
        rideId ??
        state.latestRideStatus?.rideId ??
        state.activeRide?.id ??
        state.rideRequestId;
    if (value == null) return null;
    final String normalized = value.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  String? _resolveRideIdForCancel({
    required bool isPendingRequestCancelled,
    String? rideId,
  }) {
    final String? value = isPendingRequestCancelled
        ? rideId ??
              state.rideRequestId ??
              state.activeRide?.id ??
              state.latestRideStatus?.rideId
        : rideId ??
              state.activeRide?.id ??
              state.latestRideStatus?.rideId ??
              state.rideRequestId;

    if (value == null) return null;
    final String normalized = value.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  Future<void> _handleRidePaymentVerification(
    PaymentVerificationEntity event,
  ) async {
    state = state.copyWith(
      status: RideRoomStatus.success,
      latestPaymentVerification: event,
      clearError: true,
    );

    if (!event.requiresAction) return;

    final String clientSecret = event.clientSecret.trim();
    if (clientSecret.isEmpty) {
      state = _copyWithError(
        message:
            'Ride payment verification is required, but client secret is missing.',
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
      state = _copyWithError(message: failureMessage!);
    }
  }

  bool _isDriverTrackableRideType(RideType? type) {
    return type == RideType.accepted ||
        type == RideType.arrived ||
        type == RideType.coming ||
        type == RideType.inprogress;
  }

  bool _isTerminalRideType(RideType? type) {
    return type == RideType.cancelled || type == RideType.completed;
  }

  bool _shouldRetryRideSearchAfterDriverCancel({
    required RideType? rideType,
    required RideType? previousRideType,
  }) {
    if (rideType != RideType.cancelled) return false;
    if (_isRetryingFindRideAfterDriverCancel) return false;
    if (_isUserCancelInProgress) return false;
    if (_lastFindRideParams == null) return false;

    // Only restart the user's original search if the driver cancelled before
    // the ride reached pickup.
    return previousRideType == null ||
        previousRideType == RideType.requested ||
        previousRideType == RideType.accepted;
  }

  Future<void> _retryRideSearchAfterDriverCancel() async {
    final FindRideParams? params = _lastFindRideParams;
    if (params == null || _isRetryingFindRideAfterDriverCancel) return;

    _isRetryingFindRideAfterDriverCancel = true;
    try {
      await findRide(params);
    } finally {
      _isRetryingFindRideAfterDriverCancel = false;
    }
  }

  RideType? _resolveRideType(RideResponseEntity event) {
    return RideTypeExtension.fromString(event.type) ??
        RideTypeExtension.fromString(event.ride?.rideStatus);
  }

  /// Folds the ride an event carries onto the one already on screen.
  ///
  /// Every lifecycle event now ships the ride, but the wire shape has no
  /// `rideType`, `paymentStatus` or OTP, so replacing the stored ride outright
  /// would blank fields the rider is looking at. Anything the event leaves
  /// empty keeps its current value, and `rideStatus` always follows the event
  /// type — that is the freshest thing in the payload.
  RideEntity? _rideFromEvent(RideResponseEntity event) {
    final RideEntity? incoming = event.ride;
    final RideEntity? current = state.activeRide;

    if (incoming == null) {
      // No ride in the payload: keep the one we have but move its status, so
      // nothing downstream reads a stage the ride already left.
      return _withRideStatus(current, event.type);
    }

    if (current == null || current.id != incoming.id) {
      return _withRideStatus(incoming, event.type) ?? incoming;
    }

    final RideEntity merged = RideEntity(
      id: incoming.id,
      userId: incoming.userId ?? current.userId,
      driverId: incoming.driverId ?? current.driverId,
      user: incoming.user ?? current.user,
      driver: incoming.driver ?? current.driver,
      vehicle: incoming.vehicle ?? current.vehicle,
      rideStatus: incoming.rideStatus,
      rideType: _firstFilledOr(incoming.rideType, current.rideType),
      specialRequest: _firstFilledOr(
        incoming.specialRequest,
        current.specialRequest,
      ),
      rideDistance: incoming.rideDistance > 0
          ? incoming.rideDistance
          : current.rideDistance,
      paymentMethod: _firstFilledOr(
        incoming.paymentMethod,
        current.paymentMethod,
      ),
      rideFare: incoming.rideFare > 0 ? incoming.rideFare : current.rideFare,
      averageTime: incoming.averageTime > 0
          ? incoming.averageTime
          : current.averageTime,
      paymentStatus: _firstFilledOr(
        incoming.paymentStatus,
        current.paymentStatus,
      ),
      createdAt: incoming.createdAt ?? current.createdAt,
      updatedAt: incoming.updatedAt ?? current.updatedAt,
      pickupPoint: incoming.pickupPoint ?? current.pickupPoint,
      dropOffPointRequested:
          incoming.dropOffPointRequested ?? current.dropOffPointRequested,
      otp: _firstFilled(incoming.otp, current.otp),
    );

    return _withRideStatus(merged, event.type) ?? merged;
  }

  /// Rewrites a ride's status from the event type, which is always fresher
  /// than whatever the payload's ride object says.
  RideEntity? _withRideStatus(RideEntity? ride, String? eventType) {
    if (ride == null) return null;
    final String? next = eventType?.trim();
    if (next == null || next.isEmpty || next == ride.rideStatus) return ride;

    return RideEntity(
      id: ride.id,
      userId: ride.userId,
      driverId: ride.driverId,
      user: ride.user,
      driver: ride.driver,
      vehicle: ride.vehicle,
      rideStatus: next,
      rideType: ride.rideType,
      specialRequest: ride.specialRequest,
      rideDistance: ride.rideDistance,
      paymentMethod: ride.paymentMethod,
      rideFare: ride.rideFare,
      averageTime: ride.averageTime,
      paymentStatus: ride.paymentStatus,
      createdAt: ride.createdAt,
      updatedAt: ride.updatedAt,
      pickupPoint: ride.pickupPoint,
      dropOffPointRequested: ride.dropOffPointRequested,
      otp: ride.otp,
    );
  }

  String? _firstFilled(String? incoming, String? current) {
    final String value = (incoming ?? '').trim();
    return value.isEmpty ? current : incoming;
  }

  String _firstFilledOr(String incoming, String current) {
    return incoming.trim().isEmpty ? current : incoming;
  }

  LatLng? _latLngFromDriverLocation(DriverLocationEntity? location) {
    if (location == null) return null;
    final double? latitude = location.latitude;
    final double? longitude = location.longitude;
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }

  Future<void> _syncActiveRideMapState() async {
    final int token = ++_mapSyncToken;
    final mapNotifier = ref.read(mapProvider.notifier);

    if (_isTerminalRideType(state.currentRideType)) {
      mapNotifier.clearRideMapData();
      await mapNotifier.refreshCurrentLocation(moveCamera: true);
      return;
    }

    if (!_isDriverTrackableRideType(state.currentRideType)) {
      mapNotifier.clearDriverLocation();
      return;
    }

    final ride = await _resolveRideForMapSync();
    if (token != _mapSyncToken ||
        !_isDriverTrackableRideType(state.currentRideType)) {
      return;
    }

    final pickup = ride?.pickupPoint;
    final dropOff = ride?.dropOffPointRequested;
    if (pickup == null || dropOff == null) {
      return;
    }

    await mapNotifier.syncRideRoute(
      pickupLatLng: LatLng(pickup.location.latitude, pickup.location.longitude),
      pickupName: pickup.placeName,
      dropOffLatLng: LatLng(
        dropOff.location.latitude,
        dropOff.location.longitude,
      ),
      dropOffName: dropOff.placeName,
      driverLatLng: _latLngFromDriverLocation(state.latestDriverLocation),
      driverName: ride?.driver?.fullName,
    );
  }

  Future<RideEntity?> _resolveRideForMapSync() async {
    final RideEntity? localRide =
        state.activeRide ?? state.latestRideStatus?.ride;
    final bool hasLocalRoutePoints =
        localRide?.pickupPoint != null &&
        localRide?.dropOffPointRequested != null;
    if (hasLocalRoutePoints) {
      return localRide;
    }

    final String? rideId = _resolveRideId(null);
    if (rideId == null) {
      return localRide;
    }

    final result = await _getRideByIdUseCase.call(rideId);
    RideEntity? fetchedRide;
    result.fold(
      (failure) {
        state = _copyWithError(message: failure.message);
      },
      (response) {
        fetchedRide = response.ride;
        if (fetchedRide == null) return;
        state = state.copyWith(
          status: RideRoomStatus.success,
          activeRide: fetchedRide,
          latestRideStatus: state.latestRideStatus ?? response,
          clearError: true,
        );
      },
    );
    return fetchedRide ?? localRide;
  }

  Future<void> _syncDriverOnMap() async {
    if (!_isDriverTrackableRideType(state.currentRideType)) return;
    final LatLng? driverLatLng = _latLngFromDriverLocation(
      state.latestDriverLocation,
    );
    if (driverLatLng == null) return;
    await ref
        .read(mapProvider.notifier)
        .setDriverLocation(
          driverLatLng,
          name: state.activeRide?.driver?.fullName,
        );
  }

  void showChatBadge({String? persistUnreadScopeKey}) {
    final bool nextShow = !state.isChatOpen;
    state = state.copyWith(showBadge: nextShow);
    if (nextShow) {
      final String? key = persistUnreadScopeKey?.trim();
      if (key != null && key.isNotEmpty) {
        locator<StorageService>().setRideChatBadgeUnreadScope(key);
      }
    }
  }

  /// Ride-sheet red dot: only when the [message] is from the driver/other party,
  /// not the passenger's own socket echo.
  ///
  /// We do **not** match `conversationId` to `rideId`: the server uses separate ids
  /// for the chat thread vs the ride document, so that check hid all real messages.
  ///
  /// Pass [persistUnreadScopeKey] for carpool (`carpool:<bookingId>`); normal rides
  /// default to `normal:<rideId>` from current [state].
  void showChatBadgeForIncomingMessage(
    ChatMessageModel message, {
    required String passengerUserId,
    required String driverUserId,
    String? persistUnreadScopeKey,
  }) {
    if (message.isOutgoingFromUser(passengerUserId, driverUserId)) return;
    final String? scope =
        (persistUnreadScopeKey != null &&
            persistUnreadScopeKey.trim().isNotEmpty)
        ? persistUnreadScopeKey.trim()
        : _normalRideUnreadScopeKey();
    showChatBadge(persistUnreadScopeKey: scope);
  }

  /// Clears persisted unread scope and in-memory badge (call when user opens chat).
  void clearChatBadge() {
    clearRideChatBadgePersistence();
    state = state.copyWith(showBadge: false);
  }

  /// Removes only the persisted unread marker (e.g. ride cancelled / new search).
  void clearRideChatBadgePersistence() {
    locator<StorageService>().clearRideChatBadgeUnreadScope();
  }

  /// Restores the red dot after cold start when storage matches this ride/booking.
  void applyPersistedRideChatBadge({String? currentScopeKey}) {
    final storage = locator<StorageService>();
    final String? current = currentScopeKey?.trim();
    final String? stored = storage.getRideChatBadgeUnreadScope?.trim();
    if (stored == null || stored.isEmpty) return;
    if (current == null || current.isEmpty) return;
    if (stored != current) {
      storage.clearRideChatBadgeUnreadScope();
      return;
    }
    if (!state.isChatOpen) {
      state = state.copyWith(showBadge: true);
    }
  }

  String? _normalRideUnreadScopeKey() {
    final String id =
        (state.activeRide?.id ?? state.latestRideStatus?.rideId ?? '').trim();
    if (id.isEmpty) return null;
    return 'normal:$id';
  }

  void _applyPersistedNormalRideChatBadgeIfAny() {
    final String? key = _normalRideUnreadScopeKey();
    if (key == null) return;
    applyPersistedRideChatBadge(currentScopeKey: key);
  }

  void setChatOpen() {
    clearChatBadge();
    state = state.copyWith(isChatOpen: true);
  }

  void setChatClose() {
    state = state.copyWith(isChatOpen: false);
  }
}
