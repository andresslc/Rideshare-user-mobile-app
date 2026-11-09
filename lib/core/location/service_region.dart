import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/config/app_config.dart';
import 'package:ride_app/core/di/service_locator.dart';

enum ServiceRegionId { global, florida }

class ServiceRegion {
  final ServiceRegionId id;
  final String displayName;
  final String countryCode;
  final LatLngBounds bounds;
  final LatLng center;
  final double autocompleteRadiusMeters;
  final Set<String> administrativeAreaMatches;

  const ServiceRegion({
    required this.id,
    required this.displayName,
    required this.countryCode,
    required this.bounds,
    required this.center,
    required this.autocompleteRadiusMeters,
    required this.administrativeAreaMatches,
  });

  bool get isGlobal => id == ServiceRegionId.global;
  bool contains(LatLng latLng) {
    if (isGlobal) {
      return true;
    }
    return latLng.latitude >= bounds.southwest.latitude &&
        latLng.latitude <= bounds.northeast.latitude &&
        latLng.longitude >= bounds.southwest.longitude &&
        latLng.longitude <= bounds.northeast.longitude;
  }

  LatLng clamp(LatLng latLng) {
    if (isGlobal) {
      return latLng;
    }
    final double latitude = latLng.latitude.clamp(
      bounds.southwest.latitude,
      bounds.northeast.latitude,
    );
    final double longitude = latLng.longitude.clamp(
      bounds.southwest.longitude,
      bounds.northeast.longitude,
    );
    return LatLng(latitude, longitude);
  }

  bool matchesAdministrativeArea(String? value) {
    if (isGlobal) return true;
    if (value == null) return false;
    final String normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return administrativeAreaMatches.contains(normalized);
  }
}

class ServiceRegionConfig {
  static bool get _isStagingOrDev {
    if (locator.isRegistered<AppConfig>()) {
      return locator<AppConfig>().isDevOrStaging;
    }
    return kDebugMode;
  }

  static final ServiceRegion global = ServiceRegion(
    id: ServiceRegionId.global,
    displayName: 'Global',
    countryCode: '',
    bounds: LatLngBounds(
      southwest: const LatLng(-85.0, -180.0),
      northeast: const LatLng(85.0, 180.0),
    ),
    center: const LatLng(0, 0),
    autocompleteRadiusMeters: 0,
    administrativeAreaMatches: const <String>{},
  );

  static final ServiceRegion florida = ServiceRegion(
    id: ServiceRegionId.florida,
    displayName: 'Florida',
    countryCode: 'us',
    bounds: LatLngBounds(
      southwest: const LatLng(24.396308, -87.634938),
      northeast: const LatLng(31.000968, -79.974307),
    ),
    center: const LatLng(27.6648, -81.5158),
    autocompleteRadiusMeters: 50000,
    administrativeAreaMatches: <String>{'florida', 'fl'},
  );

  static final Map<ServiceRegionId, ServiceRegion> regions =
      <ServiceRegionId, ServiceRegion>{
        ServiceRegionId.global: global,
        ServiceRegionId.florida: florida,
      };

  static ServiceRegion _active = (kDebugMode || _isStagingOrDev)
      ? global
      : florida;

  static ServiceRegion get active => _active;

  static set active(ServiceRegion region) {
    _active = region;
  }

  static ServiceRegionId? parseId(String? raw) {
    if (kDebugMode || _isStagingOrDev) {
      return ServiceRegionId.global;
    }
    final String normalized = raw?.trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'global':
      case 'world':
      case 'all':
        return ServiceRegionId.global;
      case 'florida':
      case 'fl':
        return ServiceRegionId.florida;
      default:
        return null;
    }
  }

  static void setActiveById(ServiceRegionId id) {
    _active =
        regions[id] ?? ((kDebugMode || _isStagingOrDev) ? global : florida);
  }

  static void setActiveByKey(String? raw) {
    final ServiceRegionId? id = parseId(raw);
    if (id == null) return;
    setActiveById(id);
  }
}
