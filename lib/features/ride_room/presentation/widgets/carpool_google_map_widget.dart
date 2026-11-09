import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/carpool_map_state.dart';
import 'package:ride_app/features/ride_room/presentation/states/carpool_state.dart';

import '../../../../core/location/service_region.dart';
import '../../../../core/theme/map_styles.dart';

class CarpoolGoogleMapWidget extends ConsumerStatefulWidget {
  const CarpoolGoogleMapWidget({
    super.key,
    required this.brightness,
    required this.scrollGesturesEnabled,
    required this.onMapCreated,
    this.onCameraMoveStarted,
    this.onCameraIdle,
    this.onCameraMove,
    this.bottomPadding = 280,
  });

  final Brightness brightness;
  final bool scrollGesturesEnabled;
  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback? onCameraMoveStarted;
  final VoidCallback? onCameraIdle;
  final void Function(CameraPosition)? onCameraMove;
  final double bottomPadding;

  @override
  ConsumerState<CarpoolGoogleMapWidget> createState() =>
      _CarpoolGoogleMapWidgetState();
}

class _CarpoolGoogleMapWidgetState extends ConsumerState<CarpoolGoogleMapWidget>
    with TickerProviderStateMixin {
  static const PolylineId _routePolylineId = PolylineId(
    'carpool_route_polyline',
  );
  static const Duration _routeAnimationDuration = Duration(milliseconds: 3000);

  GoogleMapController? _googleMapController;
  late AnimationController _animationController;
  String _lastFittedKey = '';
  String _lastAnimatedRouteKey = '';
  bool _isProgrammaticCameraMove = false;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: _routeAnimationDuration, vsync: this)
          ..addListener(() {
            if (mounted) setState(() {});
          });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fitCameraToVisiblePoints(CarpoolMapState state) async {
    final GoogleMapController? controller = _googleMapController;
    if (controller == null) return;

    final List<LatLng> points = <LatLng>[
      if (state.driver != null) state.driver!.latLng,
      if (state.pickup != null) state.pickup!.latLng,
      ...state.stops.map((CarpoolMapNamedPoint stop) => stop.latLng),
      if (state.dropOff != null) state.dropOff!.latLng,
    ];
    if (points.isEmpty) return;

    if (points.length == 1) {
      await _animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }

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
      await _animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }

    await _animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        160,
      ),
    );
  }

  Future<void> _animateCamera(CameraUpdate cameraUpdate) async {
    final GoogleMapController? controller = _googleMapController;
    if (controller == null) return;

    _isProgrammaticCameraMove = true;
    try {
      await controller.animateCamera(cameraUpdate);
    } finally {
      _isProgrammaticCameraMove = false;
      ref.read(carpoolMapProvider.notifier).setRouteCentered(true);
      widget.onCameraIdle?.call();
    }
  }

  String _fitKeyFor(CarpoolMapState state) {
    final Iterable<String> pointKeys = <String>[
      if (state.driver != null) 'driver',
      if (state.pickup != null)
        'pickup:${state.pickup!.latLng.latitude},${state.pickup!.latLng.longitude}',
      ...state.stops.map(
        (CarpoolMapNamedPoint stop) =>
            'stop:${stop.latLng.latitude},${stop.latLng.longitude}',
      ),
      if (state.dropOff != null)
        'dropoff:${state.dropOff!.latLng.latitude},${state.dropOff!.latLng.longitude}',
    ];
    return '${state.routeSignature}|${pointKeys.join('|')}';
  }

  Polyline? _routePolylineFrom(CarpoolMapState state) {
    for (final Polyline polyline in state.polylines) {
      if (polyline.polylineId == _routePolylineId) {
        return polyline;
      }
    }
    return null;
  }

  Set<Polyline> _animatedPolylines(CarpoolMapState state) {
    final Polyline? routePolyline = _routePolylineFrom(state);

    if (routePolyline == null || routePolyline.points.length < 2) {
      return state.polylines;
    }

    // Calculate how many points to show based on animation progress with easing
    final double easedValue = Curves.easeOut.transform(
      _animationController.value,
    );
    final int totalPoints = routePolyline.points.length;
    final int visiblePointsCount = (totalPoints * easedValue).toInt().clamp(
      2,
      totalPoints,
    );

    // Create animated polyline with partial points
    final List<LatLng> visiblePoints = routePolyline.points.sublist(
      0,
      visiblePointsCount,
    );

    // Replace the route polyline with the animated version
    return <Polyline>{
      ...state.polylines.where(
        (Polyline p) => p.polylineId != _routePolylineId,
      ),
      routePolyline.copyWith(pointsParam: visiblePoints),
    };
  }

  void _startRouteAnimation(CarpoolMapState state) {
    final Polyline? routePolyline = _routePolylineFrom(state);
    if (routePolyline == null || routePolyline.points.length < 2) {
      return;
    }

    final String routeKey = state.routeSignature;
    if (_lastAnimatedRouteKey == routeKey) {
      return;
    }

    _lastAnimatedRouteKey = routeKey;
    _animationController.forward(from: 0.0);
  }

  Future<void> _ensureDriverVisible(LatLng driverPos) async {
    final GoogleMapController? controller = _googleMapController;
    if (controller == null || _isProgrammaticCameraMove) return;

    try {
      final LatLngBounds bounds = await controller.getVisibleRegion();
      final double latSpan =
          (bounds.northeast.latitude - bounds.southwest.latitude).abs();
      final double lngSpan =
          (bounds.northeast.longitude - bounds.southwest.longitude).abs();

      if (latSpan == 0 || lngSpan == 0) return;

      final double minLat = bounds.southwest.latitude + (latSpan * 0.25);
      final double maxLat = bounds.northeast.latitude - (latSpan * 0.10);
      final double minLng = bounds.southwest.longitude + (lngSpan * 0.10);
      final double maxLng = bounds.northeast.longitude - (lngSpan * 0.10);

      final bool isDriverVisible = driverPos.latitude >= minLat &&
          driverPos.latitude <= maxLat &&
          driverPos.longitude >= minLng &&
          driverPos.longitude <= maxLng;

      if (!isDriverVisible) {
        await _animateCamera(CameraUpdate.newLatLng(driverPos));
      }
    } catch (_) {
      // Ignore map controller exceptions
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CarpoolMapState> mapAsync = ref.watch(carpoolMapProvider);
    ref.listen<AsyncValue<CarpoolMapState>>(carpoolMapProvider, (previous, next) {
      final prevState = previous?.asData?.value;
      final nextState = next.asData?.value;
      if (nextState != null && prevState != null) {
        if (nextState.recenterCount != prevState.recenterCount) {
          _fitCameraToVisiblePoints(nextState);
        } else if (nextState.driver?.latLng != null &&
            nextState.driver?.latLng != prevState.driver?.latLng) {
          _ensureDriverVisible(nextState.driver!.latLng);
        }
      }
    });

    ref.listen<CarpoolState>(carpoolProvider, (previous, next) {
      final bool requestStatusChanged =
          previous?.requestStatus != next.requestStatus;
      final bool otpVerifiedBecameTrue =
          previous?.otpVerified != true && next.otpVerified == true;
      if (!requestStatusChanged && !otpVerifiedBecameTrue) return;

      final CarpoolMapState? mapState = ref
          .read(carpoolMapProvider)
          .asData
          ?.value;
      if (mapState == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitCameraToVisiblePoints(mapState);
      });
    });

    final carpoolMapNotifier = ref.read(carpoolMapProvider.notifier);
    final activeRegion = ServiceRegionConfig.active;
    final CameraTargetBounds cameraTargetBounds = activeRegion.isGlobal
        ? CameraTargetBounds.unbounded
        : carpoolMapNotifier.cameraTargetBounds;
    return mapAsync.when(
      data: (CarpoolMapState state) {
        final String fitKey = _fitKeyFor(state);
        if (_googleMapController != null && fitKey != _lastFittedKey) {
          _lastFittedKey = fitKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _fitCameraToVisiblePoints(state);
          });
        }

        // Start animation when map is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _startRouteAnimation(state);
        });

        return GoogleMap(
          style: context.isDark
              ? (state.darkMapStyle.isNotEmpty
                    ? state.darkMapStyle
                    : MapStyles.dark)
              : (state.lightMapStyle.isNotEmpty
                    ? state.lightMapStyle
                    : MapStyles.light),
          initialCameraPosition: state.cameraPosition,
          padding: EdgeInsets.only(bottom: widget.bottomPadding),
          markers: state.markers,
          polylines: _animatedPolylines(state),
          circles: state.circles,
          onMapCreated: (GoogleMapController controller) {
            _googleMapController = controller;
            widget.onMapCreated(controller);
            final String currentFitKey = _fitKeyFor(state);
            _lastFittedKey = currentFitKey;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _fitCameraToVisiblePoints(state);
            });
          },
          onCameraMoveStarted: () {
            if (_isProgrammaticCameraMove) return;
            carpoolMapNotifier.setRouteCentered(false);
            widget.onCameraMoveStarted?.call();
          },
          onCameraMove: (position) {
            if (_isProgrammaticCameraMove) return;
            carpoolMapNotifier.onCameraMove(position);
            widget.onCameraMove?.call(position);
          },
          onCameraIdle: widget.onCameraIdle,
          cameraTargetBounds: cameraTargetBounds,
          myLocationButtonEnabled: false,
          rotateGesturesEnabled: false,
          zoomControlsEnabled: false,
          buildingsEnabled: false,
          mapToolbarEnabled: false,
          indoorViewEnabled: false,
          scrollGesturesEnabled: widget.scrollGesturesEnabled,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) =>
          Center(child: Text(context.l10n.map_load_error(error.toString()))),
    );
  }
}
