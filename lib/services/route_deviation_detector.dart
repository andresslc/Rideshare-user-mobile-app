import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteDeviationDetector {
  final double deviationThresholdMeters;

  RouteDeviationDetector({this.deviationThresholdMeters = 50.0}); // 500M

  /// Calculates the perpendicular (shortest) distance from the driver's current
  /// position to each segment of the route polyline using the Haversine formula.
  /// Returns true if the minimum distance to any segment exceeds the threshold.
  bool hasDeviated(LatLng currentPosition, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return false;
    if (routePoints.length < 2) {
      final double distance = _haversineDistance(
        currentPosition,
        routePoints.first,
      );
      return distance > deviationThresholdMeters;
    }

    double minDistance = double.infinity;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final LatLng a = routePoints[i];
      final LatLng b = routePoints[i + 1];

      final LatLng snapped = _projectPointOnSegment(currentPosition, a, b);
      final double distance = _haversineDistance(currentPosition, snapped);

      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance > deviationThresholdMeters;
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

  double _haversineDistance(LatLng p1, LatLng p2) {
    const double R = 6371000; // Earth's radius in meters
    final double lat1 = p1.latitude * math.pi / 180;
    final double lat2 = p2.latitude * math.pi / 180;
    final double lon1 = p1.longitude * math.pi / 180;
    final double lon2 = p2.longitude * math.pi / 180;

    final double dlat = lat2 - lat1;
    final double dlon = lon2 - lon1;

    final double a =
        math.sin(dlat / 2) * math.sin(dlat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dlon / 2) *
            math.sin(dlon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}
