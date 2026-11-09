import 'dart:async';
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
import 'package:ride_app/core/services/location_service.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_response_entity.dart';
import 'package:ride_app/features/ride_room/presentation/states/carpool_map_state.dart';

final carpoolMapProvider =
    AsyncNotifierProvider<CarpoolMapProvider, CarpoolMapState>(
      CarpoolMapProvider.new,
    );

class CarpoolMapProvider extends AsyncNotifier<CarpoolMapState> {
  static const LatLng _defaultLatLng = LatLng(28.5384, -81.3789);
  static const double _defaultZoom = 14;
  // static const double _polylineTrimToleranceMeters = 8;
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  static const MarkerId _pickupMarkerId = MarkerId('carpool_pickup_marker');
  static const MarkerId _dropOffMarkerId = MarkerId('carpool_dropoff_marker');
  static const MarkerId _driverMarkerId = MarkerId('carpool_driver_marker');
  static const String _stopMarkerPrefix = 'carpool_stop_marker_';
  static const PolylineId _routePolylineId = PolylineId(
    'carpool_route_polyline',
  );

  static const double _pickupMarkerIconSize = 35;
  static const double _dropOffMarkerIconSize = 40;
  static const double _stopMarkerIconSize = 40;
  static const double _driverMarkerIconSize = 30;

  late LocationService _locationService;
  final PolylinePoints _polylinePoints = PolylinePoints();
  final Dio _dio = Dio();
  BitmapDescriptor? _pickupMarkerIcon;
  BitmapDescriptor? _dropOffMarkerIcon;
  BitmapDescriptor? _stopMarkerIcon;
  BitmapDescriptor? _driverMarkerIcon;
  int _driverAnimationToken = 0;
  double _currentDriverRotation = 0.0;
  DateTime? _lastDriverLocationTime;

