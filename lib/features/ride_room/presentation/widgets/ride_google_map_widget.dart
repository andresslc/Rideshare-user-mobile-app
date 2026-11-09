import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/core/theme/map_styles.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/map_state.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';

import '../../../../core/location/service_region.dart';
import '../../enums/ride_enum.dart';
import '../providers/ride_room_provider.dart';

class RideGoogleMapWidget extends ConsumerStatefulWidget {
  const RideGoogleMapWidget({
    super.key,
    required this.scrollGesturesEnabled,
    required this.onMapCreated,
    required this.onCameraMoveStarted,
    required this.onCameraIdle,
    this.onCameraMove,
  });

  final bool scrollGesturesEnabled;
  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback onCameraMoveStarted;
  final VoidCallback onCameraIdle;
  final void Function(CameraPosition)? onCameraMove;

  @override
  ConsumerState<RideGoogleMapWidget> createState() =>
      _RideGoogleMapWidgetState();
}

class _RideGoogleMapWidgetState extends ConsumerState<RideGoogleMapWidget>
    with SingleTickerProviderStateMixin {
  static const PolylineId _routePolylineId = PolylineId(
    'pickup_dropoff_polyline',
  );
  static const Duration _routeAnimationDuration = Duration(milliseconds: 3000);
  static const double _routeBoundsPadding = 160;

  late final AnimationController _animationController;
  GoogleMapController? _googleMapController;
  String _lastAnimatedRouteKey = '';
  String _lastFittedRouteKey = '';
  bool _isProgrammaticCameraMove = false;
  bool _didFitRouteForActiveRide = false;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: _routeAnimationDuration, vsync: this)
          ..addListener(() {
            if (mounted) {
              setState(() {});
            }
          });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Polyline? _routePolylineFrom(MapState state) {
    for (final Polyline polyline in state.polylines) {
      if (polyline.polylineId == _routePolylineId) {
        return polyline;
      }
    }
    return null;
  }

  String _routeKeyFor(MapState state) {
    if (state.pickup == null || state.dropOff == null) {
      return '';
    }

    final String pickupKey =
        '${state.pickup!.latLng.latitude},${state.pickup!.latLng.longitude}';
    final String dropOffKey =
        '${state.dropOff!.latLng.latitude},${state.dropOff!.latLng.longitude}';
    return '$pickupKey->$dropOffKey';
  }

  Set<Polyline> _animatedPolylines(MapState state) {
    final Polyline? routePolyline = _routePolylineFrom(state);
    if (routePolyline == null || routePolyline.points.length < 2) {
      return state.polylines;
    }

    final double easedValue = Curves.easeOut.transform(
      _animationController.value,
    );
    final int totalPoints = routePolyline.points.length;
    final int visiblePointsCount = (totalPoints * easedValue).toInt().clamp(
      2,
      totalPoints,
    );
    final List<LatLng> visiblePoints = routePolyline.points.sublist(
      0,
      visiblePointsCount,
    );

    return <Polyline>{
      ...state.polylines.where(
        (Polyline polyline) => polyline.polylineId != _routePolylineId,
      ),
      routePolyline.copyWith(pointsParam: visiblePoints),
    };
  }

  void _startRouteAnimation(MapState state) {
    final Polyline? routePolyline = _routePolylineFrom(state);
    if (routePolyline == null || routePolyline.points.length < 2) {
      _lastAnimatedRouteKey = '';
      _animationController.stop();
      return;
    }

    final String routeKey = _routeKeyFor(state);
    if (routeKey.isEmpty) {
      _lastAnimatedRouteKey = '';
      _animationController.stop();
      return;
    }
    if (_lastAnimatedRouteKey == routeKey) {
      return;
    }

    _lastAnimatedRouteKey = routeKey;
    _animationController.forward(from: 0.0);
  }

  String _fitKeyFor(MapState state) {
    final Polyline? routePolyline = _routePolylineFrom(state);
    if (routePolyline == null || routePolyline.points.length < 2) {
      return '';
    }

    final LatLng first = routePolyline.points.first;
    final LatLng last = routePolyline.points.last;
    return [
      '${state.pickup?.latLng.latitude},${state.pickup?.latLng.longitude}',
      '${state.dropOff?.latLng.latitude},${state.dropOff?.latLng.longitude}',
      '${routePolyline.points.length}',
      '${first.latitude},${first.longitude}',
      '${last.latitude},${last.longitude}',
    ].join('|');
  }

  Future<void> _fitCameraToRoute(MapState state, {bool force = false}) async {
    final GoogleMapController? controller = _googleMapController;
    if (controller == null) return;

    if (force) {
      _didFitRouteForActiveRide = false;
    }

    if (state.driver != null) {
      if (_didFitRouteForActiveRide) {
        return;
      }
      _didFitRouteForActiveRide = true;
    } else {
      _didFitRouteForActiveRide = false;
    }

    final mapNotifier = ref.read(mapProvider.notifier);
    final LatLngBounds? bounds = mapNotifier.routeCameraBounds(state);
    if (bounds == null) return;

    final Polyline? routePolyline = _routePolylineFrom(state);
    if (routePolyline == null || routePolyline.points.isEmpty) return;

    _isProgrammaticCameraMove = true;
    try {
      if (routePolyline.points.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(routePolyline.points.first, 15),
        );
      } else {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, _routeBoundsPadding),
        );
        await Future.delayed(const Duration(milliseconds: 400));
        await controller.animateCamera(
          CameraUpdate.scrollBy(
            0,
            140, // 👈 adjust this (100–300 works depending on screen)
          ),
        );
      }
    } catch (_) {
      // If the map is not ready for bounds yet, keep the current view.
    } finally {
      _isProgrammaticCameraMove = false;
      mapNotifier.setRouteCentered(true);
    }
  }

  // String _mapKeyFor(MapState state) {
  //   final String routeKey = _routeKeyFor(state);
  //   final String rideType = state.selectedRideType ?? '';
  //   return 'ride-map:$routeKey:$rideType';
  // }

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
        _isProgrammaticCameraMove = true;
        try {
          await controller.animateCamera(CameraUpdate.newLatLng(driverPos));
          if (mounted) {
            ref.read(mapProvider.notifier).setRouteCentered(true);
          }
        } finally {
          _isProgrammaticCameraMove = false;
        }
      }
    } catch (_) {
      // Ignore map controller exceptions during dispose/re-render
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<MapState> mapAsync = ref.watch(mapProvider);
    ref.listen<AsyncValue<MapState>>(mapProvider, (previous, next) {
      final prevState = previous?.asData?.value;
      final nextState = next.asData?.value;
      if (nextState != null && prevState != null) {
        if (nextState.recenterCount != prevState.recenterCount) {
          _fitCameraToRoute(nextState, force: true);
        } else if (nextState.driver?.latLng != null &&
            nextState.driver?.latLng != prevState.driver?.latLng) {
          _ensureDriverVisible(nextState.driver!.latLng);
        }
      }
    });

    ref.listen<RideRoomState>(rideRoomProvider, (previous, next) {
      final bool rideStatusChanged =
          previous?.currentRideType != next.currentRideType;
      if (!rideStatusChanged) return;

      _didFitRouteForActiveRide = false;
      final MapState? mapState = ref.read(mapProvider).asData?.value;
      if (mapState == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitCameraToRoute(mapState);
      });
    });

    final mapNotifier = ref.read(mapProvider.notifier);
    final activeRegion = ServiceRegionConfig.active;
    final CameraTargetBounds cameraTargetBounds = activeRegion.isGlobal
        ? CameraTargetBounds.unbounded
        : mapNotifier.cameraTargetBounds;
    return mapAsync.when(
      data: (MapState state) {
        final String fitKey = _fitKeyFor(state);
        if (_googleMapController != null &&
            fitKey.isNotEmpty &&
            fitKey != _lastFittedRouteKey) {
          _lastFittedRouteKey = fitKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _fitCameraToRoute(state);
          });
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _startRouteAnimation(state);
        });

        final rideRoomState = ref.watch(rideRoomProvider);
        final bool hidePickupMarker =
            rideRoomState.currentSheet == RideSheetsType.whereToGoSheet &&
            state.dropOff == null;
        final Set<Marker> visibleMarkers = hidePickupMarker
            ? state.markers
                .where((m) => !m.markerId.value.startsWith('pickup_'))
                .toSet()
            : state.markers;

        return RepaintBoundary(
          child: GoogleMap(
            style: context.isDark
                ? (state.darkMapStyle.isNotEmpty
                    ? state.darkMapStyle
                    : MapStyles.dark)
                : (state.lightMapStyle.isNotEmpty
                    ? state.lightMapStyle
                    : MapStyles.light),
            // initialCameraPosition: CameraPosition(
            //   target: activeRegion.clamp(LatLng(28.5384, -81.3789)),
            //   zoom: 15,
            // ),
            initialCameraPosition: state.cameraPosition,
            markers: visibleMarkers,
            polylines: _animatedPolylines(state),
            circles: state.circles,
            onMapCreated: (GoogleMapController controller) {
              _googleMapController = controller;
              widget.onMapCreated(controller);
              final String currentFitKey = _fitKeyFor(state);
              if (currentFitKey.isNotEmpty) {
                _lastFittedRouteKey = currentFitKey;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _fitCameraToRoute(state);
                });
              }
            },
            onCameraMoveStarted: () {
              if (_isProgrammaticCameraMove) return;
              mapNotifier.setRouteCentered(false);
              widget.onCameraMoveStarted();
            },
            onCameraMove: (position) {
              if (_isProgrammaticCameraMove) return;
              mapNotifier.onCameraMove(position);
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) =>
          Center(child: Text(context.l10n.map_load_error(error.toString()))),
    );
  }
}
