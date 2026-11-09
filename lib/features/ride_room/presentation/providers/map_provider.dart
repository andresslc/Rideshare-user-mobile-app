import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_utils/google_maps_utils.dart' as utils;
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/constants/app_colors.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/location/service_region.dart';
import 'package:ride_app/core/params/apply_promo_code_params.dart';
import 'package:ride_app/core/params/fare_calculator_params.dart';
import 'package:ride_app/core/services/location_service.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/apply_promo_code_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/calculate_fare_usecase.dart';
import 'package:ride_app/features/ride_room/presentation/providers/camera_providers.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/map_state.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';
import 'package:ride_app/services/route_deviation_detector.dart';

import '../../../../core/services/places_search_service.dart';

final mapProvider = AsyncNotifierProvider<MapProvider, MapState>(
  MapProvider.new,
);

class MapProvider extends AsyncNotifier<MapState> {
  MapProvider({Dio? routeDio}) : _dio = routeDio ?? Dio();
  // static const LatLng _defaultLatLng = LatLng(28.5384, -81.3789);
  static const double _defaultZoom = 16;
  static const String _pickupMarkerPrefix = 'pickup_';
  static const String _dropOffMarkerPrefix = 'dropoff_';
  static const MarkerId _driverMarkerId = MarkerId('driver_marker');
  static const PolylineId _pickupDropOffPolylineId = PolylineId(
    'pickup_dropoff_polyline',
  );
  static const double _pickupMarkerIconSize = 35;
  static const double _dropOffMarkerIconSize = 40;
  static const double _driverMarkerIconSize = 30;
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';
  static const double _milesPerKilometer = 0.621371;

  late LocationService _locationService;
  late CalculateFareUseCase _calculateFareUseCase;
  //Apply PromoCode UseCase
  late ApplyPromoCodeUseCase _applyPromoCodeUseCase;
  final PolylinePoints _polylinePoints = PolylinePoints();
  final Dio _dio;
  BitmapDescriptor? _pickupMarkerIcon;
  BitmapDescriptor? _dropOffMarkerIcon;
  BitmapDescriptor? _driverMarkerIcon;
  int _driverAnimationToken = 0;
  double _currentDriverRotation = 0.0;
  DateTime? _lastDriverLocationTime;
  int _routeBuildToken = 0;
  bool _isRerouting = false;

  /// LRU reverse-geocode cache. Key is rounded lat/lng (4 decimals ≈ 11m).
  /// Max 50 entries to bound memory.
  static const int _geocodeCacheMaxSize = 50;
  final LinkedHashMap<String, String> _geocodeCache =
      LinkedHashMap<String, String>();

  /// Debounce timer for reverse geocoding on camera idle.
  Timer? _reverseGeocodeDebounce;

  /// Resolves the address for either pickup or dropoff for the given map-center coordinate.
  ///
  /// Called when the map settles after a drag gesture.
  /// Uses a 250ms debounce and an LRU cache to minimise API calls.
  Future<void> resolveAddressFromMapCenter(
    LatLng center, {
    RouteField field = RouteField.pickup,
  }) async {
    _reverseGeocodeDebounce?.cancel();
    final value = state.value;
    if (value == null) return;
    if (!_isWithinActiveRegion(center)) return;

    // Check cache first (synchronous).
    final String cacheKey = _geocodeCacheKey(center);
    final String? cached = _geocodeCache[cacheKey];
    if (cached != null) {
      // Move to end (most-recently-used).
      _geocodeCache.remove(cacheKey);
      _geocodeCache[cacheKey] = cached;

      final next = MapNamedPoint(latLng: center, name: cached);
      if (field == RouteField.pickup) {
        state = AsyncData(
          value.copyWith(
            pickup: next,
            currentLocation: MapNamedPoint(latLng: center, name: cached),
            isResolvingLocationName: false,
            markers: _syncRideMarkers(
              base: value.markers,
              pickup: next,
              dropOff: value.dropOff,
              clearRideMarkers: true,
            ),
          ),
        );
      } else {
        state = AsyncData(
          value.copyWith(
            dropOff: next,
            isResolvingLocationName: false,
            markers: _syncRideMarkers(
              base: value.markers,
              pickup: value.pickup ?? value.currentLocation,
              dropOff: next,
              clearRideMarkers: true,
            ),
          ),
        );
      }
      return;
    }

    // Immediately set isResolvingLocationName to true so the old address is never flashed
    state = AsyncData(value.copyWith(isResolvingLocationName: true));

    // Debounce the API call.
    _reverseGeocodeDebounce = Timer(
      const Duration(milliseconds: 250),
      () async {
        final latest = state.value;
        if (latest == null) return;

        try {
          final LocationAddressDetails details = await _locationService
              .getLocationDetailsFromCoordinates(
                center.latitude,
                center.longitude,
                fallback: field == RouteField.pickup ? 'Pickup' : 'Drop Off',
                reason: 'manual_pin',
              );

          // Store in cache.
          _geocodeCachePut(cacheKey, details.name);

          final postResolve = state.value;
          if (postResolve == null) return;

          final next = MapNamedPoint(
            latLng: center,
            name: details.name,
            city: details.city,
          );
          if (field == RouteField.pickup) {
            state = AsyncData(
              postResolve.copyWith(
                pickup: next,
                currentLocation: next,
                isResolvingLocationName: false,
                markers: _syncRideMarkers(
                  base: postResolve.markers,
                  pickup: next,
                  dropOff: postResolve.dropOff,
                  clearRideMarkers: true,
                ),
              ),
            );
          } else {
            state = AsyncData(
              postResolve.copyWith(
                dropOff: next,
                isResolvingLocationName: false,
                markers: _syncRideMarkers(
                  base: postResolve.markers,
                  pickup: postResolve.pickup ?? postResolve.currentLocation,
                  dropOff: next,
                  clearRideMarkers: true,
                ),
              ),
            );
          }
        } catch (e, s) {
          log('resolveAddressFromMapCenter failed', error: e, stackTrace: s);
          final postErr = state.value;
          if (postErr != null) {
            state = AsyncData(postErr.copyWith(isResolvingLocationName: false));
          }
        }
      },
    );
  }

  /// Backward-compatible wrapper for pickup address resolution.
  Future<void> resolvePickupFromMapCenter(LatLng center) =>
      resolveAddressFromMapCenter(center, field: RouteField.pickup);

  String _geocodeCacheKey(LatLng pos) =>
      '${pos.latitude.toStringAsFixed(4)},${pos.longitude.toStringAsFixed(4)}';

  void _geocodeCachePut(String key, String value) {
    _geocodeCache[key] = value;
    // Evict oldest if over capacity.
    while (_geocodeCache.length > _geocodeCacheMaxSize) {
      _geocodeCache.remove(_geocodeCache.keys.first);
    }
  }

