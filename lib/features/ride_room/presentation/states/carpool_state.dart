import 'package:ride_app/core/params/find_ride_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_completed_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/driver_location_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/joined_carpool_entity.dart';

enum CarpoolSearchStatus {
  initial,
  searchingSocket,
  searchingApi,
  loaded,
  empty,
  error,
}

enum CarpoolRequestStatus { none, pending, accepted, inProgress, completed }

class CarpoolState {
  final CarpoolSearchStatus status;
  final FindRideParams? params;
  final List<CarpoolRideEntity> rides;
  final String currentCarpoolId;
  final CarpoolRideEntity? requestedRide;
  final JoinedCarpoolEntity? joinedCarpool;
  final CarpoolRequestStatus requestStatus;
  final CarpoolRideCompletedEntity? completedRide;
  final DriverLocationEntity? latestDriverLocation;
  final bool otpVerified;
  final String rideOtp;
  final bool isJoiningRequest;
  final bool isCancellingRequest;
  final bool isCompletingRide;
  final String? errorMessage;
  final String? actionMessage;

  const CarpoolState({
    this.status = CarpoolSearchStatus.initial,
    this.params,
    this.rides = const <CarpoolRideEntity>[],
    this.currentCarpoolId = '',
    this.requestedRide,
    this.joinedCarpool,
    this.requestStatus = CarpoolRequestStatus.none,
    this.completedRide,
    this.latestDriverLocation,
    this.otpVerified = false,
    this.rideOtp = '',
    this.isJoiningRequest = false,
    this.isCancellingRequest = false,
    this.isCompletingRide = false,
    this.errorMessage,
    this.actionMessage,
  });

  bool get hasRides => rides.isNotEmpty;
  bool get isAccepted => requestStatus == CarpoolRequestStatus.accepted;
  bool get isInProgress => requestStatus == CarpoolRequestStatus.inProgress;
  bool get isCompleted => requestStatus == CarpoolRequestStatus.completed;
  bool get isPending => requestStatus == CarpoolRequestStatus.pending;
  bool get hasRequestedRide =>
      requestedRide != null &&
      (joinedCarpool?.bookingId.trim().isNotEmpty ?? false);
  String get bookingId => joinedCarpool?.bookingId ?? '';
  bool get isSearching =>
      status == CarpoolSearchStatus.searchingSocket ||
      status == CarpoolSearchStatus.searchingApi;

  CarpoolState copyWith({
    CarpoolSearchStatus? status,
    FindRideParams? params,
    List<CarpoolRideEntity>? rides,
    String? currentCarpoolId,
    CarpoolRideEntity? requestedRide,
    JoinedCarpoolEntity? joinedCarpool,
    CarpoolRequestStatus? requestStatus,
    CarpoolRideCompletedEntity? completedRide,
    DriverLocationEntity? latestDriverLocation,
    bool? otpVerified,
    String? rideOtp,
    bool? isJoiningRequest,
    bool? isCancellingRequest,
    bool? isCompletingRide,
    String? errorMessage,
    String? actionMessage,
    bool clearError = false,
    bool clearRides = false,
    bool clearRequestedRide = false,
    bool clearActionMessage = false,
  }) {
    return CarpoolState(
      status: status ?? this.status,
      params: params ?? this.params,
      rides: clearRides ? const <CarpoolRideEntity>[] : (rides ?? this.rides),
      currentCarpoolId: clearRequestedRide
          ? ''
          : (currentCarpoolId ?? this.currentCarpoolId),
      requestedRide: clearRequestedRide
          ? null
          : (requestedRide ?? this.requestedRide),
      joinedCarpool: clearRequestedRide
          ? null
          : (joinedCarpool ?? this.joinedCarpool),
      requestStatus: clearRequestedRide
          ? CarpoolRequestStatus.none
          : (requestStatus ?? this.requestStatus),
      completedRide: clearRequestedRide
          ? null
          : (completedRide ?? this.completedRide),
      latestDriverLocation: clearRequestedRide
          ? null
          : (latestDriverLocation ?? this.latestDriverLocation),
      otpVerified: clearRequestedRide ? false : (otpVerified ?? this.otpVerified),
      rideOtp: clearRequestedRide ? '' : (rideOtp ?? this.rideOtp),
      isJoiningRequest: isJoiningRequest ?? this.isJoiningRequest,
      isCancellingRequest: isCancellingRequest ?? this.isCancellingRequest,
      isCompletingRide: clearRequestedRide
          ? false
          : (isCompletingRide ?? this.isCompletingRide),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }
}
