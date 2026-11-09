import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

typedef PlacesObserver = void Function(Map<String, Object> event);

enum PlacesFailure {
  cancelled,
  network,
  timeout,
  configuration,
  quota,
  malformed,
  incomplete,
  outsideRegion,
}

extension PlacesFailureGuidance on PlacesFailure {
  bool get retryable =>
      this == PlacesFailure.timeout || this == PlacesFailure.network;

  String get messageKey => switch (this) {
    PlacesFailure.outsideRegion => 'address_search_outside_region',
    PlacesFailure.configuration ||
    PlacesFailure.quota => 'address_search_unavailable',
    PlacesFailure.malformed ||
    PlacesFailure.incomplete => 'address_search_incomplete',
    _ => 'address_search_failed',
  };
}

class PlacesException implements Exception {
  final PlacesFailure category;
  const PlacesException(this.category);
  @override
  String toString() => 'PlacesException(${category.name})';
}

String newPlacesId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class PlaceSuggestion {
  final String placeId;
  final String label;
  final String primaryText;
  final String secondaryText;
  final int? distanceMeters;
  const PlaceSuggestion({
    required this.placeId,
    required this.label,
    this.primaryText = '',
    this.secondaryText = '',
    this.distanceMeters,
  });

  Map<String, dynamic> toUiMap() => {
    'place_id': placeId,
    'description': label,
    'structured_formatting': {
      'main_text': primaryText,
      'secondary_text': secondaryText,
    },
    'prediction': this,
  };

  static PlaceSuggestion? fromPrediction(dynamic raw) {
    if (raw is! Map) return null;
    String text(dynamic node) =>
        node is Map && node['text'] is String ? node['text'] as String : '';
    final id = raw['placeId'];
    final label = text(raw['text']);
    if (id is! String || id.isEmpty || label.isEmpty) return null;
    final structured = raw['structuredFormat'];
    return PlaceSuggestion(
      placeId: id,
      label: label,
      primaryText: structured is Map ? text(structured['mainText']) : '',
      secondaryText: structured is Map ? text(structured['secondaryText']) : '',
      distanceMeters: raw['distanceMeters'] is num
          ? (raw['distanceMeters'] as num).toInt()
          : null,
    );
  }
}

class ResolvedPlace {
  final String placeId,
      label,
      formattedAddress,
      street,
      city,
      state,
      stateCode,
      country,
      countryCode,
      postalCode;
  final double latitude, longitude;
  const ResolvedPlace({
    required this.placeId,
    required this.label,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.street = '',
    this.city = '',
    this.state = '',
    this.stateCode = '',
    this.country = '',
    this.countryCode = '',
    this.postalCode = '',
  });

  static bool validCoordinates(double lat, double lng) =>
      lat.isFinite &&
      lng.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180;

  factory ResolvedPlace.fromNew(dynamic raw, PlaceSuggestion suggestion) {
    if (raw is! Map) throw const PlacesException(PlacesFailure.malformed);
    final location = raw['location'];
    if (location is! Map ||
        location['latitude'] is! num ||
        location['longitude'] is! num) {
      throw const PlacesException(PlacesFailure.incomplete);
    }
    final lat = (location['latitude'] as num).toDouble();
    final lng = (location['longitude'] as num).toDouble();
    if (!validCoordinates(lat, lng)) {
      throw const PlacesException(PlacesFailure.incomplete);
    }
    final components = raw['addressComponents'];
    if (components != null && components is! List) {
      throw const PlacesException(PlacesFailure.malformed);
    }
    String component(String type, {bool short = false}) {
      for (final item in (components as List? ?? const [])) {
        if (item is Map &&
            item['types'] is List &&
            (item['types'] as List).contains(type)) {
          final value = item[short ? 'shortText' : 'longText'];
          if (value is String) return value;
        }
      }
      return '';
    }

    String city = '';
    for (final type in [
      'locality',
      'postal_town',
      'sublocality_level_1',
      'sublocality',
      'administrative_area_level_2',
    ]) {
      city = component(type);
      if (city.isNotEmpty) break;
    }
    final address = raw['formattedAddress'];
    if (address is! String || address.trim().isEmpty) {
      throw const PlacesException(PlacesFailure.incomplete);
    }
    final id = raw['id'];
    if (id is! String || id != suggestion.placeId) {
      throw const PlacesException(PlacesFailure.malformed);
    }
    return ResolvedPlace(
      placeId: id,
      label: suggestion.label,
      formattedAddress: address,
      latitude: lat,
      longitude: lng,
      street: [
        component('street_number'),
        component('route'),
      ].where((s) => s.isNotEmpty).join(' '),
      city: city,
      state: component('administrative_area_level_1'),
      stateCode: component('administrative_area_level_1', short: true),
      country: component('country'),
      countryCode: component('country', short: true),
      postalCode: component('postal_code'),
    );
  }
}