  @override
  Future<MapState> build() async {
    _locationService = locator<LocationService>();
    _calculateFareUseCase = locator<CalculateFareUseCase>();
    _applyPromoCodeUseCase = locator<ApplyPromoCodeUseCase>();
    await _loadMarkerIcons();

    final String light = await rootBundle.loadString(
      'assets/map_style/light_map.json',
    );
    final String dark = await rootBundle.loadString(
      'assets/map_style/dark_map.json',
    );

    final LatLng initialLatLng = await _resolveInitialLatLng();
    final LocationAddressDetails initialDetails = await _locationService
        .getLocationDetailsFromCoordinates(
          initialLatLng.latitude,
          initialLatLng.longitude,
          fallback: 'Current Location',
          reason: 'initial_position',
        );

    final initialPoint = MapNamedPoint(
      latLng: initialLatLng,
      name: initialDetails.name,
      city: initialDetails.city,
    );

    return MapState(
      lightMapStyle: light,
      darkMapStyle: dark,
      currentLocation: initialPoint,
      pickup: initialPoint,
      cameraPosition: CameraPosition(
        target: _withCameraOffset(initialLatLng),
        zoom: _defaultZoom,
      ),
      markers: <Marker>{
        Marker(
          markerId: _pickupMarkerIdFor(initialLatLng),
          position: initialLatLng,
          infoWindow: InfoWindow(title: initialDetails.name),
          icon:
              _pickupMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      },
    );
  }

  String styleFor(Brightness brightness) {
    final value = state.value;
    if (value == null) return '';
    return brightness == Brightness.dark
        ? value.darkMapStyle
        : value.lightMapStyle;
  }

  CameraTargetBounds get cameraTargetBounds =>
      CameraTargetBounds(_locationService.activeRegion.bounds);

  ServiceRegion get activeRegion => _locationService.activeRegion;

  LatLngBounds? routeCameraBounds(MapState mapState) {
    final List<LatLng> points = _routeCameraPoints(mapState);
    if (points.length < 2) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final LatLng point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    if (minLat == maxLat && minLng == maxLng) {
      return null;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void clearPromoError() {
    state = AsyncData(state.value!.copyWith(clearPromoError: true));
  }

  void recenterRoute() {
    final value = state.value;
    if (value == null) return;
    state = AsyncData(
      value.copyWith(
        recenterCount: value.recenterCount + 1,
        isRouteCentered: true,
      ),
    );
  }

  void setRouteCentered(bool isCentered) {
    final value = state.value;
    if (value == null || value.isRouteCentered == isCentered) return;
    state = AsyncData(value.copyWith(isRouteCentered: isCentered));
  }

  double distanceInMiles(double distanceKm) {
    if (distanceKm <= 0) return 0;
    return distanceKm * _milesPerKilometer;
  }

  void onCameraMove(CameraPosition position) {
    final value = state.value;
    if (value == null) return;
    // Dragging/zooming the map should not mutate current pickup location.
    // Keep pickup marker fixed unless setPickupLocation/refreshCurrentLocation is called.
    final LatLng clampedTarget = activeRegion.clamp(position.target);
    state = AsyncData(
      value.copyWith(
        cameraPosition: CameraPosition(
          target: clampedTarget,
          zoom: position.zoom,
          tilt: position.tilt,
          bearing: position.bearing,
        ),
      ),
    );
  }

  /// Resolves the place name on camera idle.
  /// Note: Currently unused to avoid making redundant and expensive Geocoding API calls on camera idle.
  // Future<void> onCameraIdleResolveLocationName() async {
  //   final value = state.value;
  //   if (value == null) return;

  //   state = AsyncData(value.copyWith(isResolvingLocationName: true));

  //   try {
  //     final String placeName = await _locationService
  //         .getPlaceNameFromCoordinates(
  //           value.currentLocation.latLng.latitude,
  //           value.currentLocation.latLng.longitude,
  //           fallback: value.currentLocation.name,
  //         );

  //     final latest = state.value;
  //     if (latest == null) return;
  //     state = AsyncData(
  //       latest.copyWith(
  //         currentLocation: MapNamedPoint(
  //           latLng: latest.currentLocation.latLng,
  //           name: placeName,
  //         ),
  //         isResolvingLocationName: false,
  //         clearError: true,
  //       ),
  //     );
  //   } catch (e, s) {
  //     log('Map reverse geocode failed', error: e, stackTrace: s);
  //     final latest = state.value;
  //     if (latest == null) return;
  //     state = AsyncData(
  //       latest.copyWith(
  //         isResolvingLocationName: false,
  //         errorMessage: e.toString(),
  //       ),
  //     );
  //   }
  // }

  Future<void> refreshCurrentLocation({bool moveCamera = true}) async {
    final value = state.value;
    if (value == null) return;

    state = AsyncData(
      value.copyWith(
        isLoadingLocation: true,
        clearError: true,
        clearLocationDialogType: true,
      ),
    );

    try {
      final LocationPermissionResult accessResult = await _locationService
          .ensureLocationAccess(requestPermissionIfNeeded: true);

      if (accessResult != LocationPermissionResult.granted) {
        final latest = state.value;
        if (latest == null) return;
        final LocationDialogType dialogType = _dialogTypeFromPermissionResult(
          accessResult,
        );
        state = AsyncData(
          latest.copyWith(
            isLoadingLocation: false,
            errorMessage: _messageForPermissionResult(accessResult),
            locationDialogType: dialogType,
          ),
        );
        return;
      }

      final position = await _locationService.getCurrentLocation();
      final LatLng latLng = LatLng(position.latitude, position.longitude);
      if (!activeRegion.contains(latLng)) {
        final latest = state.value;
        if (latest == null) return;
        state = AsyncData(
          latest.copyWith(
            isLoadingLocation: false,
            errorMessage: outsideRegionMessage(),
            locationDialogType: LocationDialogType.outsideServiceRegion,
          ),
        );
        return;
      }
      final LocationAddressDetails details = await _locationService
          .getLocationDetailsFromCoordinates(
            latLng.latitude,
            latLng.longitude,
            fallback: 'Current Location',
            reason: 'initial_position',
          );
      final currentPoint = MapNamedPoint(
        latLng: latLng,
        name: details.name,
        city: details.city,
      );

      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(
          isLoadingLocation: false,
          currentLocation: currentPoint,
          pickup: currentPoint,
          cameraPosition: moveCamera
              ? CameraPosition(
                  target: _withCameraOffset(latLng),
                  zoom: _defaultZoom,
                  tilt: latest.cameraPosition.tilt,
                  bearing: latest.cameraPosition.bearing,
                )
              : latest.cameraPosition,
          markers: _syncRideMarkers(
            base: latest.markers,
            pickup: currentPoint,
            dropOff: latest.dropOff,
            clearRideMarkers: true,
          ),
          clearLocationDialogType: true,
        ),
      );
    } catch (e, s) {
      log('Current location refresh failed', error: e, stackTrace: s);
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(
          isLoadingLocation: false,
          errorMessage: _normalizeLocationErrorMessage(e),
          locationDialogType: LocationDialogType.error,
        ),
      );
    }
  }

  Future<bool> openLocationSettings() =>
      _locationService.openLocationSettings();

  void clearLocationDialog() {
    final value = state.value;
    if (value == null) return;
    state = AsyncData(
      value.copyWith(clearError: true, clearLocationDialogType: true),
    );
  }

  void setMarker(Marker marker) {
    final value = state.value;
    if (value == null) return;
    final markers = {...value.markers}
      ..removeWhere((m) => m.markerId == marker.markerId)
      ..add(marker);
    state = AsyncData(value.copyWith(markers: markers));
  }

  void removeMarker(MarkerId markerId) {
    final value = state.value;
    if (value == null) return;
    final markers = {...value.markers}
      ..removeWhere((m) => m.markerId == markerId);
    state = AsyncData(value.copyWith(markers: markers));
  }

  void setPolylines(Set<Polyline> polylines) {
    final value = state.value;
    if (value == null) return;
    state = AsyncData(value.copyWith(polylines: polylines));
  }

  void setCircles(Set<Circle> circles) {
    final value = state.value;
    if (value == null) return;
    state = AsyncData(value.copyWith(circles: circles));
  }

  void clearRideMapData() {
    final value = state.value;
    if (value == null) return;
    _driverAnimationToken++;
    _currentDriverRotation = 0.0;
    _lastDriverLocationTime = null;
    state = AsyncData(
      value.copyWith(
        pickup: value.currentPickup,
        clearDropOff: true,
        clearDriver: true,
        markers: _syncDriverMarker(
          base: _syncRideMarkers(
            base: value.markers,
            pickup: value.currentPickup,
            dropOff: null,
            clearRideMarkers: true,
          ),
          driver: null,
        ),
        polylines: _syncPickupDropOffPolyline(
          base: value.polylines,
          pickup: value.currentPickup,
          dropOff: null,
        ),
        circles: const <Circle>{},
        routeDistanceKm: 0,
        routeDurationSeconds: 0,
        clearEstimatedFare: true,
        isFareLoading: false,
        clearPromoCode: true,
        clearPromoCodeId: true,
        clearPromoCampaignId: true,
        clearPromoAppliedPercentage: true,
        clearDiscountedFare: true,
        clearPromoError: true,
        isApplyingPromoCode: false,
      ),
    );
  }

  void clearRideSelection() {
    final value = state.value;
    if (value == null) return;
    state = AsyncData(
      value.copyWith(
        clearSelectedRideType: true,
        clearEstimatedFare: true,
        isFareLoading: false,
        clearPromoCode: true,
        clearPromoCodeId: true,
        clearPromoCampaignId: true,
        clearPromoAppliedPercentage: true,
        clearDiscountedFare: true,
        clearPromoError: true,
        isApplyingPromoCode: false,
      ),
    );
  }

  Future<void> setPickupLocation(
    LatLng latLng, {
    String? name,
    ResolvedPlace? resolvedPlace,
    String? city,
    bool resolveNameIfMissing = true,
    bool moveCamera = true,
  }) async {
    final value = state.value;
    if (value == null) return;
    if (!_isWithinActiveRegion(latLng)) {
      state = AsyncData(
        value.copyWith(
          errorMessage:
              'Pickup location must be within ${activeRegion.displayName}.',
        ),
      );
      return;
    }

    String resolvedName = (name ?? '').trim();
    String resolvedCity = (resolvedPlace?.city.trim().isNotEmpty ?? false)
        ? resolvedPlace!.city
        : (city ?? '').trim();
    // Pricing and promo requests require pickup city even for saved/legacy values.
    // Fresh Places or picker components bypass this missing-data fallback.
    if (resolvedCity.isEmpty || resolvedName.isEmpty) {
      final LocationAddressDetails details = await _locationService
          .getLocationDetailsFromCoordinates(
            latLng.latitude,
            latLng.longitude,
            fallback: 'Pickup',
            reason: 'pickup_city_fallback',
          );
      if (resolvedName.isEmpty) {
        resolvedName = details.name;
      }
      resolvedCity = details.city;
    }

    final next = MapNamedPoint(
      latLng: latLng,
      name: resolvedName,
      city: resolvedCity,
      resolvedPlace: resolvedPlace,
    );
    final int routeBuildToken = ++_routeBuildToken;
    final MapState pendingState = value.copyWith(
      pickup: next,
      currentLocation: next,
      cameraPosition: moveCamera
          ? CameraPosition(
              target: _withCameraOffset(latLng),
              zoom: value.cameraPosition.zoom,
              tilt: value.cameraPosition.tilt,
              bearing: value.cameraPosition.bearing,
            )
          : value.cameraPosition,
      resetPromo: true,
      markers: _syncRideMarkers(
        base: value.markers,
        pickup: next,
        dropOff: value.dropOff,
        clearRideMarkers: true,
      ),
      polylines: _syncPickupDropOffPolyline(
        base: value.polylines,
        pickup: next,
        dropOff: null,
      ),
      routeDistanceKm: 0,
      routeDurationSeconds: 0,
      clearEstimatedFare: true,
      isFareLoading: false,
      isApplyingPromoCode: false,
    );
    state = AsyncData(pendingState);
    final routeMetrics = await _buildPickupDropOffPolyline(
      base: pendingState.polylines,
      pickup: next,
      dropOff: value.dropOff,
    );
    if (routeBuildToken != _routeBuildToken) return;

    final nextState = pendingState.copyWith(
      pickup: next,
      polylines: routeMetrics.polylines,
      routeDistanceKm: routeMetrics.distanceKm,
      routeDurationSeconds: routeMetrics.durationSeconds,
      clearEstimatedFare: true,
      isApplyingPromoCode: false,
    );
    state = AsyncData(nextState);
    await _updateFareEstimate(nextState);
  }

  Future<void> setDropOffLocation(
    LatLng latLng, {
    String? name,
    ResolvedPlace? resolvedPlace,
    String? city,
    bool resolveNameIfMissing = true,
  }) async {
    final value = state.value;
    if (value == null) return;
    if (!_isWithinActiveRegion(latLng)) {
      state = AsyncData(
        value.copyWith(
          errorMessage:
              'Drop-off location must be within ${activeRegion.displayName}.',
        ),
      );
      return;
    }

    String resolvedName = (name ?? '').trim();
    if (resolvedName.isEmpty && resolveNameIfMissing) {
      resolvedName = await _locationService.getPlaceNameFromCoordinates(
        latLng.latitude,
        latLng.longitude,
        fallback: 'Drop Off',
        reason: 'dropoff_name_fallback',
      );
    }

    final next = MapNamedPoint(
      latLng: latLng,
      name: resolvedName,
      city: resolvedPlace?.city ?? city,
      resolvedPlace: resolvedPlace,
    );
    final int routeBuildToken = ++_routeBuildToken;
    final MapState pendingState = value.copyWith(
      dropOff: next,
      resetPromo: true,
      markers: _syncRideMarkers(
        base: value.markers,
        pickup: value.currentPickup,
        dropOff: next,
        clearRideMarkers: true,
      ),
      polylines: _syncPickupDropOffPolyline(
        base: value.polylines,
        pickup: value.currentPickup,
        dropOff: null,
      ),
      routeDistanceKm: 0,
      routeDurationSeconds: 0,
      clearEstimatedFare: true,
      isFareLoading: false,
      isApplyingPromoCode: false,
    );
    state = AsyncData(pendingState);
    final routeMetrics = await _buildPickupDropOffPolyline(
      base: pendingState.polylines,
      pickup: value.currentPickup,
      dropOff: next,
    );
    if (routeBuildToken != _routeBuildToken) return;

    final nextState = pendingState.copyWith(
      dropOff: next,
      polylines: routeMetrics.polylines,
      routeDistanceKm: routeMetrics.distanceKm,
      routeDurationSeconds: routeMetrics.durationSeconds,
      clearEstimatedFare: true,
      isApplyingPromoCode: false,
    );
    state = AsyncData(nextState);
    await _updateFareEstimate(nextState);
  }

  Future<void> setSelectedRideType(String rideType) async {
    final value = state.value;
    if (value == null) return;
    final String normalized = rideType.trim().toLowerCase();
    final next = value.copyWith(
      selectedRideType: normalized,
      clearEstimatedFare: true,
      isApplyingPromoCode: false,
      resetPromo: true,
    );
    state = AsyncData(next);
    await _updateFareEstimate(next);
  }

  //Apply PromoCode
  Future<void> applyPromoCode(String code, {void Function()? onSuccess}) async {
    final MapState? value = await _getReadyState();
    if (value == null) {
      return;
    }
    state = AsyncData(
      value.copyWith(isApplyingPromoCode: true, clearPromoError: true),
    );

    final String pickupCity = (value.pickup?.city?.trim().isNotEmpty ?? false)
        ? value.pickup!.city!
        : activeRegion.displayName;

    final String rideType = value.selectedRideType ?? 'economy';
    final List<double> rideFare = <double>[
      (value.payableFare ?? value.estimatedFare ?? 0.0).toDouble(),
    ];

    final result = await _applyPromoCodeUseCase(
      ApplyPromoCodeParams(
        code: code,
        rideType: rideType,
        pickupCity: pickupCity,
        rideFare: rideFare,
      ),
    );
    final MapState? latest = state.value;
    if (latest == null) {
      return;
    }
    result.fold(
      (failure) {
        state = AsyncData(
          latest.copyWith(
            isApplyingPromoCode: false,
            promoErrorMessage: failure.message,
            resetPromo: true,
          ),
        );
      },
      (promo) {
        onSuccess?.call();

        final double discountVal = promo.discountValue;
        final num? discounted = promo.fares.isNotEmpty
            ? promo.fares[0].finalFare
            : null;

        state = AsyncData(
          latest.copyWith(
            isApplyingPromoCode: false,
            promoCode: code,
            promoCodeId: promo.codeId,
            promoCampaignId: promo.campaignId,
            promoAppliedPercentage: discountVal.toInt(),
            discountedFare: discounted,
            appliedPromo: promo,
            clearPromoError: true,
          ),
        );
      },
    );
  }

  void clearPromoCode() {
    final value = state.value;
    if (value == null) return;
    state = AsyncData(
      value.copyWith(isApplyingPromoCode: false, resetPromo: true),
    );
  }

  Future<void> syncRideRoute({
    required LatLng pickupLatLng,
    required String pickupName,
    required LatLng dropOffLatLng,
    required String dropOffName,
    LatLng? driverLatLng,
    String? driverName,
  }) async {
    final value = await _getReadyState();
    if (value == null) return;
    if (!_isWithinActiveRegion(pickupLatLng) ||
        !_isWithinActiveRegion(dropOffLatLng) ||
        (driverLatLng != null && !_isWithinActiveRegion(driverLatLng))) {
      state = AsyncData(
        value.copyWith(
          errorMessage:
              'Ride locations must be within ${activeRegion.displayName}.',
        ),
      );
      return;
    }

    final pickup = MapNamedPoint(
      latLng: pickupLatLng,
      name: pickupName.trim().isEmpty ? 'Pickup' : pickupName.trim(),
    );
    final dropOff = MapNamedPoint(
      latLng: dropOffLatLng,
      name: dropOffName.trim().isEmpty ? 'Drop Off' : dropOffName.trim(),
    );
    final bool routeUnchanged =
        value.pickup?.latLng == pickup.latLng &&
        value.dropOff?.latLng == dropOff.latLng &&
        value.polylines.any(
          (Polyline polyline) =>
              polyline.polylineId == _pickupDropOffPolylineId,
        );

    final MapNamedPoint? driver = driverLatLng == null
        ? null
        : MapNamedPoint(
            latLng: driverLatLng,
            name: (driverName ?? '').trim().isEmpty
                ? 'Driver'
                : driverName!.trim(),
          );

    final Set<Marker> rideMarkers = _syncRideMarkers(
      base: value.markers,
      pickup: pickup,
      dropOff: dropOff,
      clearRideMarkers: true,
    );

    if (routeUnchanged) {
      state = AsyncData(
        value.copyWith(
          pickup: pickup,
          dropOff: dropOff,
          driver: driver,
          markers: _syncDriverMarker(base: rideMarkers, driver: driver),
          isFareLoading: false,
        ),
      );
      return;
    }

    final routeMetrics = await _buildPickupDropOffPolyline(
      base: value.polylines,
      pickup: pickup,
      dropOff: dropOff,
    );

    final nextState = value.copyWith(
      pickup: pickup,
      dropOff: dropOff,
      driver: driver,
      markers: _syncDriverMarker(base: rideMarkers, driver: driver),
      polylines: routeMetrics.polylines,
      routeDistanceKm: routeMetrics.distanceKm,
      routeDurationSeconds: routeMetrics.durationSeconds,
      clearEstimatedFare: true,
      isFareLoading: false,
      resetPromo: !routeUnchanged,
    );

    state = AsyncData(nextState);
    await _updateFareEstimate(nextState);
  }

  Future<void> setDriverLocation(
    LatLng latLng, {
    String? name,
    bool resolveNameIfMissing = false,
  }) async {
    final initial = await _getReadyState();
    if (initial == null) return;
    if (!_isWithinActiveRegion(latLng)) return;

    String resolvedName = (name ?? '').trim();
    if (resolvedName.isEmpty && resolveNameIfMissing) {
      resolvedName = await _locationService.getPlaceNameFromCoordinates(
        latLng.latitude,
        latLng.longitude,
        fallback: 'Driver',
        reason: 'driver_name_fallback',
      );
    }
    if (resolvedName.isEmpty) {
      resolvedName = 'Driver';
    }

    final rideRoomState = ref.read(rideRoomProvider);
    final bool isRideInProgress =
        rideRoomState.currentRideType == RideType.inprogress;

    final int token = ++_driverAnimationToken;
    final next = MapNamedPoint(latLng: latLng, name: resolvedName);

    if (initial.driver == null) {
      _currentDriverRotation = 0.0;
      state = AsyncData(
        initial.copyWith(
          driver: next,
          markers: _syncDriverMarker(
            base: initial.markers,
            driver: next,
            rotation: 0,
          ),
          polylines: isRideInProgress
              ? _consumePickupDropOffPolylineByDriver(
                  base: initial.polylines,
                  driverLatLng: latLng,
                )
              : initial.polylines,
        ),
      );
      if (isRideInProgress) {
        await _checkDeviationAndReroute(latLng);
      }
      return;
    }

    final DateTime now = DateTime.now();
    int totalDurationMs = 4500;
    if (_lastDriverLocationTime != null) {
      final int elapsedMs = now
          .difference(_lastDriverLocationTime!)
          .inMilliseconds;
      if (elapsedMs >= 1500 && elapsedMs <= 10000) {
        totalDurationMs = (elapsedMs * 0.95).round();
      }
    }
    _lastDriverLocationTime = now;

    final LatLng startPosition =
        state.value?.driver?.latLng ?? initial.driver!.latLng;
    final double startRotation = _currentDriverRotation;
    final double distanceMeters = _calculateDistanceMeters(
      startPosition,
      latLng,
    );

    // Ignore tiny GPS drift noise if displacement is negligible (< 0.3 meters)
    if (distanceMeters < 0.3) {
      return;
    }

    // Recalculate target bearing when movement is >= 1.0 meters
    final double targetBearing = distanceMeters >= 1.0
        ? _calculateBearing(startPosition, latLng)
        : startRotation;

    const int frameIntervalMs = 40; // ~25 FPS smooth updates
    final int steps = math.max(16, (totalDurationMs / frameIntervalMs).round());
    final int stepDurationMs = math.max(1, totalDurationMs ~/ steps);
    final Stopwatch stopwatch = Stopwatch()..start();

    for (int i = 1; i <= steps; i++) {
      if (token != _driverAnimationToken) return;

      await Future.delayed(Duration(milliseconds: stepDurationMs));
      if (token != _driverAnimationToken) return;

      final current = state.value;
      if (current == null) return;

      final double t = math.min(
        1.0,
        stopwatch.elapsedMilliseconds / totalDurationMs,
      );
      final LatLng intermediate = LatLng(
        startPosition.latitude + (latLng.latitude - startPosition.latitude) * t,
        startPosition.longitude +
            (latLng.longitude - startPosition.longitude) * t,
      );

      final double currentRotation = _lerpRotation(
        startRotation,
        targetBearing,
        t,
      );
      _currentDriverRotation = currentRotation;

      final MapNamedPoint intermediateDriver = MapNamedPoint(
        latLng: intermediate,
        name: resolvedName,
      );

      final bool isLastStep = i == steps || t >= 1.0;
      final bool shouldTrimPolyline = (i % 4 == 0) || isLastStep;

      state = AsyncData(
        current.copyWith(
          driver: intermediateDriver,
          markers: _syncDriverMarker(
            base: current.markers,
            driver: intermediateDriver,
            rotation: currentRotation,
          ),
          polylines: isRideInProgress && shouldTrimPolyline
              ? _consumePickupDropOffPolylineByDriver(
                  base: current.polylines,
                  driverLatLng: intermediate,
                )
              : current.polylines,
        ),
      );
    }

    if (token == _driverAnimationToken && isRideInProgress) {
      await _checkDeviationAndReroute(latLng);
    }
  }

  Future<MapState?> _getReadyState() async {
    final current = state.value;
    if (current != null) return current;
    try {
      return await future;
    } catch (_) {
      return state.value;
    }
  }

  void clearPickupLocation({bool resetPromo = true}) {
    final value = state.value;
    if (value == null) return;
    _routeBuildToken++;
    state = AsyncData(
      value.copyWith(
        clearPickup: true,
        resetPromo: resetPromo,
        markers: _syncRideMarkers(
          base: value.markers,
          pickup: null,
          dropOff: value.dropOff,
          clearRideMarkers: true,
        ),
        polylines: _syncPickupDropOffPolyline(
          base: value.polylines,
          pickup: null,
          dropOff: value.dropOff,
        ),
        routeDistanceKm: 0,
        routeDurationSeconds: 0,
        clearEstimatedFare: true,
        isFareLoading: false,
        clearPromoError: true,
        isApplyingPromoCode: false,
      ),
    );
  }

  void clearDropOffLocation() {
    final value = state.value;
    if (value == null) return;
    _routeBuildToken++;
    state = AsyncData(
      value.copyWith(
        clearDropOff: true,
        markers: _syncRideMarkers(
          base: value.markers,
          pickup: value.pickup,
          dropOff: null,
          clearRideMarkers: true,
        ),
        polylines: _syncPickupDropOffPolyline(
          base: value.polylines,
          pickup: value.pickup,
          dropOff: null,
        ),
        routeDistanceKm: 0,
        routeDurationSeconds: 0,
        clearEstimatedFare: true,
        isFareLoading: false,
        clearPromoError: true,
        isApplyingPromoCode: false,
        resetPromo: true,
      ),
    );
  }

  void clearDriverLocation() {
    final value = state.value;
    if (value == null) return;
    _driverAnimationToken++;
    _currentDriverRotation = 0.0;
    _lastDriverLocationTime = null;
    state = AsyncData(
      value.copyWith(
        clearDriver: true,
        markers: _syncDriverMarker(base: value.markers, driver: null),
      ),
    );
  }

  Future<LatLng> _resolveInitialLatLng() async {
    try {
      final last = await _locationService.getLastKnownLocation();
      if (last != null) {
        final LatLng latLng = LatLng(last.latitude, last.longitude);
        if (activeRegion.contains(latLng)) {
          return latLng;
        }
      }
    } catch (_) {}

    try {
      final current = await _locationService.getCurrentLocation(
        requestPermissionIfNeeded: false,
      );
      final LatLng latLng = LatLng(current.latitude, current.longitude);
      if (activeRegion.contains(latLng)) {
        return latLng;
      }
      return activeRegion.center;
    } catch (_) {
      return activeRegion.center;
    }
  }

  Set<Marker> _syncRideMarkers({
    required Set<Marker> base,
    required MapNamedPoint? pickup,
    required MapNamedPoint? dropOff,
    bool clearRideMarkers = false,
  }) {
    final markers = <Marker>{
      ...base.where(
        (m) => clearRideMarkers ? !_isRideMarker(m.markerId) : true,
      ),
    };

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: _pickupMarkerIdFor(pickup.latLng),
          position: pickup.latLng,
          infoWindow: InfoWindow(title: pickup.name),
          icon:
              _pickupMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (dropOff != null) {
      markers.add(
        Marker(
          markerId: _dropOffMarkerIdFor(dropOff.latLng),
          position: dropOff.latLng,
          infoWindow: InfoWindow(title: dropOff.name),
          icon:
              _dropOffMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    return markers;
  }

  MarkerId _pickupMarkerIdFor(LatLng latLng) {
    return MarkerId(
      '$_pickupMarkerPrefix${latLng.latitude}_${latLng.longitude}',
    );
  }

  MarkerId _dropOffMarkerIdFor(LatLng latLng) {
    return MarkerId(
      '$_dropOffMarkerPrefix${latLng.latitude}_${latLng.longitude}',
    );
  }

  bool _isRideMarker(MarkerId markerId) {
    return markerId.value.startsWith(_pickupMarkerPrefix) ||
        markerId.value.startsWith(_dropOffMarkerPrefix);
  }

  LatLng _withCameraOffset(LatLng source) {
    return activeRegion.clamp(source);
  }

  bool _isWithinActiveRegion(LatLng latLng) {
    return activeRegion.contains(latLng);
  }

  List<LatLng> _routeCameraPoints(MapState mapState) {
    Polyline? routePolyline;
    for (final Polyline polyline in mapState.polylines) {
      if (polyline.polylineId == _pickupDropOffPolylineId) {
        routePolyline = polyline;
        break;
      }
    }

    if (routePolyline != null && routePolyline.points.length >= 2) {
      return routePolyline.points;
    }

    final MapNamedPoint? pickup = mapState.pickup;
    final MapNamedPoint? dropOff = mapState.dropOff;
    if (pickup == null || dropOff == null) {
      return const <LatLng>[];
    }

    return <LatLng>[pickup.latLng, dropOff.latLng];
  }

  Set<Marker> _syncDriverMarker({
    required Set<Marker> base,
    required MapNamedPoint? driver,
    double rotation = 0,
  }) {
    final markers = <Marker>{
      ...base.where((m) => m.markerId != _driverMarkerId),
    };

    if (driver == null) {
      return markers;
    }

    markers.add(
      Marker(
        markerId: _driverMarkerId,
        position: driver.latLng,
        infoWindow: InfoWindow(title: driver.name),
        icon:
            _driverMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: rotation,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ),
    );
    return markers;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * math.pi / 180;
    final double lng1 = start.longitude * math.pi / 180;
    final double lat2 = end.latitude * math.pi / 180;
    final double lng2 = end.longitude * math.pi / 180;

    final double dLng = lng2 - lng1;
    final double y = math.sin(dLng) * math.cos(lat2);
    final double x =
        (math.cos(lat1) * math.sin(lat2)) -
        (math.sin(lat1) * math.cos(lat2) * math.cos(dLng));
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _calculateDistanceMeters(LatLng start, LatLng end) {
    final double lat1 = start.latitude * math.pi / 180;
    final double lng1 = start.longitude * math.pi / 180;
    final double lat2 = end.latitude * math.pi / 180;
    final double lng2 = end.longitude * math.pi / 180;

    final double dLat = lat2 - lat1;
    final double dLng = lng2 - lng1;

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return 6371000 * c;
  }

  double _lerpRotation(double start, double end, double t) {
    double diff = (end - start + 180) % 360 - 180;
    if (diff < -180) diff += 360;
    return (start + diff * t + 360) % 360;
  }

  LocationDialogType _dialogTypeFromPermissionResult(
    LocationPermissionResult result,
  ) {
    switch (result) {
      case LocationPermissionResult.denied:
        return LocationDialogType.permissionDenied;
      case LocationPermissionResult.permanentlyDenied:
        return LocationDialogType.permissionPermanentlyDenied;
      case LocationPermissionResult.serviceDisabled:
        return LocationDialogType.serviceDisabled;
      case LocationPermissionResult.error:
        return LocationDialogType.error;
      case LocationPermissionResult.granted:
        return LocationDialogType.none;
    }
  }

  String outsideRegionMessage() {
    return 'You are currently outside ${activeRegion.displayName}. Please choose a location within ${activeRegion.displayName} to continue.';
  }

  String _messageForPermissionResult(LocationPermissionResult result) {
    switch (result) {
      case LocationPermissionResult.denied:
        return 'Location permission denied';
      case LocationPermissionResult.permanentlyDenied:
        return 'Location permission permanently denied. Please enable it from app settings.';
      case LocationPermissionResult.serviceDisabled:
        return 'Location services are disabled';
      case LocationPermissionResult.error:
        return 'Could not request location permission';
      case LocationPermissionResult.granted:
        return '';
    }
  }

  String _normalizeLocationErrorMessage(Object error) {
    final String raw = error.toString().trim();
    if (raw.startsWith('LocationException:')) {
      return raw.replaceFirst('LocationException:', '').trim();
    }
    return raw;
  }

  Future<void> _loadMarkerIcons() async {
    _pickupMarkerIcon = await _loadBitmapDescriptor(
      AppIcons.locationMarker,
      fallbackHue: BitmapDescriptor.hueGreen,
      // width: _pickupMarkerIconSize,
      height: _pickupMarkerIconSize,
    );
    _dropOffMarkerIcon = await _loadBitmapDescriptor(
      AppIcons.stopMarker,
      fallbackHue: BitmapDescriptor.hueRed,
      // width: _dropOffMarkerIconSize,
      height: _dropOffMarkerIconSize,
    );
    _driverMarkerIcon = await _loadBitmapDescriptor(
      AppIcons.car,
      fallbackHue: BitmapDescriptor.hueAzure,
      // width: _driverMarkerIconSize,
      height: _driverMarkerIconSize,
    );
  }

  Future<BitmapDescriptor> _loadBitmapDescriptor(
    String assetPath, {
    required double fallbackHue,
    double? width,
    double? height,
  }) async {
    try {
      return await BitmapDescriptor.asset(
        const ImageConfiguration(),
        assetPath,
        width: width,
        height: height,
      );
    } catch (e, s) {
      log('Marker icon load failed for $assetPath', error: e, stackTrace: s);
      return BitmapDescriptor.defaultMarkerWithHue(fallbackHue);
    }
  }

  Set<Polyline> _syncPickupDropOffPolyline({
    required Set<Polyline> base,
    required MapNamedPoint? pickup,
    required MapNamedPoint? dropOff,
  }) {
    final polylines = <Polyline>{
      ...base.where((p) => p.polylineId != _pickupDropOffPolylineId),
    };

    if (pickup == null || dropOff == null) {
      return polylines;
    }

    polylines.add(
      Polyline(
        polylineId: _pickupDropOffPolylineId,
        points: <LatLng>[pickup.latLng, dropOff.latLng],
        color: const Color(0xFF2E7DFF),
        width: 5,
        geodesic: true,
      ),
    );
    return polylines;
  }

  Future<_RouteBuildResult> _buildPickupDropOffPolyline({
    required Set<Polyline> base,
    required MapNamedPoint? pickup,
    required MapNamedPoint? dropOff,
  }) async {
    if (pickup == null || dropOff == null) {
      return _RouteBuildResult(
        polylines: _syncPickupDropOffPolyline(
          base: base,
          pickup: pickup,
          dropOff: dropOff,
        ),
        distanceKm: 0,
        durationSeconds: 0,
      );
    }

    if (ApiEndpoints.useOsrmInDebug) {
      final _RouteMetrics? osrmRoute = await _fetchOsrmRouteMetrics(
        pickup: pickup.latLng,
        dropOff: dropOff.latLng,
      );
      if (osrmRoute != null && osrmRoute.points.length >= 2) {
        return _buildRouteResult(
          base: base,
          routePoints: osrmRoute.points,
          distanceKm: osrmRoute.distanceKm,
          durationSeconds: osrmRoute.durationSeconds,
        );
      }
    }

    final String apiKey = (ApiEndpoints.mapApiKey).trim();
    if (apiKey.isEmpty) {
      final List<LatLng> fallbackPoints = <LatLng>[
        pickup.latLng,
        dropOff.latLng,
      ];
      final double distanceKm = _calculateRouteDistanceKm(fallbackPoints);
      return _buildRouteResult(
        base: base,
        routePoints: fallbackPoints,
        distanceKm: distanceKm,
        durationSeconds: _estimateDurationSeconds(distanceKm),
      );
    }

    try {
      final PolylineResult result = await _polylinePoints
          .getRouteBetweenCoordinates(
            googleApiKey: apiKey,
            request: PolylineRequest(
              origin: PointLatLng(
                pickup.latLng.latitude,
                pickup.latLng.longitude,
              ),
              destination: PointLatLng(
                dropOff.latLng.latitude,
                dropOff.latLng.longitude,
              ),
              mode: TravelMode.driving,
            ),
          );

      if (result.points.isEmpty) {
        final List<LatLng> fallbackPoints = <LatLng>[
          pickup.latLng,
          dropOff.latLng,
        ];
        final double distanceKm = _calculateRouteDistanceKm(fallbackPoints);
        return _buildRouteResult(
          base: base,
          routePoints: fallbackPoints,
          distanceKm: distanceKm,
          durationSeconds: _estimateDurationSeconds(distanceKm),
        );
      }

      final List<LatLng> routePoints = result.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(growable: false);
      // final double distanceKm = _calculateRouteDistanceKm(routePoints);
      final double distanceKm = ((result.totalDistanceValue ?? 0) / 1000)
          .toDouble();
      final int durationSeconds = result.totalDurationValue ?? 0;
      return _buildRouteResult(
        base: base,
        routePoints: routePoints,
        distanceKm: distanceKm,
        durationSeconds: durationSeconds,
      );
    } catch (e, s) {
      log('Route polyline fetch failed', error: e, stackTrace: s);
      final List<LatLng> fallbackPoints = <LatLng>[
        pickup.latLng,
        dropOff.latLng,
      ];
      final double distanceKm = _calculateRouteDistanceKm(fallbackPoints);
      return _buildRouteResult(
        base: base,
        routePoints: fallbackPoints,
        distanceKm: distanceKm,
        durationSeconds: _estimateDurationSeconds(distanceKm),
      );
    }
  }

  _RouteBuildResult _buildRouteResult({
    required Set<Polyline> base,
    required List<LatLng> routePoints,
    required double distanceKm,
    required int durationSeconds,
  }) {
    final polylines = <Polyline>{
      ...base.where((p) => p.polylineId != _pickupDropOffPolylineId),
    };
    polylines.add(
      Polyline(
        polylineId: _pickupDropOffPolylineId,
        points: routePoints,
        color: AppColors.brand,
        width: 3,
        geodesic: true,
      ),
    );
    return _RouteBuildResult(
      polylines: polylines,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
    );
  }

  double _calculateRouteDistanceKm(List<LatLng> routePoints) {
    if (routePoints.length < 2) return 0;
    double distanceMeters = 0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      final LatLng start = routePoints[i];
      final LatLng end = routePoints[i + 1];
      distanceMeters += _locationService.calculateDistance(
        startLatitude: start.latitude,
        startLongitude: start.longitude,
        endLatitude: end.latitude,
        endLongitude: end.longitude,
      );
    }
    return distanceMeters / 1000;
  }

  int _estimateDurationSeconds(double distanceKm) {
    if (distanceKm <= 0) return 0;
    // Fallback average speed (urban traffic) when provider duration is unavailable.
    const double averageSpeedKmPerHour = 30;
    final double hours = distanceKm / averageSpeedKmPerHour;
    return (hours * 3600).round();
  }

  Future<_RouteMetrics?> _fetchOsrmRouteMetrics({
    required LatLng pickup,
    required LatLng dropOff,
  }) async {
    try {
      final String coordinates =
          '${pickup.longitude},${pickup.latitude};'
          '${dropOff.longitude},${dropOff.latitude}';
      final Uri uri = Uri.parse(
        '$_osrmBaseUrl/route/v1/driving/$coordinates'
        '?overview=full&geometries=polyline&steps=false',
      );

      final Response<dynamic> response = await _dio.getUri(uri);
      final dynamic payload = response.data;
      final Map<String, dynamic> data = payload is Map<String, dynamic>
          ? payload
          : Map<String, dynamic>.from(jsonDecode(payload.toString()) as Map);

      final List<dynamic> routes = (data['routes'] as List<dynamic>? ?? []);
      if (routes.isEmpty) return null;

      final Map<String, dynamic> firstRoute =
          routes.first is Map<String, dynamic>
          ? routes.first as Map<String, dynamic>
          : Map<String, dynamic>.from(routes.first as Map);

      final String geometry = (firstRoute['geometry'] ?? '').toString();
      if (geometry.isEmpty) return null;

      final decoded = _polylinePoints.decodePolyline(geometry);
      if (decoded.isEmpty) return null;

      final List<LatLng> points = decoded
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(growable: false);
      final double distanceMeters =
          (firstRoute['distance'] as num?)?.toDouble() ?? 0;
      final int durationSeconds =
          ((firstRoute['duration'] as num?)?.toDouble() ?? 0).round();

      return _RouteMetrics(
        points: points,
        distanceKm: distanceMeters / 1000,
        durationSeconds: durationSeconds,
      );
    } catch (e, s) {
      log('OSRM route fetch failed', error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> _updateFareEstimate(MapState mapState) async {
    final String? rideType = mapState.selectedRideType;
    if (rideType == null ||
        rideType.isEmpty ||
        !mapState.isRideReady ||
        mapState.routeDistanceKm <= 0) {
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(
          clearEstimatedFare: true,
          isFareLoading: false,
          clearPromoError: true,
          isApplyingPromoCode: false,
        ),
      );
      return;
    }

    final latestBeforeRequest = state.value;
    if (latestBeforeRequest == null) return;
    state = AsyncData(latestBeforeRequest.copyWith(isFareLoading: true));

    final String pickupCity =
        (mapState.pickup?.city?.trim().isNotEmpty ?? false)
        ? mapState.pickup!.city!
        : "";

    final result = await _calculateFareUseCase(
      FareCalculatorParams(
        miles: distanceInMiles(mapState.routeDistanceKm),
        rideType: rideType,
        pickupCity: pickupCity,
      ),
    );

    final latest = state.value;
    if (latest == null) return;

    // Parameter safeguard: Discard result if parameters changed while request was in-flight
    if (latest.selectedRideType != rideType ||
        latest.pickup?.latLng != mapState.pickup?.latLng ||
        latest.dropOff?.latLng != mapState.dropOff?.latLng) {
      log('Aborting fare calculation update: parameters have changed.');
      return;
    }

    result.fold(
      (failure) {
        log('Fare estimate fetch failed: ${failure.message}');
        state = AsyncData(
          latest.copyWith(
            clearEstimatedFare: true,
            isFareLoading: false,
            clearPromoError: true,
            isApplyingPromoCode: false,
          ),
        );
      },
      (fareQuote) {
        final int? percentage = latest.promoAppliedPercentage;
        num? discounted;

        if (percentage != null && percentage > 0) {
          discounted = fareQuote.primaryFare * (1 - percentage / 100);
        }

        state = AsyncData(
          latest.copyWith(
            estimatedFare: fareQuote.primaryFare,
            clearEstimatedFare: false,
            isFareLoading: false,
            discountedFare: discounted,
            clearDiscountedFare: discounted == null,
            clearPromoError: true,
            isApplyingPromoCode: false,
          ),
        );
      },
    );
  }

  Set<Polyline> _consumePickupDropOffPolylineByDriver({
    required Set<Polyline> base,
    required LatLng driverLatLng,
  }) {
    final Polyline? route = base
        .where((p) => p.polylineId == _pickupDropOffPolylineId)
        .cast<Polyline?>()
        .firstWhere((p) => p != null, orElse: () => null);

    if (route == null || route.points.length < 2) {
      return base;
    }

    final points = route.points;

    final math.Point<num> driver = math.Point(
      driverLatLng.longitude,
      driverLatLng.latitude,
    );

    int nearestIndex = -1;
    double minDistance = double.infinity;
    LatLng? snappedLatLng;

    for (int i = 0; i < points.length - 1; i++) {
      final LatLng a = points[i];
      final LatLng b = points[i + 1];

      final math.Point<num> p1 = math.Point(a.longitude, a.latitude);
      final math.Point<num> p2 = math.Point(b.longitude, b.latitude);

      final double distance = utils.PolyUtils.distanceToLine(
        driver,
        p1,
        p2,
      ).toDouble();

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;

        // 🔥 MANUAL projection onto segment
        snappedLatLng = _projectPointOnSegment(driverLatLng, a, b);
      }
    }

    const double toleranceMeters = 15;

    // ❌ Driver is off-route → do nothing
    if (nearestIndex == -1 ||
        minDistance > toleranceMeters ||
        snappedLatLng == null) {
      return base;
    }

    final updatedPoints = <LatLng>[
      snappedLatLng,
      ...points.skip(nearestIndex + 1),
    ];

    final polylines = <Polyline>{
      ...base.where((p) => p.polylineId != _pickupDropOffPolylineId),
    };

    if (updatedPoints.length < 2) return polylines;

    polylines.add(route.copyWith(pointsParam: updatedPoints));

    return polylines;
  }

  Future<void> _checkDeviationAndReroute(LatLng driverLatLng) async {
    if (_isRerouting) return;

    final current = state.value;
    if (current == null) return;

    final Polyline? routePolyline = current.polylines
        .where((p) => p.polylineId == _pickupDropOffPolylineId)
        .cast<Polyline?>()
        .firstWhere((p) => p != null, orElse: () => null);

    if (routePolyline == null || routePolyline.points.length < 2) return;

    final detector = RouteDeviationDetector(deviationThresholdMeters: 50.0);
    final hasDeviated = detector.hasDeviated(
      driverLatLng,
      routePolyline.points,
    );

    if (hasDeviated) {
      log('Driver has deviated from route. Rerouting...');
      _isRerouting = true;
      try {
        final LatLng destination = routePolyline.points.last;
        final String apiKey = ApiEndpoints.mapApiKey.trim();

        List<LatLng> newPoints = [];
        double newDistanceKm = 0;
        int newDurationSeconds = 0;

        if (ApiEndpoints.useOsrmInDebug) {
          final osrmRoute = await _fetchOsrmRouteMetrics(
            pickup: driverLatLng,
            dropOff: destination,
          );
          if (osrmRoute != null && osrmRoute.points.length >= 2) {
            newPoints = osrmRoute.points;
            newDistanceKm = osrmRoute.distanceKm;
            newDurationSeconds = osrmRoute.durationSeconds;
          }
        }

        if (newPoints.isEmpty && apiKey.isNotEmpty) {
          final result = await _polylinePoints.getRouteBetweenCoordinates(
            googleApiKey: apiKey,
            request: PolylineRequest(
              origin: PointLatLng(
                driverLatLng.latitude,
                driverLatLng.longitude,
              ),
              destination: PointLatLng(
                destination.latitude,
                destination.longitude,
              ),
              mode: TravelMode.driving,
            ),
          );

          if (result.points.isNotEmpty) {
            final double distanceKm = ((result.totalDistanceValue ?? 0) / 1000)
                .toDouble();
            final int durationSeconds = result.totalDurationValue ?? 0;
            newPoints = result.points
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList();
            newDistanceKm = distanceKm;
            newDurationSeconds = durationSeconds;
          }
        }

        if (newPoints.isNotEmpty) {
          final updatedPolylines = <Polyline>{
            ...current.polylines.where(
              (p) => p.polylineId != _pickupDropOffPolylineId,
            ),
          };
          updatedPolylines.add(
            Polyline(
              polylineId: _pickupDropOffPolylineId,
              points: newPoints,
              color: AppColors.brand,
              width: 3,
              geodesic: true,
            ),
          );

          final latest = state.value;
          if (latest != null) {
            state = AsyncData(
              latest.copyWith(
                polylines: updatedPolylines,
                routeDistanceKm: newDistanceKm,
                routeDurationSeconds: newDurationSeconds,
              ),
            );
          }
        }
      } catch (e, s) {
        log('Rerouting failed', error: e, stackTrace: s);
      } finally {
        _isRerouting = false;
      }
    }
  }
}

LatLng _projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
  final double ax = a.longitude;
  final double ay = a.latitude;
  final double bx = b.longitude;
  final double by = b.latitude;
  final double px = p.longitude;
  final double py = p.latitude;

  final double dx = bx - ax;
  final double dy = by - ay;

  if (dx == 0 && dy == 0) return a;

  final double t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);

  final double clampedT = t.clamp(0.0, 1.0);

  return LatLng(ay + clampedT * dy, ax + clampedT * dx);
}

/// OLD IMplementation

//   Set<Polyline> _consumePickupDropOffPolylineByDriver({
//     required Set<Polyline> base,
//     required LatLng driverLatLng,
//   }) {
//     final Polyline? route = base
//         .where((p) => p.polylineId == _pickupDropOffPolylineId)
//         .cast<Polyline?>()
//         .firstWhere((p) => p != null, orElse: () => null);

//     if (route == null || route.points.length < 2) {
//       return base;
//     }

//     final List<LatLng> points = route.points;
//     final math.Point<num> driverPoint = math.Point<num>(
//       driverLatLng.longitude,
//       driverLatLng.latitude,
//     );
//     final List<math.Point<num>> polylinePath = points
//         .map((point) => math.Point<num>(point.longitude, point.latitude))
//         .toList(growable: false);

//     final bool isOnPath = utils.PolyUtils.isLocationOnPathTolerance(
//       driverPoint,
//       polylinePath,
//       false,
//       _polylineTrimToleranceMeters,
//     );
//     if (!isOnPath) {
//       return base;
//     }

//     int nearestIndex = -1;
//     double? nearestDistanceMeters;

//     for (int i = 0; i < points.length; i++) {
//       final LatLng point = points[i];
//       final double distanceMeters = utils.SphericalUtils.computeDistanceBetween(
//         driverPoint,
//         math.Point<num>(point.longitude, point.latitude),
//       ).toDouble();

//       if (nearestDistanceMeters == null ||
//           distanceMeters < nearestDistanceMeters) {
//         nearestDistanceMeters = distanceMeters;
//         nearestIndex = i;
//       }
//     }

//     if (nearestIndex == -1 ||
//         nearestDistanceMeters == null ||
//         nearestDistanceMeters > _polylineTrimToleranceMeters) {
//       return base;
//     }

//     final List<LatLng> updatedPoints = <LatLng>[
//       driverLatLng,
//       ...points.skip(nearestIndex + 1),
//     ];

//     final polylines = <Polyline>{
//       ...base.where((p) => p.polylineId != _pickupDropOffPolylineId),
//     };

//     if (updatedPoints.length < 2) {
//       return polylines;
//     }

//     polylines.add(route.copyWith(pointsParam: updatedPoints));
//     return polylines;
//   }
// }

class _RouteBuildResult {
  final Set<Polyline> polylines;
  final double distanceKm;
  final int durationSeconds;

  const _RouteBuildResult({
    required this.polylines,
    required this.distanceKm,
    required this.durationSeconds,
  });
}

class _RouteMetrics {
  final List<LatLng> points;
  final double distanceKm;
  final int durationSeconds;

  const _RouteMetrics({
    required this.points,
    required this.distanceKm,
    required this.durationSeconds,
  });
}
