import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/location/service_region.dart';
import 'package:ride_app/core/services/address_search_controller.dart';
import 'package:ride_app/core/services/location_service.dart';
import 'package:ride_app/core/services/places_search_service.dart';
import 'package:ride_app/core/theme/app_theme.dart';
import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/location_repository.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_recent_locations_use_case.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/save_recent_location_use_case.dart';
import 'package:ride_app/features/ride_room/presentation/providers/enter_route_provider.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/location_component/location_models/address_details.dart';
import 'package:ride_app/shared/location_component/location_ui/address_search_field.dart';
import 'package:ride_app/shared/models/selected_location.dart';
import 'package:ride_app/shared/providers/place_picker_provider.dart';

import 'address_search_test.dart' show FakeTransport, predictions, details;

class TestLocationService extends Mock implements LocationService {
  @override
  final PlacesSearchService placesSearch;
  int reverseLookups = 0;
  TestLocationService(this.placesSearch);
  @override
  ServiceRegion get activeRegion => ServiceRegionConfig.global;
  @override
  AddressSearchController createAddressSearch({
    required void Function() onChanged,
    LatLng? Function()? origin,
    bool legacyDeviceOrigin = true,
    void Function(LatLng)? onLegacyOriginResolved,
    Duration legacyDebounce = const Duration(milliseconds: 300),
  }) => AddressSearchController(
    service: placesSearch,
    contextProvider: () =>
        const PlacesContext(enabled: true, apiKey: 'test-only', language: 'en'),
    onChanged: onChanged,
  );
  @override
  Future<Map<String, dynamic>?> getAddressFromCoordinates(
    double lat,
    double lng, {
    required String reason,
  }) async {
    reverseLookups++;
    return {
      'results': [
        {
          'formatted_address': 'Manual pin',
          'address_components': [
            {
              'types': ['locality'],
              'long_name': 'Manual city',
            },
            {
              'types': ['administrative_area_level_1'],
              'long_name': 'Manual state',
            },
            {
              'types': ['country'],
              'long_name': 'Manual country',
              'short_name': 'MC',
            },
          ],
        },
      ],
    };
  }
}

class TestRepository extends Mock implements LocationRepository {
  final saved = <LocationEntity>[];
  @override
  Future<List<LocationEntity>> getRecentLocations() async => saved;
  @override
  Future<void> saveRecentLocation(LocationEntity location) async {
    saved.add(location);
  }
}

