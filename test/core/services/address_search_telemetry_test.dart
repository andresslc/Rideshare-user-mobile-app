import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/core/constants/constants_data.dart';
import 'package:ride_app/core/services/location_service.dart';
import 'package:ride_app/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'address_search_review_test.dart' show flushReview;
import 'address_search_test.dart' show FakeTransport;

void main() {
  final previous = remoteConfigModel;
  late FakeTransport transport;
  late LocationService service;
  late List<Map<String, Object>> events;
  final response = {
    'status': 'OK',
    'results': [
      {
        'formatted_address': 'Private test address',
        'address_components': [
          {
            'types': ['locality'],
            'long_name': 'Private test city',
          },
        ],
      },
    ],
  };
  setUp(() async {
    remoteConfigModel = previous.copyWith(mapApiKey: 'private-test-key');
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    transport = FakeTransport();
    events = [];
    service = LocationService(
      storage,
      dio: Dio()..httpClientAdapter = transport,
      placesObserver: events.add,
    );
  });
  tearDown(() => remoteConfigModel = previous);
  for (final reason in [
    'initial_position',
    'manual_pin',
    'pickup_city_fallback',
    'initial_address_fallback',
    'legacy_components_fallback',
  ]) {
    testWidgets(
      'reverse geocode $reason pairs dispatch/outcome without sensitive fields',
      (tester) async {
        final pending = service.getAddressFromCoordinates(
          28.5,
          -81.4,
          reason: reason,
        );
        await flushReview(tester);
        transport.respond(0, response);
        await flushReview(tester);
        expect(await pending, isNotNull);
        expect(events.map((e) => e['event']), [
          'request_started',
          'request_finished',
        ]);
        expect(
          events.every(
            (e) => e['method'] == 'reverse_geocode' && e['reason'] == reason,
          ),
          isTrue,
        );
        expect(events.last['status'], 'success');
        expect(events.last['elapsed_ms'], isA<int>());
        for (final forbidden in [
          'query',
          'address',
          'latitude',
          'longitude',
          'origin',
          'latlng',
          'key',
          'apiKey',
          'sessionToken',
        ]) {
          expect(events.any((e) => e.containsKey(forbidden)), isFalse);
        }
        expect(events.toString(), isNot(contains('Private')));
        expect(events.toString(), isNot(contains('private-test-key')));
        expect(events.toString(), isNot(contains('28.5')));
      },
    );
  }
  for (final status in [
    'ZERO_RESULTS',
    'OVER_QUERY_LIMIT',
    'REQUEST_DENIED',
    'UNKNOWN_ERROR',
  ]) {
    testWidgets('reverse geocode $status emits a sanitized outcome', (
      tester,
    ) async {
      final pending = service.getAddressFromCoordinates(
        28.5,
        -81.4,
        reason: 'manual_pin',
      );
      await flushReview(tester);
      transport.respond(0, {'status': status, 'results': []});
      await flushReview(tester);
      expect(await pending, isNull);
      expect(
        events.last['status'],
        {
          'ZERO_RESULTS': 'incomplete',
          'OVER_QUERY_LIMIT': 'quota',
          'REQUEST_DENIED': 'configuration',
          'UNKNOWN_ERROR': 'network',
        }[status],
      );
    });
  }
  testWidgets(
    'reverse geocode denial without results stays a configuration error',
    (tester) async {
      final pending = service.getAddressFromCoordinates(
        28.5,
        -81.4,
        reason: 'initial_position',
      );
      await flushReview(tester);
      transport.respond(0, {'status': 'REQUEST_DENIED'});
      await flushReview(tester);
      expect(await pending, isNull);
      expect(events.last['status'], 'configuration');
    },
  );
  testWidgets('reverse geocode OK with no results is incomplete', (
    tester,
  ) async {
    final pending = service.getAddressFromCoordinates(
      28.5,
      -81.4,
      reason: 'manual_pin',
    );
    await flushReview(tester);
    transport.respond(0, {'status': 'OK', 'results': []});
    await flushReview(tester);
    expect(await pending, isNull);
    expect(events.last['status'], 'incomplete');
  });
  testWidgets(
    'reverse geocode timeout emits completion without raw request error',
    (tester) async {
      final pending = service.getAddressFromCoordinates(
        28.5,
        -81.4,
        reason: 'initial_position',
      );
      await flushReview(tester);
      transport.pending[0].completeError(
        DioException(
          requestOptions: transport.requests[0],
          type: DioExceptionType.receiveTimeout,
          message: 'private response',
        ),
      );
      await flushReview(tester);
      expect(await pending, isNull);
      expect(events.last['status'], 'timeout');
      expect(events.toString(), isNot(contains('private response')));
    },
  );
  testWidgets('coordinate helpers forward explicit reasons and resolved city', (
    tester,
  ) async {
    final city = service.getCityFromCoordinates(
      28.5,
      -81.4,
      reason: 'pickup_city_fallback',
    );
    await flushReview(tester);
    transport.respond(0, response);
    await flushReview(tester);
    expect(await city, 'Private test city');
    expect(events.last['reason'], 'pickup_city_fallback');
    final name = service.getPlaceNameFromCoordinates(
      28.5,
      -81.4,
      reason: 'initial_position',
    );
    await flushReview(tester);
    transport.respond(1, response);
    await flushReview(tester);
    expect(await name, 'Private test address');
    expect(events.last['reason'], 'initial_position');
  });
}
