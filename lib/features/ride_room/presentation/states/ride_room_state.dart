import 'package:ride_app/core/params/find_ride_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/driver_location_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/payment_verification_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_search_exhausted_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_search_status_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_upgrade_entity.dart';
import 'package:ride_app/features/ride_room/enums/ride_enum.dart';

enum RideRoomStatus { initial, loading, success, error }

enum RideType {
  locationAccess('locationAccess'),
  requested('requested'),

  /// The driver search ran out of rings without anyone accepting. The backend
  /// already closed the ride and charged nothing.
  expired('expired'),
  accepted('accepted'),
  arrived('arrived'),
  /// Rider notified they're heading to pickup; same sheet as [arrived].
  coming('coming'),
  inprogress('inprogress'),
  completed('completed'),
  cancelled('cancelled');

  const RideType(this.value);
  final String value;
}

extension RideTypeExtension on RideType {
  RideSheetsType toSheet() {
    switch (this) {
      case RideType.requested:
      // `expired` keeps the search sheet on screen: it swaps its own body for
      // the "no drivers" panel so the rider can retry without going back.
      case RideType.expired:
        return RideSheetsType.findingDriverSheet;
      case RideType.arrived:
      case RideType.coming:
        return RideSheetsType.driverArrivedSheet;
      case RideType.inprogress:
      case RideType.accepted:
        return RideSheetsType.onGoingRideStatusSheet;
      case RideType.completed:
      case RideType.cancelled:
      case RideType.locationAccess:
        return RideSheetsType.whereToGoSheet;
    }
  }

  OnGoingRideStatus toOnGoingRideStatus() {
    switch (this) {
      case RideType.accepted:
        return OnGoingRideStatus.onTheWay;
      case RideType.arrived:
      case RideType.coming:
        return OnGoingRideStatus.rideStarted;
      case RideType.inprogress:
        return OnGoingRideStatus.inProgress;
      case RideType.completed:
      case RideType.cancelled:
      case RideType.locationAccess:
      case RideType.expired:
      case RideType.requested:
        return OnGoingRideStatus.reachedDestination;
    }
  }

  // Convert backend string to enum with normalization.
  static RideType? fromString(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase().replaceAll('-', '');
    try {
      return RideType.values.firstWhere(
        (e) =>
            e.value.toLowerCase().replaceAll('-', '') == normalized ||
            e.name.toLowerCase().replaceAll('-', '') == normalized,
      );
    } catch (_) {
      return null;
    }
  }
}

class RideRoomState {
  final RideRoomStatus status;
  final bool isSocketInitialized;
  final String? errorMessage;
  final String? rideRequestId;
  final RideEntity? activeRide;
  final String? rideOTP;
  final RideResponseEntity? latestRideStatus;
  final DriverLocationEntity? latestDriverLocation;
  final PaymentVerificationEntity? latestPaymentVerification;

  /// Progress of the escalating driver search, refreshed once per ring.
  final RideSearchStatusEntity? searchStatus;

  /// Set when the ladder ended with nobody accepting. Non-null means the
  /// search sheet shows the "no drivers" panel instead of the progress.
  final RideSearchExhaustedEntity? searchExhausted;

  /// Pending "switch to Luxury" offer. Non-null means the search sheet shows
  /// the offer instead of the progress. The ride stays `requested` meanwhile.
  final RideUpgradeOfferEntity? upgradeOffer;

  /// True while `ride:upgrade:decide` is waiting for its ack.
  final bool isDecidingUpgrade;

  /// Category and fare of the ride being searched. They change once, when the
  /// rider accepts an upgrade.
  final String? searchCategory;
  final num? searchFare;

  /// Category the ride had before an accepted upgrade; null on a first pass.
  final String? upgradedFromCategory;

  final RideSheetsType currentSheet;
  final RideType? currentRideType;
  final FindRideParams? pendingCarpoolParams;
  final String draftSpecialRequest;
  final bool showBadge;
  final bool isChatOpen; // ✅ NEW

