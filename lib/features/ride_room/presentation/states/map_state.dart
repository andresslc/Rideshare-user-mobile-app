import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/features/ride_room/domain/entities/apply_promo_code_entity.dart';

import '../../../../core/services/places_search_service.dart';

enum LocationDialogType {
  none,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  outsideServiceRegion,
  error,
}

class MapNamedPoint {
  final ResolvedPlace? resolvedPlace;
  final LatLng latLng;
  final String name;
  final String? city;

  const MapNamedPoint({
    this.resolvedPlace,
    required this.latLng,
    required this.name,
    this.city,
  });

  MapNamedPoint copyWith({LatLng? latLng, String? name, String? city}) {
    return MapNamedPoint(
      resolvedPlace: resolvedPlace,
      latLng: latLng ?? this.latLng,
      name: name ?? this.name,
      city: city ?? this.city,
    );
  }
}

class MapState {
  final String lightMapStyle;
  final String darkMapStyle;
  final CameraPosition cameraPosition;
  final MapNamedPoint currentLocation;
  // final String currentLocationName;
  final bool isLoadingLocation;
  final bool isResolvingLocationName;
  final String? errorMessage;
  final LocationDialogType locationDialogType;
  final MapNamedPoint? pickup;
  final MapNamedPoint? dropOff;
  final MapNamedPoint? driver;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Circle> circles;
  final double routeDistanceKm;
  final int routeDurationSeconds;
  final num? estimatedFare;
  final bool isFareLoading;
  final String? selectedRideType;
  final bool isApplyingPromoCode;
  final String? promoCode;
  final String? promoCodeId;
  final String? promoCampaignId;
  final int? promoAppliedPercentage;
  final num? discountedFare;
  final String? promoErrorMessage;
  final PromoCodeEntity? appliedPromo;
  final int recenterCount;
  final bool isRouteCentered;

  const MapState({
    required this.lightMapStyle,
    required this.darkMapStyle,
    required this.cameraPosition,
    required this.currentLocation,

    this.isLoadingLocation = false,
    this.isResolvingLocationName = false,
    this.errorMessage,
    this.locationDialogType = LocationDialogType.none,
    this.pickup,
    this.dropOff,
    this.driver,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.circles = const <Circle>{},
    this.routeDistanceKm = 0,
    this.routeDurationSeconds = 0,
    this.estimatedFare,
    this.isFareLoading = false,
    this.selectedRideType,
    this.isApplyingPromoCode = false,
    this.promoCode,
    this.promoCodeId,
    this.promoCampaignId,
    this.promoAppliedPercentage,
    this.discountedFare,
    this.promoErrorMessage,
    this.appliedPromo,
    this.recenterCount = 0,
    this.isRouteCentered = true,
  });

  // Backward-compatible access used in existing screen code.
  String get light => lightMapStyle;
  String get dark => darkMapStyle;
  bool get isRideReady => pickup != null && dropOff != null;
  bool get hasAppliedPromoCode =>
      promoCodeId != null && (promoCodeId?.isNotEmpty ?? false);
  num? get payableFare {
    if (appliedPromo != null && appliedPromo!.fares.isNotEmpty) {
      return appliedPromo!.fares[0].finalFare;
    }
    return discountedFare ?? estimatedFare;
  }

  //  has estimated fair
  bool get hasEstimatedFair => estimatedFare != null;

  MapNamedPoint get currentPickup =>
      pickup ??
      MapNamedPoint(latLng: currentLocation.latLng, name: currentLocation.name);

  MapState copyWith({
    String? lightMapStyle,
    String? darkMapStyle,
    CameraPosition? cameraPosition,
    MapNamedPoint? currentLocation,
    bool? isLoadingLocation,
    bool? isResolvingLocationName,
    String? errorMessage,
    bool clearError = false,
    LocationDialogType? locationDialogType,
    bool clearLocationDialogType = false,
    MapNamedPoint? pickup,
    MapNamedPoint? dropOff,
    MapNamedPoint? driver,
    bool clearPickup = false,
    bool clearDropOff = false,
    bool clearDriver = false,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    Set<Circle>? circles,
    double? routeDistanceKm,
    int? routeDurationSeconds,
    num? estimatedFare,
    bool clearEstimatedFare = false,
    bool? isFareLoading,
    String? selectedRideType,
    bool clearSelectedRideType = false,
    bool? isApplyingPromoCode,
    String? promoCode,
    bool clearPromoCode = false,
    String? promoCodeId,
    bool clearPromoCodeId = false,
    String? promoCampaignId,
    bool clearPromoCampaignId = false,
    int? promoAppliedPercentage,
    bool clearPromoAppliedPercentage = false,
    num? discountedFare,
    bool clearDiscountedFare = false,
    String? promoErrorMessage,
    bool clearPromoError = false,
    bool resetPromo = false,
    PromoCodeEntity? appliedPromo,
    bool clearAppliedPromo = false,
    int? recenterCount,
    bool? isRouteCentered,
  }) {
    return MapState(
      lightMapStyle: lightMapStyle ?? this.lightMapStyle,
      darkMapStyle: darkMapStyle ?? this.darkMapStyle,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      currentLocation: currentLocation ?? this.currentLocation,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      isResolvingLocationName:
          isResolvingLocationName ?? this.isResolvingLocationName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      locationDialogType: clearLocationDialogType
          ? LocationDialogType.none
          : (locationDialogType ?? this.locationDialogType),
      pickup: clearPickup ? null : (pickup ?? this.pickup),
      dropOff: clearDropOff ? null : (dropOff ?? this.dropOff),
      driver: clearDriver ? null : (driver ?? this.driver),
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      circles: circles ?? this.circles,
      routeDistanceKm: routeDistanceKm ?? this.routeDistanceKm,
      routeDurationSeconds: routeDurationSeconds ?? this.routeDurationSeconds,
      estimatedFare: clearEstimatedFare
          ? null
          : (estimatedFare ?? this.estimatedFare),
      isFareLoading: isFareLoading ?? this.isFareLoading,
      selectedRideType: clearSelectedRideType
          ? null
          : (selectedRideType ?? this.selectedRideType),
      isApplyingPromoCode: isApplyingPromoCode ?? this.isApplyingPromoCode,
      promoCode:
          promoCode ?? (resetPromo || clearPromoCode ? null : this.promoCode),
      promoCodeId:
          promoCodeId ??
          (resetPromo || clearPromoCodeId ? null : this.promoCodeId),
      promoCampaignId:
          promoCampaignId ??
          (resetPromo || clearPromoCampaignId ? null : this.promoCampaignId),
      promoAppliedPercentage:
          promoAppliedPercentage ??
          (resetPromo || clearPromoAppliedPercentage
              ? null
              : this.promoAppliedPercentage),
      promoErrorMessage:
          promoErrorMessage ??
          (resetPromo || clearPromoError ? null : this.promoErrorMessage),
      discountedFare:
          discountedFare ??
          (resetPromo || clearDiscountedFare ? null : this.discountedFare),
      appliedPromo:
          appliedPromo ??
          (resetPromo || clearAppliedPromo ? null : this.appliedPromo),
      recenterCount: recenterCount ?? this.recenterCount,
      isRouteCentered: isRouteCentered ?? this.isRouteCentered,
    );
  }
}