  @override
  Future<CarpoolMapState> build() async {
    _locationService = locator<LocationService>();
    await _loadMarkerIcons();

    final String light = await rootBundle.loadString(
      'assets/map_style/light_map.json',
    );
    final String dark = await rootBundle.loadString(
      'assets/map_style/dark_map.json',
    );

    final LatLng initialLatLng = await _resolveInitialLatLng();
    final String initialPlaceName = await _locationService
        .getPlaceNameFromCoordinates(
          initialLatLng.latitude,
          initialLatLng.longitude,
          fallback: 'Current Location',
          reason: 'initial_position',
        );

    return CarpoolMapState(
      lightMapStyle: light,
      darkMapStyle: dark,
      currentLocation: CarpoolMapNamedPoint(
        latLng: initialLatLng,
        name: initialPlaceName,
      ),
      cameraPosition: CameraPosition(
        target: _withCameraOffset(initialLatLng),
        zoom: _defaultZoom,
      ),
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

  void onCameraMove(CameraPosition position) {
    final value = state.value;
    if (value == null) return;
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

  Future<void> refreshCurrentLocation({bool moveCamera = true}) async {
    final value = await _getReadyState();
    if (value == null) return;

    try {
      final position = await _locationService.getCurrentLocation(
        requestPermissionIfNeeded: false,
      );
      final LatLng latLng = LatLng(position.latitude, position.longitude);
      final String placeName = await _locationService
          .getPlaceNameFromCoordinates(
            latLng.latitude,
            latLng.longitude,
            fallback: 'Current Location',
            reason: 'initial_position',
          );

      state = AsyncData(
        value.copyWith(
          currentLocation: CarpoolMapNamedPoint(
            latLng: latLng,
            name: placeName,
          ),
          cameraPosition: moveCamera
              ? CameraPosition(
                  target: _withCameraOffset(latLng),
                  zoom: value.cameraPosition.zoom,
                  tilt: value.cameraPosition.tilt,
                  bearing: value.cameraPosition.bearing,
                )
              : value.cameraPosition,
          clearError: true,
        ),
      );
    } catch (e, s) {
      log('Carpool current location refresh failed', error: e, stackTrace: s);
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(latest.copyWith(errorMessage: e.toString()));
    }
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

  Future<void> syncRideRoute({
    required CarpoolRideEntity ride,
    LatLng? driverLatLng,
    String? driverName,
  }) async {
    final value = await _getReadyState();
    if (value == null) return;

    final CarpoolMapNamedPoint? pickup = _resolvePickupPoint(ride);
    final CarpoolMapNamedPoint? dropOff = _resolveDropOffPoint(ride);
    if (pickup == null || dropOff == null) return;

    final List<CarpoolMapNamedPoint> stops = _resolveIntermediateStops(ride);
    final String routeSignature = _buildRouteSignature(
      pickup: pickup,
      stops: stops,
      dropOff: dropOff,
    );

    final Set<Marker> markers = _buildMarkers(
      pickup: pickup,
      dropOff: dropOff,
      stops: stops,
      driver: value.driver,
    );

    final bool shouldRebuildRoute =
        routeSignature != value.routeSignature || value.polylines.isEmpty;
    final _RouteBuildResult routeResult = shouldRebuildRoute
        ? await _buildCarpoolRoute(
            base: value.polylines,
            pickup: pickup,
            stops: stops,
            dropOff: dropOff,
          )
        : _RouteBuildResult(polylines: value.polylines);

    final CarpoolMapNamedPoint? driver = driverLatLng == null
        ? value.driver
        : CarpoolMapNamedPoint(
            latLng: driverLatLng,
            name: (driverName ?? '').trim().isEmpty
                ? (ride.driver?.fullName.trim().isNotEmpty ?? false)
                      ? ride.driver!.fullName
                      : 'Driver'
                : driverName!.trim(),
          );

    final Set<Marker> nextMarkers = _syncDriverMarker(
      base: markers,
      driver: driver,
    );

    final List<LatLng> cameraPoints = <LatLng>[
      pickup.latLng,
      ...stops.map((CarpoolMapNamedPoint stop) => stop.latLng),
      dropOff.latLng,
      if (driver != null) driver.latLng,
    ];

    state = AsyncData(
      value.copyWith(
        pickup: pickup,
        dropOff: dropOff,
        stops: stops,
        driver: driver,
        markers: nextMarkers,
        polylines: routeResult.polylines,
        cameraPosition: CameraPosition(
          target: _centerOf(cameraPoints),
          zoom: value.cameraPosition.zoom,
        ),
        routeSignature: routeSignature,
        clearError: true,
      ),
    );
  }

  Future<void> setDriverLocation(LatLng latLng, {String? name}) async {
    final initial = await _getReadyState();
    if (initial == null || !_isWithinActiveRegion(latLng)) return;

    final String resolvedName = (name ?? '').trim().isEmpty
        ? 'Driver'
        : name!.trim();
    final int token = ++_driverAnimationToken;
    final CarpoolMapNamedPoint next = CarpoolMapNamedPoint(
      latLng: latLng,
      name: resolvedName,
    );

    if (initial.driver == null) {
      _currentDriverRotation = 0.0;
      state = AsyncData(
        initial.copyWith(
          driver: next,
          markers: _syncDriverMarker(base: initial.markers, driver: next),
          polylines: _consumeRoutePolylineByDriver(
            base: initial.polylines,
            driverLatLng: latLng,
          ),
          cameraPosition: _cameraPositionWithTarget(
            initial.cameraPosition,
            latLng,
          ),
        ),
      );
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

      final CarpoolMapNamedPoint intermediateDriver = CarpoolMapNamedPoint(
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
          polylines: shouldTrimPolyline
              ? _consumeRoutePolylineByDriver(
                  base: current.polylines,
                  driverLatLng: intermediate,
                )
              : current.polylines,
        ),
      );
    }
  }

  void clearRideMapData() {
    final value = state.value;
    if (value == null) return;
    _driverAnimationToken++;
    _currentDriverRotation = 0.0;
    _lastDriverLocationTime = null;
    state = AsyncData(
      value.copyWith(
        clearPickup: true,
        clearDropOff: true,
        clearDriver: true,
        clearStops: true,
        markers: const <Marker>{},
        polylines: const <Polyline>{},
        circles: const <Circle>{},
        routeSignature: '',
        cameraPosition: CameraPosition(
          target: _withCameraOffset(value.currentLocation.latLng),
          zoom: _defaultZoom,
        ),
        clearError: true,
      ),
    );
  }

  Future<CarpoolMapState?> _getReadyState() async {
    final current = state.value;
    if (current != null) return current;
    try {
      return await future;
    } catch (_) {
      return state.value;
    }
  }

  CarpoolMapNamedPoint? _resolvePickupPoint(CarpoolRideEntity ride) {
    final CarpoolRideStopEntity? stop =
        ride.resolvedPickupStop ??
        (ride.routes.isNotEmpty ? ride.routes.first : null);
    if (stop == null) return null;
    return CarpoolMapNamedPoint(
      latLng: LatLng(stop.location.latitude, stop.location.longitude),
      name: stop.placeName.trim().isEmpty ? 'Pickup' : stop.placeName.trim(),
    );
  }

  CarpoolMapNamedPoint? _resolveDropOffPoint(CarpoolRideEntity ride) {
    final CarpoolRideStopEntity? stop =
        ride.resolvedDropOffStop ??
        (ride.routes.isNotEmpty ? ride.routes.last : null);
    if (stop == null) return null;
    return CarpoolMapNamedPoint(
      latLng: LatLng(stop.location.latitude, stop.location.longitude),
      name: stop.placeName.trim().isEmpty ? 'Drop Off' : stop.placeName.trim(),
    );
  }

  List<CarpoolMapNamedPoint> _resolveIntermediateStops(CarpoolRideEntity ride) {
    final String pickupId = ride.resolvedPickupStop?.id ?? '';
    final String dropOffId = ride.resolvedDropOffStop?.id ?? '';

    return ride.routes
        .where((CarpoolRideStopEntity stop) {
          final String stopId = stop.id.trim();
          if (stopId.isNotEmpty && stopId == pickupId) return false;
          if (stopId.isNotEmpty && stopId == dropOffId) return false;
          return true;
        })
        .map(
          (CarpoolRideStopEntity stop) => CarpoolMapNamedPoint(
            latLng: LatLng(stop.location.latitude, stop.location.longitude),
            name: stop.placeName.trim().isEmpty
                ? 'Stop'
                : stop.placeName.trim(),
          ),
        )
        .toList(growable: false);
  }

  String _buildRouteSignature({
    required CarpoolMapNamedPoint pickup,
    required List<CarpoolMapNamedPoint> stops,
    required CarpoolMapNamedPoint dropOff,
  }) {
    final Iterable<CarpoolMapNamedPoint> points = <CarpoolMapNamedPoint>[
      pickup,
      ...stops,
      dropOff,
    ];
    return points
        .map(
          (CarpoolMapNamedPoint point) =>
              '${point.name}:${point.latLng.latitude},${point.latLng.longitude}',
        )
        .join('|');
  }

  Set<Marker> _buildMarkers({
    required CarpoolMapNamedPoint pickup,
    required CarpoolMapNamedPoint dropOff,
    required List<CarpoolMapNamedPoint> stops,
    required CarpoolMapNamedPoint? driver,
  }) {
    final Set<Marker> markers = <Marker>{
      Marker(
        markerId: _pickupMarkerId,
        position: pickup.latLng,
        infoWindow: InfoWindow(title: pickup.name),
        icon:
            _pickupMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: _dropOffMarkerId,
        position: dropOff.latLng,
        infoWindow: InfoWindow(title: dropOff.name),
        icon:
            _dropOffMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    for (int i = 0; i < stops.length; i++) {
      final CarpoolMapNamedPoint stop = stops[i];
      markers.add(
        Marker(
          markerId: MarkerId('$_stopMarkerPrefix$i'),
          position: stop.latLng,
          infoWindow: InfoWindow(title: stop.name),
          icon:
              _stopMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    return _syncDriverMarker(base: markers, driver: driver);
  }

  Set<Marker> _syncDriverMarker({
    required Set<Marker> base,
    required CarpoolMapNamedPoint? driver,
    double rotation = 0,
  }) {
    final Set<Marker> markers = <Marker>{
      ...base.where((Marker marker) => marker.markerId != _driverMarkerId),
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

  Future<_RouteBuildResult> _buildCarpoolRoute({
    required Set<Polyline> base,
    required CarpoolMapNamedPoint pickup,
    required List<CarpoolMapNamedPoint> stops,
    required CarpoolMapNamedPoint dropOff,
  }) async {
    final List<LatLng> waypoints = _dedupePoints(<LatLng>[
      pickup.latLng,
      ...stops.map((CarpoolMapNamedPoint stop) => stop.latLng),
      dropOff.latLng,
    ]);

    if (waypoints.length < 2) {
      return const _RouteBuildResult(polylines: <Polyline>{});
    }

    final List<LatLng> completeRoute = <LatLng>[];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final LatLng origin = waypoints[i];
      final LatLng destination = waypoints[i + 1];
      final List<LatLng> segment = await _fetchRoutePoints(
        origin: origin,
        destination: destination,
      );

      if (segment.isEmpty) {
        if (completeRoute.isEmpty || completeRoute.last != origin) {
          completeRoute.add(origin);
        }
        completeRoute.add(destination);
        continue;
      }

      if (completeRoute.isEmpty) {
        completeRoute.addAll(segment);
        continue;
      }

      completeRoute.addAll(segment.skip(1));
    }

    final Set<Polyline> polylines = <Polyline>{
      ...base.where(
        (Polyline polyline) => polyline.polylineId != _routePolylineId,
      ),
      Polyline(
        polylineId: _routePolylineId,
        points: completeRoute,
        color: AppColors.brand,
        width: 3,
        geodesic: true,
      ),
    };

    return _RouteBuildResult(polylines: polylines);
  }

  Future<List<LatLng>> _fetchRoutePoints({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (ApiEndpoints.useOsrmInDebug) {
      final List<LatLng>? osrmRoute = await _fetchOsrmRoute(
        origin: origin,
        destination: destination,
      );
      if (osrmRoute != null && osrmRoute.length >= 2) {
        return osrmRoute;
      }
    }

    final String apiKey = (ApiEndpoints.mapApiKey).trim();
    if (apiKey.isEmpty) {
      return <LatLng>[origin, destination];
    }

    try {
      final PolylineResult result = await _polylinePoints
          .getRouteBetweenCoordinates(
            googleApiKey: apiKey,
            request: PolylineRequest(
              origin: PointLatLng(origin.latitude, origin.longitude),
              destination: PointLatLng(
                destination.latitude,
                destination.longitude,
              ),
              mode: TravelMode.driving,
            ),
          );

      if (result.points.isEmpty) {
        return <LatLng>[origin, destination];
      }

      return result.points
          .map((PointLatLng point) => LatLng(point.latitude, point.longitude))
          .toList(growable: false);
    } catch (e, s) {
      log('Carpool route polyline fetch failed', error: e, stackTrace: s);
      return <LatLng>[origin, destination];
    }
  }

  Future<List<LatLng>?> _fetchOsrmRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final Uri uri = Uri.parse(
        '$_osrmBaseUrl/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline&steps=false',
      );

      final Response<dynamic> response = await _dio.getUri(uri);
      final dynamic payload = response.data;
      final Map<String, dynamic> data = payload is Map<String, dynamic>
          ? payload
          : Map<String, dynamic>.from(jsonDecode(payload.toString()) as Map);
      final List<dynamic> routes =
          data['routes'] as List<dynamic>? ?? <dynamic>[];
      if (routes.isEmpty) return null;

      final Map<String, dynamic> firstRoute =
          routes.first is Map<String, dynamic>
          ? routes.first as Map<String, dynamic>
          : Map<String, dynamic>.from(routes.first as Map);
      final String geometry = (firstRoute['geometry'] ?? '').toString();
      if (geometry.isEmpty) return null;

      final List<PointLatLng> decoded = _polylinePoints.decodePolyline(
        geometry,
      );
      if (decoded.isEmpty) return null;

      return decoded
          .map((PointLatLng point) => LatLng(point.latitude, point.longitude))
          .toList(growable: false);
    } catch (e, s) {
      log('Carpool OSRM route fetch failed', error: e, stackTrace: s);
      return null;
    }
  }

  Set<Polyline> _consumeRoutePolylineByDriver({
    required Set<Polyline> base,
    required LatLng driverLatLng,
  }) {
    final Polyline? route = base
        .where((polyline) => polyline.polylineId == _routePolylineId)
        .cast<Polyline?>()
        .firstWhere((polyline) => polyline != null, orElse: () => null);

    if (route == null || route.points.length < 2) {
      return base;
    }

    final List<LatLng> points = route.points;

    final math.Point<num> driverPoint = math.Point<num>(
      driverLatLng.longitude,
      driverLatLng.latitude,
    );

    int nearestIndex = -1;
    double minDistance = double.infinity;

    // 🔥 Find nearest SEGMENT (not point)
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];

      final math.Point<num> p1 = math.Point(a.longitude, a.latitude);
      final math.Point<num> p2 = math.Point(b.longitude, b.latitude);

      final double distance = utils.PolyUtils.distanceToLine(
        driverPoint,
        p1,
        p2,
      ).toDouble();

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // 🔥 STRICT tolerance gate (prevents wrong road shifting)
    const double toleranceMeters = 15;

    if (nearestIndex == -1 || minDistance > toleranceMeters) {
      return base; // ❌ driver is off-route → DO NOT MOVE POLYLINE
    }

    // 🔥 DO NOT use raw GPS point → prevents wrong-road jumps
    final LatLng snappedPoint = _snapToSegment(
      driverLatLng,
      points[nearestIndex],
      points[nearestIndex + 1],
    );

    final List<LatLng> updatedPoints = <LatLng>[
      snappedPoint,
      ...points.skip(nearestIndex + 1),
    ];

    final Set<Polyline> polylines = <Polyline>{
      ...base.where((p) => p.polylineId != _routePolylineId),
    };

    if (updatedPoints.length < 2) {
      return polylines;
    }

    polylines.add(route.copyWith(pointsParam: updatedPoints));

    return polylines;
  }

  LatLng _snapToSegment(LatLng p, LatLng a, LatLng b) {
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

  // Set<Polyline> _consumeRoutePolylineByDriver({
  //   required Set<Polyline> base,
  //   required LatLng driverLatLng,
  // }) {
  //   final Polyline? route = base
  //       .where((Polyline polyline) => polyline.polylineId == _routePolylineId)
  //       .cast<Polyline?>()
  //       .firstWhere(
  //         (Polyline? polyline) => polyline != null,
  //         orElse: () => null,
  //       );

  //   if (route == null || route.points.length < 2) {
  //     return base;
  //   }

  //   final List<LatLng> points = route.points;
  //   final math.Point<num> driverPoint = math.Point<num>(
  //     driverLatLng.longitude,
  //     driverLatLng.latitude,
  //   );
  //   final List<math.Point<num>> polylinePath = points
  //       .map((point) => math.Point<num>(point.longitude, point.latitude))
  //       .toList(growable: false);

  //   final bool isOnPath = utils.PolyUtils.isLocationOnPathTolerance(
  //     driverPoint,
  //     polylinePath,
  //     false,
  //     _polylineTrimToleranceMeters,
  //   );
  //   if (!isOnPath) {
  //     return base;
  //   }

  //   int nearestIndex = -1;
  //   double? nearestDistanceMeters;

  //   for (int i = 0; i < points.length; i++) {
  //     final LatLng point = points[i];
  //     final double distanceMeters = utils.SphericalUtils.computeDistanceBetween(
  //       driverPoint,
  //       math.Point<num>(point.longitude, point.latitude),
  //     ).toDouble();

  //     if (nearestDistanceMeters == null ||
  //         distanceMeters < nearestDistanceMeters) {
  //       nearestDistanceMeters = distanceMeters;
  //       nearestIndex = i;
  //     }
  //   }

  //   if (nearestIndex == -1 ||
  //       nearestDistanceMeters == null ||
  //       nearestDistanceMeters > _polylineTrimToleranceMeters) {
  //     return base;
  //   }

  //   final List<LatLng> updatedPoints = <LatLng>[
  //     driverLatLng,
  //     ...points.skip(nearestIndex + 1),
  //   ];
  //   final Set<Polyline> polylines = <Polyline>{
  //     ...base.where(
  //       (Polyline polyline) => polyline.polylineId != _routePolylineId,
  //     ),
  //   };

  //   if (updatedPoints.length < 2) {
  //     return polylines;
  //   }

  //   polylines.add(route.copyWith(pointsParam: updatedPoints));
  //   return polylines;
  // }

  List<LatLng> _dedupePoints(List<LatLng> points) {
    final List<LatLng> unique = <LatLng>[];
    for (final LatLng point in points) {
      if (unique.isEmpty ||
          unique.last.latitude != point.latitude ||
          unique.last.longitude != point.longitude) {
        unique.add(point);
      }
    }
    return unique;
  }

  LatLng _centerOf(List<LatLng> points) {
    if (points.isEmpty) return _defaultLatLng;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final LatLng point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return activeRegion.clamp(
      LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
    );
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

  Future<void> _loadMarkerIcons() async {
    _pickupMarkerIcon = await _loadBitmapDescriptor(
      AppIcons.locationMarker,
      fallbackHue: BitmapDescriptor.hueGreen,
      height: _pickupMarkerIconSize,
    );
    _dropOffMarkerIcon = await _loadBitmapDescriptor(
      AppIcons.stopMarker,
      fallbackHue: BitmapDescriptor.hueRed,
      height: _dropOffMarkerIconSize,
    );
    _stopMarkerIcon = await _loadBitmapDescriptor(
      AppIcons.stopMarker,
      fallbackHue: BitmapDescriptor.hueOrange,
      height: _stopMarkerIconSize,
    );
    _driverMarkerIcon = await _loadBitmapDescriptor(
      AppIcons.car,
      fallbackHue: BitmapDescriptor.hueAzure,
      height: _driverMarkerIconSize,
    );
  }

  Future<BitmapDescriptor> _loadBitmapDescriptor(
    String assetPath, {
    required double fallbackHue,
    double? height,
  }) async {
    try {
      return await BitmapDescriptor.asset(
        const ImageConfiguration(),
        assetPath,
        height: height,
      );
    } catch (e, s) {
      log(
        'Carpool marker icon load failed for $assetPath',
        error: e,
        stackTrace: s,
      );
      return BitmapDescriptor.defaultMarkerWithHue(fallbackHue);
    }
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

  LatLng _withCameraOffset(LatLng source) {
    return activeRegion.clamp(source);
  }

  bool _isWithinActiveRegion(LatLng latLng) {
    return activeRegion.contains(latLng);
  }

  CameraPosition _cameraPositionWithTarget(CameraPosition base, LatLng target) {
    return CameraPosition(
      target: activeRegion.clamp(target),
      zoom: base.zoom,
      tilt: base.tilt,
      bearing: base.bearing,
    );
  }
}

class _RouteBuildResult {
  final Set<Polyline> polylines;

  const _RouteBuildResult({required this.polylines});
}
