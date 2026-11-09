import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/core/config/remote_config_model.dart';
import 'package:ride_app/core/services/address_search_controller.dart';
import 'package:ride_app/core/services/places_search_service.dart';

class FakeTransport implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final pending = <Completer<ResponseBody>>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    final completer = Completer<ResponseBody>();
    pending.add(completer);
    return completer.future;
  }

  void respond(int index, Object data, {int status = 200}) =>
      pending[index].complete(
        ResponseBody.fromString(
          jsonEncode(data),
          status,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> predictions(String id) => {
  'suggestions': [
    {
      'queryPrediction': {
        'text': {'text': 'ignored query'},
      },
    },
    {
      'placePrediction': {
        'placeId': id,
        'text': {'text': 'Sample business, sample street'},
        'structuredFormat': {
          'mainText': {'text': 'Sample business'},
        },
        'distanceMeters': 42,
      },
    },
    {
      'placePrediction': {'placeId': 'bad'},
    },
    null,
  ],
};
Map<String, dynamic> details(String id, {double latitude = 0}) => {
  'id': id,
  'location': {'latitude': latitude, 'longitude': 10},
  'formattedAddress': '123 Sample Road',
  'addressComponents': [
    {
      'longText': 'Sample County',
      'types': ['administrative_area_level_2'],
    },
    {
      'longText': 'Sample Town',
      'types': ['postal_town'],
    },
    {
      'longText': '123',
      'types': ['street_number'],
    },
    {
      'longText': 'Sample Road',
      'types': ['route'],
    },
    {
      'longText': 'Florida',
      'shortText': 'FL',
      'types': ['administrative_area_level_1'],
    },
  ],
};

void main() {
  late FakeTransport transport;
  late PlacesSearchService service;
  late List<Map<String, Object>> events;
  PlacesContext config = const PlacesContext(
    enabled: true,
    apiKey: 'test-secret',
    language: 'es',
    region: 'test',
    geography: {
      'origin': {'latitude': 0.0, 'longitude': 10.0},
      'includedRegionCodes': ['us'],
    },
  );
  late AddressSearchController controller;
  var tokens = 0;
  setUp(() {
    config = const PlacesContext(
      enabled: true,
      apiKey: 'test-secret',
      language: 'es',
      region: 'test',
      geography: {
        'origin': {'latitude': 0.0, 'longitude': 10.0},
        'includedRegionCodes': ['us'],
      },
    );
    tokens = 0;
    events = [];
    transport = FakeTransport();
    service = PlacesSearchService(
      dio: Dio()..httpClientAdapter = transport,
      observer: events.add,
    );
    controller = AddressSearchController(
      service: service,
      contextProvider: () => config,
      tokenGenerator: () => 'test-token-${++tokens}',
    );
  });
  tearDown(() => controller.dispose());
  Future<void> flush(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> settle(
    WidgetTester tester,
    String query, {
    String field = 'ride.pickup',
  }) async {
    controller.edit(query, field: field);
    await tester.pump(const Duration(milliseconds: 400));
    await flush(tester);
  }

  test('rollout defaults off and malformed values fail closed', () {
    for (final raw in [
      '',
      '{}',
      '{"addressSearchV2Enabled":"true"}',
      '{"addressSearchV2Enabled":1}',
      'invalid',
    ]) {
      expect(
        RemoteConfigModel.fromConfigString(raw).addressSearchV2Enabled,
        isFalse,
      );
    }
    expect(
      RemoteConfigModel.fromConfigString(
        '{"addressSearchV2Enabled":true}',
      ).addressSearchV2Enabled,
      isTrue,
    );
    expect(
      RemoteConfigModel.defaults()
          .copyWith(addressSearchV2Enabled: true)
          .addressSearchV2Enabled,
      isTrue,
    );
  });

  testWidgets('debounce, minimum, same query and new request contracts', (
    tester,
  ) async {
    for (final query in ['', ' ', 'a']) {
      await settle(tester, query);
    }
    expect(transport.requests, isEmpty);
    controller.edit('su', field: 'ride.pickup');
    await tester.pump(const Duration(milliseconds: 300));
    controller.edit('sub', field: 'ride.pickup');
    await tester.pump(const Duration(milliseconds: 399));
    expect(transport.requests, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await flush(tester);
    expect(transport.requests, hasLength(1));
    await settle(tester, 'sub');
    expect(transport.requests, hasLength(1));
    final request = transport.requests.single;
    expect(
      request.uri.toString(),
      'https://places.googleapis.com/v1/places:autocomplete',
    );
    expect(request.data['input'], 'sub');
    expect(request.data['sessionToken'], 'test-token-1');
    expect(request.data['languageCode'], 'es');
    expect(request.data['origin'], config.geography['origin']);
    expect(request.data['includeQueryPredictions'], isFalse);
    expect(request.data['includePureServiceAreaBusinesses'], isFalse);
    for (final key in [
      'textQuery',
      'pageSize',
      'rankPreference',
      'includedPrimaryTypes',
    ]) {
      expect(request.data.containsKey(key), isFalse);
    }
    expect(
      request.headers['X-Goog-FieldMask'],
      PlacesSearchService.suggestionsMask,
    );
    transport.respond(0, predictions('one'));
    await flush(tester);
    expect(controller.loading, isFalse, reason: events.toString());
    expect(controller.error, isNull);
    expect(controller.suggestions, hasLength(1));
    expect(controller.suggestions.single.primaryText, 'Sample business');
    expect(controller.suggestions.single.secondaryText, '');
    expect(controller.suggestions.single.distanceMeters, 42);
    await settle(tester, 'sub');
    expect(transport.requests, hasLength(1));
  });

  testWidgets(
    'one Details request, same token, full components, zero latitude and double tap',
    (tester) async {
      await settle(tester, 'sub');
      transport.respond(0, predictions('one'));
      await flush(tester);
      await settle(tester, 'subway');
      transport.respond(1, predictions('two'));
      await flush(tester);
      final suggestion = controller.suggestions.single;
      final first = controller.select(suggestion),
          second = controller.select(suggestion);
      expect(identical(first, second), isTrue);
      await flush(tester);
      expect(transport.requests, hasLength(3));
      final request = transport.requests.last;
      expect(request.method, 'GET');
      expect(request.uri.path, '/v1/places/two');
      expect(request.queryParameters['sessionToken'], 'test-token-1');
      expect(
        request.headers['X-Goog-FieldMask'],
        'id,location,formattedAddress,addressComponents',
      );
      transport.respond(2, details('two'));
      await flush(tester);
      final place = await first;
      expect(place!.latitude, 0);
      expect(place.city, 'Sample Town');
      expect(place.postalCode, '');
      expect(place.street, '123 Sample Road');
      expect(place.label, suggestion.label);
      expect(
        transport.requests.where((r) => r.uri.host == 'maps.googleapis.com'),
        isEmpty,
      );
      await settle(tester, 'new');
      expect(transport.requests.last.data['sessionToken'], 'test-token-2');
      expect(events.toString(), isNot(contains('test-secret')));
      expect(events.toString(), isNot(contains('test-token')));
      expect(events.toString(), isNot(contains('Sample')));
    },
  );

  testWidgets('A B A and a field switch invalidate generations immediately', (
    tester,
  ) async {
    await settle(tester, 'sub');
    controller.edit('subway', field: 'ride.pickup');
    controller.edit('sub', field: 'ride.pickup');
    transport.respond(0, predictions('obsolete'));
    await flush(tester);
    expect(controller.suggestions, isEmpty);
    await tester.pump(const Duration(milliseconds: 400));
    await flush(tester);
    transport.respond(1, predictions('current'));
    await flush(tester);
    expect(controller.suggestions.single.placeId, 'current');
    await settle(tester, 'sub', field: 'ride.dropoff');
    expect(transport.requests.last.data['sessionToken'], 'test-token-2');
    transport.respond(2, predictions('dropoff'));
    await flush(tester);
    final pending = controller.select(controller.suggestions.single);
    await flush(tester);
    controller.edit('changed', field: 'ride.dropoff');
    transport.respond(3, details('dropoff'));
    await flush(tester);
    expect(await pending, isNull);
    expect(controller.suggestions, isEmpty);
    controller.abandon();
  });

  testWidgets('close, clear, dispose and config change reject pending work', (
    tester,
  ) async {
    controller.edit('sub', field: 'profile');
    controller.abandon();
    await tester.pump(const Duration(seconds: 1));
    expect(transport.requests, isEmpty);
    await settle(tester, 'sub');
    config = const PlacesContext(
      enabled: false,
      apiKey: 'changed',
      language: 'es',
    );
    transport.respond(0, predictions('obsolete'));
    await flush(tester);
    expect(controller.suggestions, isEmpty);
    controller.dispose();
    await settle(tester, 'sub');
    expect(transport.requests, hasLength(1));
  });

  testWidgets(
    'failed Details has no automatic fallback; explicit retry has no retired token',
    (tester) async {
      await settle(tester, 'sub');
      transport.respond(0, predictions('one'));
      await flush(tester);
      final first = controller.select(controller.suggestions.single);
      await flush(tester);
      transport.respond(1, {}, status: 503);
      await flush(tester);
      expect(await first, isNull);
      expect(controller.error, PlacesFailure.network);
      expect(controller.canRetrySelection, isTrue);
      expect(transport.requests, hasLength(2));
      final retry = controller.retrySelection();
      await flush(tester);
      expect(
        transport.requests.last.queryParameters.containsKey('sessionToken'),
        isFalse,
      );
      transport.respond(2, details('one'));
      await flush(tester);
      expect(await retry, isNotNull);
      expect(events.where((e) => e['event'] == 'retry'), hasLength(1));
    },
  );

  testWidgets(
    'empty success differs from malformed, credentials and quota failures',
    (tester) async {
      await settle(tester, 'empty');
      transport.respond(0, {});
      await flush(tester);
      expect(controller.error, isNull);
      expect(controller.suggestions, isEmpty);
      await settle(tester, 'malformed');
      transport.respond(1, {'suggestions': 'invalid'});
      await flush(tester);
      expect(controller.error, PlacesFailure.malformed);
      await settle(tester, 'quota');
      transport.respond(2, {}, status: 429);
      await flush(tester);
      expect(controller.error, PlacesFailure.quota);
      await settle(tester, 'credential');
      transport.respond(3, {}, status: 403);
      await flush(tester);
      expect(controller.error, PlacesFailure.configuration);
    },
  );

  testWidgets(
    'origin is prepared once and changing input during preparation dispatches only the latest query',
    (tester) async {
      controller.dispose();
      final preparing = Completer<PlacesContext>();
      var originLookups = 0;
      controller = AddressSearchController(
        service: service,
        contextProvider: () => config,
        prepareContext: (c) {
          originLookups++;
          return preparing.future;
        },
      );
      await settle(tester, 'sub');
      expect(transport.requests, isEmpty);
      await settle(tester, 'subway');
      preparing.complete(config);
      await flush(tester);
      expect(originLookups, 1);
      expect(transport.requests, hasLength(1));
      expect(transport.requests.single.data['input'], 'subway');
      transport.respond(0, predictions('one'));
      await flush(tester);
      await settle(tester, 'next');
      expect(originLookups, 1);
      transport.respond(1, predictions('two'));
      await flush(tester);
    },
  );

  testWidgets(
    'selected service area failure is explicit and never clamps the returned coordinates',
    (tester) async {
      config = PlacesContext(
        enabled: true,
        apiKey: 'test',
        language: 'en',
        accepts: (_) => false,
      );
      await settle(tester, 'sample');
      transport.respond(0, predictions('one'));
      await flush(tester);
      final selected = controller.select(controller.suggestions.single);
      await flush(tester);
      transport.respond(1, details('one'));
      await flush(tester);
      expect(await selected, isNull);
      expect(controller.error, PlacesFailure.outsideRegion);
      expect(transport.requests, hasLength(2));
    },
  );

  test(
    'coordinate validation rejects missing, nonfinite and out of range data',
    () {
      const suggestion = PlaceSuggestion(placeId: 'one', label: 'Sample');
      for (final raw in [
        {},
        {...details('one'), 'location': {}},
        details('one', latitude: 91),
        details('one', latitude: double.nan),
        details('one', latitude: double.infinity),
      ]) {
        expect(
          () => ResolvedPlace.fromNew(raw, suggestion),
          throwsA(isA<PlacesException>()),
        );
      }
      expect(ResolvedPlace.validCoordinates(0, 0), isTrue);
      expect(
        ResolvedPlace.fromNew(details('one'), suggestion).city,
        'Sample Town',
      );
    },
  );

  testWidgets(
    'legacy strategy is isolated and permission failure does not block typing',
    (tester) async {
      controller.dispose();
      var searches = 0, resolutions = 0;
      service = PlacesSearchService(
        dio: Dio()..httpClientAdapter = transport,
        legacySearch: (_, _) async {
          searches++;
          return [const PlaceSuggestion(placeId: 'legacy', label: 'Sample')];
        },
        legacyResolve: (s, _) async {
          resolutions++;
          return ResolvedPlace(
            placeId: s.placeId,
            label: s.label,
            formattedAddress: s.label,
            latitude: 0,
            longitude: 0,
          );
        },
      );
      config = PlacesContext(
        enabled: false,
        apiKey: 'test',
        language: 'en',
        accepts: (_) => false,
      );
      controller = AddressSearchController(
        service: service,
        contextProvider: () => config,
        prepareContext: (c) async => c,
      );
      await settle(tester, 'sample');
      expect(searches, 1);
      final result = await controller.select(controller.suggestions.single);
      expect(result, isNotNull);
      expect(resolutions, 1);
      expect(transport.requests, isEmpty);
    },
  );
}
