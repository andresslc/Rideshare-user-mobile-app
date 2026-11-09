import 'package:google_maps_flutter/google_maps_flutter.dart';

class CarpoolMapNamedPoint {
  final LatLng latLng;
  final String name;

  const CarpoolMapNamedPoint({
    required this.latLng,
    required this.name,
  });
}

class CarpoolMapState {
  final String lightMapStyle;
  final String darkMapStyle;
  final CameraPosition cameraPosition;
  final CarpoolMapNamedPoint currentLocation;
  final String? errorMessage;
  final CarpoolMapNamedPoint? pickup;
  final CarpoolMapNamedPoint? dropOff;
  final CarpoolMapNamedPoint? driver;
  final List<CarpoolMapNamedPoint> stops;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Circle> circles;
  final String routeSignature;
  final int recenterCount;
  final bool isRouteCentered;

  const CarpoolMapState({
    required this.lightMapStyle,
    required this.darkMapStyle,
    required this.cameraPosition,
    required this.currentLocation,
    this.errorMessage,
    this.pickup,
    this.dropOff,
    this.driver,
    this.stops = const <CarpoolMapNamedPoint>[],
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.circles = const <Circle>{},
    this.routeSignature = '',
    this.recenterCount = 0,
    this.isRouteCentered = true,
  });

  CarpoolMapState copyWith({
    String? lightMapStyle,
    String? darkMapStyle,
    CameraPosition? cameraPosition,
    CarpoolMapNamedPoint? currentLocation,
    String? errorMessage,
    bool clearError = false,
    CarpoolMapNamedPoint? pickup,
    CarpoolMapNamedPoint? dropOff,
    CarpoolMapNamedPoint? driver,
    bool clearPickup = false,
    bool clearDropOff = false,
    bool clearDriver = false,
    List<CarpoolMapNamedPoint>? stops,
    bool clearStops = false,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    Set<Circle>? circles,
    String? routeSignature,
    int? recenterCount,
    bool? isRouteCentered,
  }) {
    return CarpoolMapState(
      lightMapStyle: lightMapStyle ?? this.lightMapStyle,
      darkMapStyle: darkMapStyle ?? this.darkMapStyle,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      currentLocation: currentLocation ?? this.currentLocation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pickup: clearPickup ? null : (pickup ?? this.pickup),
      dropOff: clearDropOff ? null : (dropOff ?? this.dropOff),
      driver: clearDriver ? null : (driver ?? this.driver),
      stops: clearStops ? const <CarpoolMapNamedPoint>[] : (stops ?? this.stops),
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      circles: circles ?? this.circles,
      routeSignature: routeSignature ?? this.routeSignature,
      recenterCount: recenterCount ?? this.recenterCount,
      isRouteCentered: isRouteCentered ?? this.isRouteCentered,
    );
  }
}