/// Immutable configuration for one interaction. Credentials are never telemetry.
class PlacesContext {
  // Origin and its circle bias are snapshots, not configuration changes.
  Map<String, dynamic> get configurationGeography => {
    for (final entry in geography.entries)
      if (entry.key != 'origin' && entry.key != 'locationBias')
        entry.key: entry.value,
    if (geography['locationBias'] is Map &&
        (geography['locationBias'] as Map).containsKey('rectangle'))
      'locationBias': geography['locationBias'],
  };

  final bool enabled;
  final String apiKey, language, region;
  final Map<String, dynamic> geography;
  final bool Function(ResolvedPlace)? accepts;
  const PlacesContext({
    required this.enabled,
    required this.apiKey,
    required this.language,
    this.region = '',
    this.geography = const {},
    this.accepts,
  });
}

class PlacesSearchService {
  static const suggestionsMask =
      'suggestions.placePrediction.placeId,suggestions.placePrediction.text.text,suggestions.placePrediction.structuredFormat.mainText.text,suggestions.placePrediction.structuredFormat.secondaryText.text,suggestions.placePrediction.distanceMeters';
  static const detailsMask = 'id,location,formattedAddress,addressComponents';
  final String application;
  final String platform;
  final Map<String, int> counters = {};
  final Dio _dio;
  final PlacesObserver? observer;
  final Future<List<PlaceSuggestion>> Function(String, PlacesContext)?
  legacySearch;
  final Future<ResolvedPlace?> Function(PlaceSuggestion, PlacesContext)?
  legacyResolve;