  const RideRoomState({
    this.currentSheet = RideSheetsType.whereToGoSheet,
    this.currentRideType,
    this.status = RideRoomStatus.initial,
    this.isSocketInitialized = false,
    this.errorMessage,
    this.rideRequestId,
    this.rideOTP,
    this.activeRide,
    this.latestRideStatus,
    this.latestDriverLocation,
    this.latestPaymentVerification,
    this.searchStatus,
    this.searchExhausted,
    this.upgradeOffer,
    this.isDecidingUpgrade = false,
    this.searchCategory,
    this.searchFare,
    this.upgradedFromCategory,
    this.pendingCarpoolParams,
    this.draftSpecialRequest = '',
    this.showBadge = false,
    this.isChatOpen = false, // ✅ DEFAULT
  });

  RideEntity? get currentRide => activeRide ?? latestRideStatus?.ride;

  String? get currentRideId =>
      latestRideStatus?.rideId ?? activeRide?.id ?? rideRequestId;

  /// True while the rider is waiting on the dispatch ladder.
  bool get isSearchingForDriver =>
      currentRideType == RideType.requested &&
      searchExhausted == null &&
      upgradeOffer == null;

  RideRoomState copyWith({
    RideType? currentRideType,
    RideSheetsType? currentSheet,
    RideRoomStatus? status,
    bool? isSocketInitialized,
    String? errorMessage,
    String? rideRequestId,
    RideEntity? activeRide,
    String? rideOTP,
    RideResponseEntity? latestRideStatus,
    DriverLocationEntity? latestDriverLocation,
    PaymentVerificationEntity? latestPaymentVerification,
    RideSearchStatusEntity? searchStatus,
    RideSearchExhaustedEntity? searchExhausted,
    RideUpgradeOfferEntity? upgradeOffer,
    bool? isDecidingUpgrade,
    String? searchCategory,
    num? searchFare,
    String? upgradedFromCategory,
    FindRideParams? pendingCarpoolParams,
    String? draftSpecialRequest,
    bool? showBadge,
    bool? isChatOpen, // ✅ NEW
    bool clearError = false,
    bool clearPendingCarpoolParams = false,
    bool clearDraftSpecialRequest = false,
    bool clearSearchProgress = false,
    bool clearUpgradeOffer = false,
  }) {
    return RideRoomState(
      currentRideType: currentRideType ?? this.currentRideType,
      currentSheet: currentSheet ?? this.currentSheet,
      status: status ?? this.status,
      isSocketInitialized: isSocketInitialized ?? this.isSocketInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      rideRequestId: rideRequestId ?? this.rideRequestId,
      activeRide: activeRide ?? this.activeRide,
      rideOTP: rideOTP ?? this.rideOTP,
      latestRideStatus: latestRideStatus ?? this.latestRideStatus,
      latestDriverLocation:
      latestDriverLocation ?? this.latestDriverLocation,
      latestPaymentVerification:
      latestPaymentVerification ?? this.latestPaymentVerification,
      searchStatus: clearSearchProgress
          ? null
          : (searchStatus ?? this.searchStatus),
      searchExhausted: clearSearchProgress
          ? null
          : (searchExhausted ?? this.searchExhausted),
      // An offer only exists mid-search, so anything that ends the search
      // ends the offer too.
      upgradeOffer: (clearUpgradeOffer || clearSearchProgress)
          ? null
          : (upgradeOffer ?? this.upgradeOffer),
      isDecidingUpgrade: (clearUpgradeOffer || clearSearchProgress)
          ? false
          : (isDecidingUpgrade ?? this.isDecidingUpgrade),
      searchCategory: searchCategory ?? this.searchCategory,
      searchFare: searchFare ?? this.searchFare,
      upgradedFromCategory: upgradedFromCategory ?? this.upgradedFromCategory,
      pendingCarpoolParams: clearPendingCarpoolParams
          ? null
          : (pendingCarpoolParams ?? this.pendingCarpoolParams),
      draftSpecialRequest: clearDraftSpecialRequest
          ? ''
          : (draftSpecialRequest ?? this.draftSpecialRequest),
      showBadge: showBadge ?? this.showBadge,
      isChatOpen: isChatOpen ?? this.isChatOpen, // ✅ HANDLE COPY
    );
  }
}
