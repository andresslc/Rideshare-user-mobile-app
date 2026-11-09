import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'route_deviation_detector.dart';

class LiveRouteManager {
  final String apiKey;
  final double deviationThresholdMeters;

  final StreamController<List<LatLng>> _routeStreamController =
      StreamController<List<LatLng>>.broadcast();

  Timer? _timer;
  bool _isRerouting = false;
  LatLng? _destination;
  final RouteDeviationDetector _deviationDetector;
  final PolylinePoints _polylinePoints = PolylinePoints();
  List<LatLng> _currentRoutePoints = [];

  LiveRouteManager({
    required this.apiKey,
    double? deviationThresholdMeters,
  })  : deviationThresholdMeters = deviationThresholdMeters ?? 300.0,
        _deviationDetector = RouteDeviationDetector(
          deviationThresholdMeters: deviationThresholdMeters ?? 300.0,
        );

  Stream<List<LatLng>> get routeStream => _routeStreamController.stream;

  Future<void> startTracking({
    required LatLng origin,
    required LatLng destination,
  }) async {
    _destination = destination;
    _timer?.cancel();

    // Fetch initial route
    await _fetchAndEmitRoute(origin, destination);

    // Start timer every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkDeviationAndReroute());
  }

  Future<void> _checkDeviationAndReroute() async {
    if (_isRerouting || _destination == null || _currentRoutePoints.isEmpty) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);

      final deviated = _deviationDetector.hasDeviated(currentLatLng, _currentRoutePoints);
      if (deviated) {
        debugPrint('Deviation detected. Rerouting...');
        await _fetchAndEmitRoute(currentLatLng, _destination!);
      }
    } catch (e) {
      debugPrint('Error getting location or checking deviation: $e');
    }
  }

  Future<void> _fetchAndEmitRoute(LatLng origin, LatLng destination) async {
    if (_isRerouting) return;
    _isRerouting = true;

    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: apiKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        final newPoints = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        _currentRoutePoints = newPoints;
        _routeStreamController.add(newPoints);
      } else {
        debugPrint('Route fetch returned no points: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    } finally {
      _isRerouting = false;
    }
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _routeStreamController.close();
  }
}