  PlacesSearchService({
    Dio? dio,
    this.application = 'test',
    this.platform = 'test',
    this.observer,
    this.legacySearch,
    this.legacyResolve,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 10),
             ),
           ) {
    _dio.options.connectTimeout ??= const Duration(seconds: 10);
  }

  void observe(Map<String, Object> event) {
    final counter =
        '${event['field'] ?? 'location'}.${event['strategy'] ?? 'v2'}.${event['method'] ?? ''}.${event['event']}.${event['status'] ?? ''}';
    counters[counter] = (counters[counter] ?? 0) + 1;
    event = {'application': application, 'platform': platform, ...event};
    try {
      observer?.call(Map.unmodifiable(event));
    } catch (_) {
      /* Metrics cannot break address entry. */
    }
  }

  Future<T> _request<T>(
    String method,
    PlacesContext context,
    String interaction,
    String field,
    Future<T> Function() call,
  ) async {
    if (context.apiKey.isEmpty) {
      throw const PlacesException(PlacesFailure.configuration);
    }
    final watch = Stopwatch()..start();
    var status = 'success';
    observe({
      'event': 'request_started',
      'method': method,
      'interaction': interaction,
      'field': field,
      'strategy': context.enabled ? 'v2' : 'legacy',
    });
    try {
      return await call();
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      final category = CancelToken.isCancel(error)
          ? PlacesFailure.cancelled
          : [
              DioExceptionType.connectionTimeout,
              DioExceptionType.receiveTimeout,
              DioExceptionType.sendTimeout,
            ].contains(error.type)
          ? PlacesFailure.timeout
          : code == 429
          ? PlacesFailure.quota
          : code == 400 || code == 401 || code == 403
          ? PlacesFailure.configuration
          : PlacesFailure.network;
      status = code == null ? category.name : '${code ~/ 100}xx';
      throw PlacesException(category);
    } on PlacesException catch (error) {
      status = error.category.name;
      rethrow;
    } catch (_) {
      status = 'malformed';
      throw const PlacesException(PlacesFailure.malformed);
    } finally {
      observe({
        'event': 'request_finished',
        'method': method,
        'interaction': interaction,
        'field': field,
        'strategy': context.enabled ? 'v2' : 'legacy',
        'status': status,
        'elapsed_ms': watch.elapsedMilliseconds,
      });
    }
  }

  Future<List<PlaceSuggestion>> search(
    String query,
    PlacesContext context, {
    required String? token,
    required String interaction,
    required String field,
    CancelToken? cancelToken,
  }) => _request('autocomplete', context, interaction, field, () async {
    if (!context.enabled) {
      if (legacySearch == null) {
        throw const PlacesException(PlacesFailure.configuration);
      }
      return legacySearch!(query, context);
    }
    final response = await _dio.post(
      'https://places.googleapis.com/v1/places:autocomplete',
      data: {
        'input': query,
        'languageCode': context.language,
        'sessionToken': token,
        'includeQueryPredictions': false,
        'includePureServiceAreaBusinesses': false,
        ...context.geography,
      },
      cancelToken: cancelToken,
      options: Options(
        headers: {
          'X-Goog-Api-Key': context.apiKey,
          'X-Goog-FieldMask': suggestionsMask,
        },
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
      ),
    );
    final data = response.data;
    if (data is! Map ||
        (data['suggestions'] != null && data['suggestions'] is! List)) {
      throw const PlacesException(PlacesFailure.malformed);
    }
    final result = <PlaceSuggestion>[];
    for (final raw in (data['suggestions'] as List? ?? const [])) {
      final suggestion = PlaceSuggestion.fromPrediction(
        raw is Map ? raw['placePrediction'] : null,
      );
      if (suggestion != null) result.add(suggestion);
    }
    observe({
      'event': 'suggestions',
      'interaction': interaction,
      'field': field,
      'count': result.length,
    });
    return List.unmodifiable(result.take(5));
  });

  Future<ResolvedPlace> resolve(
    PlaceSuggestion suggestion,
    PlacesContext context, {
    required String? token,
    required String interaction,
    required String field,
    CancelToken? cancelToken,
  }) => _request('details', context, interaction, field, () async {
    ResolvedPlace? result;
    if (!context.enabled) {
      if (legacyResolve == null) {
        throw const PlacesException(PlacesFailure.configuration);
      }
      result = await legacyResolve!(suggestion, context);
    } else {
      final response = await _dio.get(
        'https://places.googleapis.com/v1/places/${Uri.encodeComponent(suggestion.placeId)}',
        queryParameters: {
          'languageCode': context.language,
          if (token != null) 'sessionToken': token,
        },
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'X-Goog-Api-Key': context.apiKey,
            'X-Goog-FieldMask': detailsMask,
          },
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      result = ResolvedPlace.fromNew(response.data, suggestion);
    }
    if (result == null ||
        !ResolvedPlace.validCoordinates(result.latitude, result.longitude)) {
      throw const PlacesException(PlacesFailure.incomplete);
    }
    if (context.enabled &&
        context.accepts != null &&
        !context.accepts!(result)) {
      throw const PlacesException(PlacesFailure.outsideRegion);
    }
    return result;
  });
}
