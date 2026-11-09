import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';

import '../../shared/location_component/location_models/address_details.dart';
import '../constants/constants_data.dart';
import '../location/service_region.dart';
import '../utils/app_log.dart';
import 'address_search_controller.dart';
import 'places_search_service.dart';
import 'storage_service.dart';

class LocationAddressDetails {
  final String name;
  final String city;

  const LocationAddressDetails({required this.name, required this.city});
}

/// Comprehensive location service for handling permissions and location access.
///
/// Provides methods to:
/// - Check and request location permissions
/// - Get current device location
/// - Stream location updates for real-time tracking
/// - Handle permission denied and service disabled scenarios
class LocationService {
  final StorageService _storage;
  final Dio _dio;

  late final PlacesSearchService placesSearch;

  LocationService(this._storage, {Dio? dio, PlacesObserver? placesObserver})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ) {
    placesSearch = PlacesSearchService(
      application: 'user',
      platform: defaultTargetPlatform.name,
      dio: _dio,
      observer: placesObserver,
      legacySearch: (query, context) async {
        final origin = context.geography['origin'];
        final results = await getPlaceSuggestions(
          query,
          origin: origin is Map
              ? LatLng(
                  origin['latitude'] as double,
                  origin['longitude'] as double,
                )
              : null,
        );
        return results.map((m) {
          final structured = m['structured_formatting'] as Map?;
          return PlaceSuggestion(
            placeId: m['place_id'] as String,
            label: m['description'] as String,
            primaryText: (structured?['main_text'] ?? '') as String,
            secondaryText: (structured?['secondary_text'] ?? '') as String,
          );
        }).toList();
      },
      legacyResolve: (suggestion, context) async {
        final position = await getPlaceDetails(suggestion.placeId);
        if (position == null) return null;
        return ResolvedPlace(
          placeId: suggestion.placeId,
          label: suggestion.label,
          formattedAddress: suggestion.label,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      },
    );
  }

  PlacesContext placesContext({LatLng? origin}) {
    final region = activeRegion;
    final geography = <String, dynamic>{};
    if (origin != null &&
        ResolvedPlace.validCoordinates(origin.latitude, origin.longitude)) {
      geography['origin'] = {
        'latitude': origin.latitude,
        'longitude': origin.longitude,
      };
    }
    if (!region.isGlobal) {
      geography['locationBias'] = {
        'rectangle': {
          'low': {
            'latitude': region.bounds.southwest.latitude,
            'longitude': region.bounds.southwest.longitude,
          },
          'high': {
            'latitude': region.bounds.northeast.latitude,
            'longitude': region.bounds.northeast.longitude,
          },
        },
      };
      if (region.countryCode.isNotEmpty) {
        geography['includedRegionCodes'] = [region.countryCode];
      }
    } else if (geography.containsKey('origin')) {
      geography['locationBias'] = {
        'circle': {'center': geography['origin'], 'radius': 50000.0},
      };
    }
    return PlacesContext(
      enabled: remoteConfigModel.addressSearchV2Enabled,
      apiKey: ApiEndpoints.mapApiKey,
      language: _storage.getLanguageCode ?? 'en',
      region: region.id.name,
      geography: geography,
      accepts: (place) =>
          region.isGlobal ||
          (region.contains(LatLng(place.latitude, place.longitude)) &&
              (region.matchesAdministrativeArea(place.state) ||
                  region.matchesAdministrativeArea(place.stateCode))),
    );
  }

  final Set<AddressSearchController> _addressSearches = {};
  void invalidateAddressSearches() {
    for (final controller in _addressSearches.toList()) {
      controller.abandon();
    }
  }

  AddressSearchController createAddressSearch({
    required void Function() onChanged,
    LatLng? Function()? origin,
    bool legacyDeviceOrigin = true,
    void Function(LatLng)? onLegacyOriginResolved,
    Duration legacyDebounce = const Duration(milliseconds: 300),
  }) {
    late final AddressSearchController controller;
    controller = AddressSearchController(
      service: placesSearch,
      contextProvider: () => placesContext(origin: origin?.call()),
      legacyDebounce: legacyDebounce,
      prepareContext: (context) async {
        if (context.geography.containsKey('origin')) return context;
        if (!context.enabled && !legacyDeviceOrigin) return context;
        // The disabled strategy retains its original fresh-fix-first policy.
        // The enabled strategy snapshots cached origin once per interaction.
        Position? position;
        if (!context.enabled) {
          try {
            position = await getCurrentLocation(
              requestPermissionIfNeeded: false,
            );
          } catch (_) {
            /* Fall back to the cached fix. */
          }
        }
        final last = position ?? await getLastKnownLocation();
        if (last == null) return context;
        if (!context.enabled) {
          onLegacyOriginResolved?.call(LatLng(last.latitude, last.longitude));
        }
        final prepared = placesContext(
          origin: LatLng(last.latitude, last.longitude),
        );
        return PlacesContext(
          enabled: context.enabled,
          apiKey: context.apiKey,
          language: context.language,
          region: context.region,
          geography: prepared.geography,
          accepts: context.accepts,
        );
      },
      onChanged: onChanged,
      onDispose: () => _addressSearches.remove(controller),
    );
    _addressSearches.add(controller);
    return controller;
  }

  /// Check if location permission is granted.
  Future<bool> hasLocationPermission() async {
    final LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission from the user.
  ///
  /// Returns [LocationPermissionResult] indicating the outcome.
  Future<LocationPermissionResult> requestLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('Location services are disabled', name: 'LocationService');
        return LocationPermissionResult.serviceDisabled;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        await _storage.setLocationPermissionGranted(true);
        log('Location permission already granted', name: 'LocationService');
        return LocationPermissionResult.granted;
      }

      if (permission == LocationPermission.deniedForever) {
        log('Location permission permanently denied', name: 'LocationService');
        return LocationPermissionResult.permanentlyDenied;
      }

      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        await _storage.setLocationPermissionGranted(true);
        log('Location permission granted', name: 'LocationService');
        return LocationPermissionResult.granted;
      } else if (permission == LocationPermission.deniedForever) {
        await _storage.setLocationPermissionGranted(false);
        log('Location permission permanently denied', name: 'LocationService');
        return LocationPermissionResult.permanentlyDenied;
      } else {
        await _storage.setLocationPermissionGranted(false);
        log('Location permission denied', name: 'LocationService');
        return LocationPermissionResult.denied;
      }
    } catch (e) {
      log('Error requesting location permission: $e', name: 'LocationService');
      return LocationPermissionResult.error;
    }
  }

  /// Open app settings so user can manually grant location permission.
  Future<bool> openLocationSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      log('Error opening settings: $e', name: 'LocationService');
      return false;
    }
  }

  /// Ensure location service/permission is ready before accessing coordinates.
  Future<LocationPermissionResult> ensureLocationAccess({
    bool requestPermissionIfNeeded = true,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult.serviceDisabled;
      }

      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return LocationPermissionResult.granted;
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionResult.permanentlyDenied;
      }

      if (!requestPermissionIfNeeded) {
        return LocationPermissionResult.denied;
      }

      return requestLocationPermission();
    } catch (e) {
      log('Error ensuring location access: $e', name: 'LocationService');
      return LocationPermissionResult.error;
    }
  }

  /// Get the current device location.
  ///
  /// Returns [Position] with latitude, longitude, accuracy, etc.
  /// Throws [LocationException] if permission is denied or service is disabled.
  Future<Position> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
  }) async {
    try {
      final permissionResult = await ensureLocationAccess(
        requestPermissionIfNeeded: requestPermissionIfNeeded,
      );
      if (permissionResult != LocationPermissionResult.granted) {
        switch (permissionResult) {
          case LocationPermissionResult.permanentlyDenied:
            throw LocationException(
              'Location permission permanently denied. Please enable it from app settings.',
            );
          case LocationPermissionResult.serviceDisabled:
            throw LocationException('Location services are disabled');
          case LocationPermissionResult.denied:
            throw LocationException('Location permission denied');
          case LocationPermissionResult.error:
            throw LocationException('Could not request location permission');
          case LocationPermissionResult.granted:
            break;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      log('Current location obtained', name: 'LocationService');

      return position;
    } catch (e) {
      log('Error getting current location: $e', name: 'LocationService');
      rethrow;
    }
  }

  /// Stream location updates for real-time tracking.
  Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    late final LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              "Ride App is updating your location for your ride.",
          notificationTitle: "Location updates active",
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        activityType: ActivityType.otherNavigation,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Get the last known location (cached).
  Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      log('Error getting last known location: $e', name: 'LocationService');
      return null;
    }
  }

  /// Calculate distance between two coordinates in meters.
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  ServiceRegion get activeRegion => _activeRegion;
  ServiceRegion get _activeRegion => ServiceRegionConfig.active;

  bool isWithinActiveRegion(double latitude, double longitude) {
    return _activeRegion.contains(LatLng(latitude, longitude));
  }

  LatLng clampToActiveRegion(double latitude, double longitude) {
    return _activeRegion.clamp(LatLng(latitude, longitude));
  }

  /// Mark that user has seen the location permission prompt.
  Future<void> markLocationPromptShown() async {
    await _storage.setLocationPromptShown(true);
  }

  /// Check if user has seen the location permission prompt.
  bool hasSeenLocationPrompt() {
    return _storage.hasSeenLocationPrompt;
  }

  bool isLocationPermissionGranted() {
    return _storage.isLocationPermissionGranted;
  }

  /// Get place suggestions from Google Places API (New – Autocomplete).
  ///
  /// Uses the `places:autocomplete` endpoint (not `searchText`) — autocomplete
  /// is designed for partial address completion; searchText is a POI search
  /// and returns zero results for partial address strings like
  /// "11471 sw 103rd st" without a city qualifier.
  ///
  /// When [origin] (typically the user's current location) is provided, results
  /// are soft-biased around it via `locationBias`. When a non-global service
  /// region is active, the region's bounds are used as a rectangle bias so the
  /// whole service area (e.g. all of Florida) is preferred without excluding
  /// distant matches.
  ///
  /// The returned maps are shaped to be **backward-compatible** with the old
  /// legacy Autocomplete API shape that all callers expect:
  /// ```
  /// {
  ///   'place_id':              String,
  ///   'description':           String,   // full formatted address
  ///   'structured_formatting': { 'main_text': ..., 'secondary_text': ... },
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getPlaceSuggestions(
    String query, {
    LatLng? origin,
  }) async {
    final apiKey = ApiEndpoints.mapApiKey;
    if (apiKey.isEmpty) return [];

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'input': query,
        'languageCode': _storage.getLanguageCode ?? 'en',
      };

      // Top-level `origin` gives Google a proximity signal for ranking
      // without excluding distant matches — pairs with the wide rectangle
      // bias below so nearby results still rank first inside the region.
      if (origin != null) {
        body['origin'] = <String, dynamic>{
          'latitude': origin.latitude,
          'longitude': origin.longitude,
        };
      }

      // Prefer a rectangle bias covering the full service area (Places API
      // New caps circle radius at 50 km, which is smaller than most service
      // regions). Fall back to a circle around origin when global.
      if (!_activeRegion.isGlobal) {
        final bounds = _activeRegion.bounds;
        body['locationBias'] = <String, dynamic>{
          'rectangle': <String, dynamic>{
            'low': <String, dynamic>{
              'latitude': bounds.southwest.latitude,
              'longitude': bounds.southwest.longitude,
            },
            'high': <String, dynamic>{
              'latitude': bounds.northeast.latitude,
              'longitude': bounds.northeast.longitude,
            },
          },
        };
        if (_activeRegion.countryCode.isNotEmpty) {
          body['includedRegionCodes'] = <String>[_activeRegion.countryCode];
        }
      } else if (origin != null) {
        body['locationBias'] = <String, dynamic>{
          'circle': <String, dynamic>{
            'center': <String, dynamic>{
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            },
            'radius': 50000.0,
          },
        };
      }

      final dio = Dio();
      final response = await dio.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: body,
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
          },
        ),
      );

      final List<dynamic> suggestions =
          (response.data['suggestions'] as List<dynamic>?) ?? <dynamic>[];
      if (suggestions.isEmpty) return [];

      final List<Map<String, dynamic>> mapped = suggestions
          .map((dynamic raw) {
            final Map<String, dynamic> s = raw is Map<String, dynamic>
                ? raw
                : Map<String, dynamic>.from(raw as Map);
            final dynamic predictionRaw = s['placePrediction'];
            if (predictionRaw is! Map) return const <String, dynamic>{};
            final Map<String, dynamic> prediction =
                predictionRaw is Map<String, dynamic>
                ? predictionRaw
                : Map<String, dynamic>.from(predictionRaw);

            final String placeId = (prediction['placeId'] ?? '').toString();

            String extractText(dynamic node) {
              if (node is Map) {
                final dynamic t = node['text'];
                if (t != null) return t.toString();
              }
              return '';
            }

            final String description = extractText(prediction['text']);

            String mainText = '';
            String secondaryText = '';
            final dynamic structured = prediction['structuredFormat'];
            if (structured is Map) {
              mainText = extractText(structured['mainText']);
              secondaryText = extractText(structured['secondaryText']);
            }

            return <String, dynamic>{
              'place_id': placeId,
              'description': description,
              'structured_formatting': <String, dynamic>{
                'main_text': mainText,
                'secondary_text': secondaryText,
              },
            };
          })
          .where((m) => (m['place_id'] ?? '').toString().isNotEmpty)
          .toList();

      final List<Map<String, dynamic>> filtered = mapped
          .where(_predictionMatchesActiveRegion)
          .toList(growable: true);
      return List<Map<String, dynamic>>.unmodifiable(filtered);
    } catch (e) {
      log('Unable to get place suggestions', name: 'LocationService');
      return [];
    }
  }

  /// Get formatted address from coordinates using Google Geocoding API.
  Future<Map<String, dynamic>?> getAddressFromCoordinates(
    double lat,
    double lng, {
    required String reason,
  }) async {
    final apiKey = ApiEndpoints.mapApiKey;
    if (apiKey.isEmpty) return null;

    final watch = Stopwatch()..start();
    var status = 'success';
    placesSearch.observe({
      'event': 'request_started',
      'method': 'reverse_geocode',
      'field': 'location.lookup',
      'reason': reason,
    });
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': apiKey,
          'language': _storage.getLanguageCode,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        status = 'malformed';
        return null;
      }
      status = switch (data['status']) {
        'OK' => 'success',
        'ZERO_RESULTS' => 'incomplete',
        'OVER_QUERY_LIMIT' => 'quota',
        'REQUEST_DENIED' || 'INVALID_REQUEST' => 'configuration',
        'UNKNOWN_ERROR' => 'network',
        _ => 'malformed',
      };
      if (status == 'success') {
        if (data['results'] is! List) {
          status = 'malformed';
        } else if ((data['results'] as List).isEmpty) {
          status = 'incomplete';
        }
      }
      return status == 'success' ? data : null;
    } on DioException catch (error) {
      status = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => 'timeout',
        DioExceptionType.cancel => 'cancelled',
        _ => switch (error.response?.statusCode) {
          429 => 'quota',
          400 || 401 || 403 => 'configuration',
          _ => 'network',
        },
      };
      return null;
    } catch (_) {
      status = 'malformed';
      return null;
    } finally {
      placesSearch.observe({
        'event': 'request_finished',
        'method': 'reverse_geocode',
        'field': 'location.lookup',
        'reason': reason,
        'status': status,
        'elapsed_ms': watch.elapsedMilliseconds,
      });
    }
  }

  /// Resolves both a user-friendly place name and city from coordinates in a single request.
  Future<LocationAddressDetails> getLocationDetailsFromCoordinates(
    double lat,
    double lng, {
    String fallback = 'Unknown location',
    required String reason,
  }) async {
    final response = await getAddressFromCoordinates(lat, lng, reason: reason);
    if (response == null) {
      return LocationAddressDetails(name: fallback, city: '');
    }

    try {
      final List<dynamic> results =
          (response['results'] as List<dynamic>? ?? []);
      if (results.isEmpty) {
        return LocationAddressDetails(name: fallback, city: '');
      }

      final Map<String, dynamic> first = results.first is Map<String, dynamic>
          ? results.first as Map<String, dynamic>
          : Map<String, dynamic>.from(results.first as Map);

      final String formatted = (first['formatted_address'] ?? '').toString();
      final String name = formatted.isNotEmpty ? formatted : fallback;

      String city = '';
      final components = first['address_components'];
      if (components is List) {
        for (var component in components) {
          if (component is! Map) continue;
          final Map<String, dynamic> componentMap =
              component is Map<String, dynamic>
              ? component
              : Map<String, dynamic>.from(component);
          final types = componentMap['types'];
          if (types is List &&
              (types.contains('locality') ||
                  types.contains('administrative_area_level_2'))) {
            city = (componentMap['long_name'] ?? '').toString();
            break;
          }
        }
      }

      return LocationAddressDetails(name: name, city: city);
    } catch (e) {
      log('Unable to parse location details', name: 'LocationService');
      return LocationAddressDetails(name: fallback, city: '');
    }
  }

  /// Resolve a short, user-friendly place name from coordinates.
  Future<String> getPlaceNameFromCoordinates(
    double lat,
    double lng, {
    String fallback = 'Unknown location',
    required String reason,
  }) async {
    final details = await getLocationDetailsFromCoordinates(
      lat,
      lng,
      fallback: fallback,
      reason: reason,
    );
    return details.name;
  }

  Future<String> getCityFromCoordinates(
    double lat,
    double lng, {
    required String reason,
  }) async {
    final details = await getLocationDetailsFromCoordinates(
      lat,
      lng,
      reason: reason,
    );
    return details.city;
  }

  /// Get place details (LatLng) from Place ID.
  ///
  /// We intentionally *do not* drop results that fall just outside the
  /// configured service region, because Google occasionally returns
  /// coordinates that sit on the edge of the bounding box (e.g. points near
  /// Florida borders). Downstream callers can still clamp/validate if needed.
  Future<Position?> getPlaceDetails(String placeId) async {
    final apiKey = ApiEndpoints.mapApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': apiKey,
          'fields': 'geometry,address_component,formatted_address',
        },
      );

      if (response.data['status'] != 'OK') return null;

      final Map<String, dynamic> result =
          response.data['result'] is Map<String, dynamic>
          ? response.data['result'] as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data['result'] as Map);

      final dynamic geometry = result['geometry'];
      final Map<String, dynamic>? geometryMap = geometry is Map<String, dynamic>
          ? geometry
          : (geometry is Map ? Map<String, dynamic>.from(geometry) : null);
      final dynamic rawLocation = geometryMap?['location'];
      final Map<String, dynamic>? locationMap =
          rawLocation is Map<String, dynamic>
          ? rawLocation
          : (rawLocation is Map
                ? Map<String, dynamic>.from(rawLocation)
                : null);
      if (locationMap == null) return null;

      // We still log if it is outside the active region, but return the position.
      final double lat = (locationMap['lat'] as num).toDouble();
      final double lng = (locationMap['lng'] as num).toDouble();
      if (!_placeResultMatchesActiveRegion(result)) {
        log(
          'Place outside active region, returning coordinates',
          name: 'LocationService',
        );
      }

      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } catch (e) {
      log('Unable to get place details', name: 'LocationService');
      return null;
    }
  }

  /// Get address details (city, state, country, lat, lng) from Place ID.
  Future<AddressDetails?> getAddressDetailsFromPlaceId(String placeId) async {
    final apiKey = ApiEndpoints.mapApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': apiKey,
          'fields': 'geometry,address_components,formatted_address',
        },
      );

      if (response.data['status'] != 'OK') return null;

      final Map<String, dynamic> result =
          response.data['result'] is Map<String, dynamic>
          ? response.data['result'] as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data['result'] as Map);

      final dynamic geometry = result['geometry'];
      final Map<String, dynamic>? geometryMap = geometry is Map<String, dynamic>
          ? geometry
          : (geometry is Map ? Map<String, dynamic>.from(geometry) : null);
      final dynamic rawLocation = geometryMap?['location'];
      final Map<String, dynamic>? locationMap =
          rawLocation is Map<String, dynamic>
          ? rawLocation
          : (rawLocation is Map
                ? Map<String, dynamic>.from(rawLocation)
                : null);

      final double lat = (locationMap?['lat'] as num?)?.toDouble() ?? 0.0;
      final double lng = (locationMap?['lng'] as num?)?.toDouble() ?? 0.0;

      String city = '';
      String state = '';
      String country = '';
      String zipCode = '';

      final List<dynamic> components =
          result['address_components'] as List<dynamic>? ?? const <dynamic>[];

      for (final dynamic raw in components) {
        final Map<String, dynamic> component = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);
        final List<dynamic> types = component['types'] as List<dynamic>? ?? [];

        if (types.contains('locality')) {
          city = (component['long_name'] ?? '').toString();
        } else if (city.isEmpty &&
            (types.contains('sublocality_level_1') ||
                types.contains('sublocality') ||
                types.contains('administrative_area_level_2'))) {
          city = (component['long_name'] ?? '').toString();
        }

        if (types.contains('administrative_area_level_1')) {
          state = (component['long_name'] ?? '').toString();
        }

        if (types.contains('country')) {
          country = (component['long_name'] ?? '').toString();
        }

        if (types.contains('postal_code')) {
          zipCode = (component['long_name'] ?? '').toString();
        }
      }

      // If city or state is empty, attempt fallback via reverse geocoding
      if ((city.isEmpty || state.isEmpty) && (lat != 0.0 || lng != 0.0)) {
        final geoData = await getAddressFromCoordinates(
          lat,
          lng,
          reason: 'legacy_components_fallback',
        );
        if (geoData != null && (geoData['results'] as List).isNotEmpty) {
          final firstResult = geoData['results'][0];
          final List<dynamic> geoComponents =
              firstResult['address_components'] as List<dynamic>? ??
              const <dynamic>[];
          for (final dynamic raw in geoComponents) {
            final Map<String, dynamic> component = raw is Map<String, dynamic>
                ? raw
                : Map<String, dynamic>.from(raw as Map);
            final List<dynamic> types =
                component['types'] as List<dynamic>? ?? [];
            if (city.isEmpty && types.contains('locality')) {
              city = (component['long_name'] ?? '').toString();
            } else if (city.isEmpty &&
                (types.contains('sublocality_level_1') ||
                    types.contains('sublocality') ||
                    types.contains('administrative_area_level_2'))) {
              city = (component['long_name'] ?? '').toString();
            }

            if (state.isEmpty &&
                types.contains('administrative_area_level_1')) {
              state = (component['long_name'] ?? '').toString();
            }

            if (country.isEmpty && types.contains('country')) {
              country = (component['long_name'] ?? '').toString();
            }

            if (zipCode.isEmpty && types.contains('postal_code')) {
              zipCode = (component['long_name'] ?? '').toString();
            }
          }
        }
      }

      return AddressDetails(
        latitude: lat,
        longitude: lng,
        city: city,
        state: state,
        country: country,
        zipCode: zipCode,
      );
    } catch (e) {
      log('Unable to get address details', name: 'LocationService');
      return null;
    }
  }

  bool _predictionMatchesActiveRegion(Map<String, dynamic> prediction) {
    if (activeRegion.isGlobal) {
      return true;
    }
    final dynamic structured = prediction['structured_formatting'];
    final Map<String, dynamic> structuredMap =
        structured is Map<String, dynamic> ? structured : <String, dynamic>{};
    final String secondaryText = (structuredMap['secondary_text'] ?? '')
        .toString()
        .toLowerCase();
    final String description = (prediction['description'] ?? '')
        .toString()
        .toLowerCase();

    return _activeRegion.administrativeAreaMatches.any(
      (match) => secondaryText.contains(match) || description.contains(match),
    );
  }

  bool _placeResultMatchesActiveRegion(Map<String, dynamic> result) {
    final dynamic geometry = result['geometry'];
    final Map<String, dynamic>? geometryMap = geometry is Map<String, dynamic>
        ? geometry
        : (geometry is Map ? Map<String, dynamic>.from(geometry) : null);
    final dynamic rawLocation = geometryMap?['location'];
    final Map<String, dynamic>? locationMap =
        rawLocation is Map<String, dynamic>
        ? rawLocation
        : (rawLocation is Map ? Map<String, dynamic>.from(rawLocation) : null);
    if (locationMap == null) return false;

    final double? latitude = (locationMap['lat'] as num?)?.toDouble();
    final double? longitude = (locationMap['lng'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return false;
    if (!isWithinActiveRegion(latitude, longitude)) return false;

    final List<dynamic> components =
        result['address_components'] as List<dynamic>? ?? const <dynamic>[];
    for (final dynamic raw in components) {
      final Map<String, dynamic> component = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);
      final List<dynamic> types = component['types'] as List<dynamic>? ?? [];
      if (types.contains('administrative_area_level_1')) {
        final String? longName = component['long_name']?.toString();
        final String? shortName = component['short_name']?.toString();
        return _activeRegion.matchesAdministrativeArea(longName) ||
            _activeRegion.matchesAdministrativeArea(shortName);
      }
    }

    final String formatted = (result['formatted_address'] ?? '').toString();
    return _activeRegion.administrativeAreaMatches.any(
      (match) => formatted.toLowerCase().contains(match),
    );
  }
}

enum LocationPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
  error,
}

class LocationException implements Exception {
  final String message;

  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
