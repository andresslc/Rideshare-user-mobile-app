import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/core/services/address_search_controller.dart';
import 'package:ride_app/core/services/places_search_service.dart';
import 'package:ride_app/core/theme/app_theme.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/location_component/location_ui/address_search_error.dart';

import 'address_search_test.dart' show FakeTransport, predictions, details;

Future<void> flushReview(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(Duration.zero);
  });
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  for (final category in PlacesFailure.values.where(
    (c) => c != PlacesFailure.cancelled,
  )) {
    testWidgets(
      'Details $category offers only useful retry and localized guidance',
      (tester) async {
        final transport = FakeTransport();
        final controller = AddressSearchController(
          service: PlacesSearchService(
            dio: Dio()..httpClientAdapter = transport,
          ),
          contextProvider: () => PlacesContext(
            enabled: true,
            apiKey: 'test',
            language: 'en',
            accepts: (_) => category != PlacesFailure.outsideRegion,
          ),
        );
        controller.edit('sample', field: 'profile');
        await tester.pump(const Duration(milliseconds: 400));
        await flushReview(tester);
        transport.respond(0, predictions('one'));
        await flushReview(tester);
        final selection = controller.select(controller.suggestions.single);
        await flushReview(tester);
        switch (category) {
          case PlacesFailure.timeout:
            transport.pending[1].completeError(
              DioException(
                requestOptions: transport.requests[1],
                type: DioExceptionType.receiveTimeout,
              ),
            );
          case PlacesFailure.network:
            transport.respond(1, {}, status: 503);
          case PlacesFailure.configuration:
            transport.respond(1, {}, status: 403);
          case PlacesFailure.quota:
            transport.respond(1, {}, status: 429);
          case PlacesFailure.malformed:
            transport.respond(1, {...details('one'), 'id': 'wrong'});
          case PlacesFailure.incomplete:
            transport.respond(1, {...details('one'), 'location': {}});
          default:
            transport.respond(1, details('one'));
        }
        await flushReview(tester);
        expect(await selection, isNull);
        expect(controller.error, category);
        expect(controller.canRetrySelection, category.retryable);
        expect(controller.canRetry, category.retryable);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AddressSearchError(
                failure: controller.error!,
                onRetry: () {},
              ),
            ),
          ),
        );
        expect(find.byKey(ValueKey(category.messageKey)), findsOneWidget);
        expect(
          find.text('Try again'),
          category.retryable ? findsOneWidget : findsNothing,
        );
        if (!category.retryable) {
          expect(await controller.retrySelection(), isNull);
          controller.retrySearch();
          await tester.pump(const Duration(seconds: 1));
          expect(transport.requests, hasLength(2));
        }
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      },
    );
  }

  testWidgets(
    'origin arrival keeps active token and bias, next interaction uses new origin',
    (tester) async {
      final transport = FakeTransport();
      Map<String, dynamic> origin = {'latitude': 0.0, 'longitude': 10.0};
      var tokens = 0;
      final controller = AddressSearchController(
        service: PlacesSearchService(dio: Dio()..httpClientAdapter = transport),
        tokenGenerator: () => 'token-${++tokens}',
        contextProvider: () => PlacesContext(
          enabled: true,
          apiKey: 'test',
          language: 'en',
          geography: {
            'origin': origin,
            'locationBias': {
              'circle': {'center': origin, 'radius': 50000.0},
            },
          },
        ),
      );
      controller.edit('sample', field: 'dropoff');
      await tester.pump(const Duration(milliseconds: 400));
      await flushReview(tester);
      final initialOrigin = origin;
      final token = transport.requests[0].data['sessionToken'];
      origin = {'latitude': 2.0, 'longitude': 11.0};
      transport.respond(0, predictions('one'));
      await flushReview(tester);
      expect(controller.suggestions, hasLength(1));
      controller.edit('sample next', field: 'dropoff');
      await tester.pump(const Duration(milliseconds: 400));
      await flushReview(tester);
      expect(transport.requests[1].data['sessionToken'], token);
      expect(transport.requests[1].data['origin'], initialOrigin);
      transport.respond(1, predictions('two'));
      await flushReview(tester);
      final selected = controller.select(controller.suggestions.single);
      await flushReview(tester);
      transport.respond(2, details('two'));
      await flushReview(tester);
      expect(await selected, isNotNull);
      controller.edit('next interaction', field: 'dropoff');
      await tester.pump(const Duration(milliseconds: 400));
      await flushReview(tester);
      expect(transport.requests[3].data['origin'], origin);
      expect(transport.requests[3].data['sessionToken'], isNot(token));
      transport.respond(3, predictions('three'));
      await flushReview(tester);
      controller.dispose();
    },
  );

  testWidgets('service area bounds change invalidates pending search', (
    tester,
  ) async {
    final transport = FakeTransport();
    var north = 10.0;
    final controller = AddressSearchController(
      service: PlacesSearchService(dio: Dio()..httpClientAdapter = transport),
      contextProvider: () => PlacesContext(
        enabled: true,
        apiKey: 'test',
        language: 'en',
        geography: {
          'locationBias': {
            'rectangle': {
              'high': {'latitude': north, 'longitude': 10.0},
            },
          },
        },
      ),
    );
    controller.edit('sample', field: 'dropoff');
    await tester.pump(const Duration(milliseconds: 400));
    await flushReview(tester);
    north = 20;
    transport.respond(0, predictions('one'));
    await flushReview(tester);
    expect(controller.suggestions, isEmpty);
    controller.dispose();
  });

  testWidgets(
    'legacy sends one character after 300ms and preserves all results and request count',
    (tester) async {
      var searches = 0, selections = 0;
      final queries = <String>[];
      final controller = AddressSearchController(
        service: PlacesSearchService(
          legacySearch: (q, c) async {
            queries.add(q);
            searches++;
            return List.generate(
              10,
              (i) => PlaceSuggestion(placeId: '$i', label: 'Sample $i'),
            );
          },
          legacyResolve: (s, c) async {
            selections++;
            return ResolvedPlace(
              placeId: s.placeId,
              label: s.label,
              formattedAddress: s.label,
              latitude: 0,
              longitude: 10,
            );
          },
        ),
        contextProvider: () =>
            const PlacesContext(enabled: false, apiKey: 'test', language: 'en'),
      );
      controller.edit('a', field: 'pickup');
      await tester.pump(const Duration(milliseconds: 299));
      expect(searches, 0);
      await tester.pump(const Duration(milliseconds: 1));
      await flushReview(tester);
      expect(
        searches,
        1,
        reason:
            'loading=${controller.loading}; error=${controller.error}; enabled=${controller.enabled}; counts=${controller.service.counters}',
      );
      expect(controller.suggestions, hasLength(10));
      expect(await controller.select(controller.suggestions.first), isNotNull);
      expect(selections, 1);
      expect(queries, ['a']);
      controller.dispose();
    },
  );
}