void main() {
  late FakeTransport transport;
  late TestLocationService locationService;
  setUp(() {
    transport = FakeTransport();
    locationService = TestLocationService(
      PlacesSearchService(dio: Dio()..httpClientAdapter = transport),
    );
  });
  Future<void> flush(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  }

  testWidgets(
    'picker selection shares one resolved address with map; programmatic idle does not geocode; next drag does',
    (tester) async {
      final picker = PlacePickerNotifier(locationService);
      picker.searchPlaces('sample');
      await tester.pump(const Duration(milliseconds: 400));
      await flush(tester);
      transport.respond(0, predictions('one'));
      await flush(tester);
      final chosen = picker.state.suggestions.single;
      final selected = picker.selectSuggestion(chosen);
      final duplicate = picker.selectSuggestion(chosen);
      await flush(tester);
      expect(transport.requests, hasLength(2));
      expect(await duplicate, isNull);
      transport.respond(1, details('one'));
      await flush(tester);
      final point = await selected;
      expect(point, const LatLng(0, 10));
      expect(picker.state.selectedAddress.city, 'Sample Town');
      picker.onCameraMove(point!);
      picker.onCameraIdle();
      await tester.pump(const Duration(seconds: 1));
      expect(locationService.reverseLookups, 0);
      expect(transport.requests, hasLength(2));
      picker.onMapGestureStarted();
      picker.onCameraMove(const LatLng(1, 11));
      picker.onCameraIdle();
      picker.onCameraIdle();
      await tester.pump(const Duration(milliseconds: 400));
      await flush(tester);
      expect(locationService.reverseLookups, 1);
      expect(picker.state.selectedAddress.city, 'Manual city');
      picker.dispose();
    },
  );

  testWidgets(
    'picker reopening a resolved value makes no request; interrupted selection remains unresolved',
    (tester) async {
      final picker = PlacePickerNotifier(locationService);
      final address = Address.fromResolvedPlace(
        const ResolvedPlace(
          placeId: 'one',
          label: 'Sample',
          formattedAddress: 'Sample road',
          latitude: 0,
          longitude: 10,
          city: 'Sample Town',
          state: 'Sample State',
        ),
      );
      await picker.setInitialLocation(initialAddress: address);
      expect(locationService.reverseLookups, 0);
      expect(picker.state.selectedAddress.city, 'Sample Town');
      picker.searchPlaces('sample');
      await tester.pump(const Duration(milliseconds: 400));
      await flush(tester);
      transport.respond(0, predictions('one'));
      await flush(tester);
      final selected = picker.selectSuggestion(picker.state.suggestions.single);
      await flush(tester);
      picker.onMapGestureStarted();
      transport.respond(1, details('one'));
      await flush(tester);
      expect(await selected, isNull);
      expect(picker.state.selectedAddress.formattedAddress, '');
      picker.dispose();
    },
  );

  testWidgets(
    'ride provider captures field identity, blocks stale Details and reuses a recent without requests',
    (tester) async {
      final repository = TestRepository();
      locator.registerSingleton<LocationService>(locationService);
      locator.registerSingleton<GetRecentLocationsUseCase>(
        GetRecentLocationsUseCase(repository),
      );
      locator.registerSingleton<SaveRecentLocationUseCase>(
        SaveRecentLocationUseCase(repository),
      );
      final container = ProviderContainer();
      final notifier = container.read(enterRouteProvider.notifier);
      notifier.onSearchQueryChanged('sample', type: RideLocationType.pickup);
      await tester.pump(const Duration(milliseconds: 400));
      await flush(tester);
      transport.respond(0, predictions('one'));
      await flush(tester);
      final chosen = container.read(enterRouteProvider).searchResults.single;
      final selected = notifier.resolveSelectedLocation(
        location: chosen,
        type: RideLocationType.pickup,
      );
      await flush(tester);
      notifier.activateField(RideLocationType.dropoff);
      transport.respond(1, details('one'));
      await flush(tester);
      expect(await selected, isNull);
      final recent = LocationEntity(
        id: 'recent',
        name: 'Saved',
        address: 'Saved address',
        latitude: 0,
        longitude: 10,
        type: RideLocationType.pickup,
        timestamp: nullTimestamp,
      );
      final result = await notifier.resolveSelectedLocation(
        location: recent,
        type: RideLocationType.dropoff,
      );
      expect(result!.latitude, 0);
      expect(transport.requests, hasLength(2));
      container.dispose();
      await locator.reset();
    },
  );

  Future<void> openField(
    WidgetTester tester,
    TextEditingController text,
    void Function(AddressDetails) onResolved,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AddressSearchField(
              controller: text,
              locationService: locationService,
              onDetailsFetched: onResolved,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Street Address'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'sample');
    await tester.pump(const Duration(milliseconds: 400));
    await flush(tester);
    transport.respond(0, predictions('one'));
    await flush(tester);
  }

  testWidgets(
    'profile tap despite focus loss fetches once and applies one full Details callback',
    (tester) async {
      final text = TextEditingController();
      final applied = <AddressDetails>[];
      await openField(tester, text, applied.add);
      await tester.tap(find.text('Sample business, sample street'));
      await flush(tester);
      transport.respond(1, details('one'));
      await flush(tester);
      expect(transport.requests, hasLength(2));
      expect(applied, hasLength(1));
      expect(applied.single.isResolvedFromPlaces, isTrue);
      expect(applied.single.city, 'Sample Town');
      expect(text.text, '123 Sample Road');
      await tester.pumpWidget(const SizedBox());
      text.dispose();
    },
  );

  testWidgets('profile external clear discards pending Details', (
    tester,
  ) async {
    final text = TextEditingController();
    final applied = <AddressDetails>[];
    await openField(tester, text, applied.add);
    await tester.tap(find.text('Sample business, sample street'));
    await flush(tester);
    text.clear();
    transport.respond(1, details('one'));
    await flush(tester);
    expect(applied, isEmpty);
    expect(text.text, '');
    expect(transport.requests, hasLength(2));
    await tester.pumpWidget(const SizedBox());
    text.dispose();
  });
}

final nullTimestamp = DateTime(2026);
