import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ride_app/core/constants/constants_data.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/location/service_region.dart';
import 'package:ride_app/core/params/fare_calculator_params.dart';
import 'package:ride_app/core/params/find_ride_params.dart';
import 'package:ride_app/core/services/location_service.dart';
import 'package:ride_app/core/services/storage_service.dart';
import 'package:ride_app/core/theme/app_theme.dart';
import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_fare_quote_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_fare_repository.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/apply_promo_code_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/calculate_fare_usecase.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_recent_locations_use_case.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/save_recent_location_use_case.dart';
import 'package:ride_app/features/ride_room/enums/ride_enum.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/carpool_state.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';
import 'package:ride_app/features/ride_room/screens/enter_route_screen.dart';
import 'package:ride_app/features/ride_room/screens/ride_place_picker_screen.dart';
import 'package:ride_app/features/ride_room/screens/select_ride_sheet.dart';
import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';
import 'package:ride_app/features/settings/presentation/providers/saved_locations_provider.dart';
import 'package:ride_app/features/settings/presentation/states/saved_locations_state.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/location_component/location_models/address_details.dart';
import 'package:ride_app/shared/location_component/location_ui/address_search_field.dart';
import 'package:ride_app/shared/providers/place_picker_provider.dart';
import 'package:ride_app/shared/screens/place_picker_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'address_search_integration_test.dart' show TestRepository;
import 'address_search_review_test.dart' show flushReview;
import 'address_search_test.dart' show FakeTransport, predictions, details;

class ScreenLocationService extends LocationService {
  final reasons = <String>[];
  final legacyQueries = <String>[];
  int freshLookups = 0, legacyDetails = 0, profileDetails = 0;
  ScreenLocationService(
    super.storage,
    Dio dio,
    void Function(Map<String, Object>) observer,
  ) : super(dio: dio, placesObserver: observer);
  @override
  Future<Position?> getLastKnownLocation() async => null;
  @override
  Future<Position> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
  }) async {
    freshLookups++;
    return Position(
      latitude: 28.5,
      longitude: -81.4,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<LocationAddressDetails> getLocationDetailsFromCoordinates(
    double lat,
    double lng, {
    String fallback = 'Unknown location',
    required String reason,
  }) async {
    reasons.add(reason);
    return LocationAddressDetails(name: fallback, city: 'Fallback City');
  }

  @override
  Future<Map<String, dynamic>?> getAddressFromCoordinates(
    double lat,
    double lng, {
    required String reason,
  }) async {
    reasons.add(reason);
    return {
      'results': [
        {
          'formatted_address': 'Manual pin',
          'address_components': [
            {
              'types': ['locality'],
              'long_name': 'Manual City',
            },
            {
              'types': ['administrative_area_level_1'],
              'long_name': 'Florida',
            },
          ],
        },
      ],
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getPlaceSuggestions(
    String query, {
    LatLng? origin,
  }) async {
    legacyQueries.add(query);
    return [
      {
        'place_id': 'legacy',
        'description': 'Legacy address',
        'structured_formatting': {'main_text': 'Legacy'},
      },
    ];
  }

  @override
  Future<Position?> getPlaceDetails(String placeId) async {
    legacyDetails++;
    return getCurrentLocation(requestPermissionIfNeeded: false);
  }

  @override
  Future<AddressDetails?> getAddressDetailsFromPlaceId(String placeId) async {
    profileDetails++;
    return AddressDetails(
      latitude: 28.5,
      longitude: -81.4,
      city: 'Orlando',
      state: 'Florida',
      country: 'US',
      zipCode: '',
    );
  }
}

class FakeRoutes implements HttpClientAdapter {
  int requests = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    return ResponseBody.fromString(
      jsonEncode({
        'code': 'Ok',
        'routes': [
          {
            'geometry': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
            'distance': 1000,
            'duration': 60,
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class ScreenMapProvider extends MapProvider {
  ScreenMapProvider(Dio dio) : super(routeDio: dio);
  void seedPromo() => state = AsyncData(
    state.value!.copyWith(promoCodeId: 'test-promo', promoCode: 'PROMO'),
  );
}

class FareRepository extends Mock implements RideFareRepository {}

class PromoUseCase extends Mock implements ApplyPromoCodeUseCase {}

class ScreenFareUseCase extends CalculateFareUseCase {
  final params = <FareCalculatorParams>[];
  ScreenFareUseCase() : super(FareRepository());
  @override
  Future<Right<Never, RideFareQuoteEntity>> call(
    FareCalculatorParams value,
  ) async {
    params.add(value);
    return const Right(RideFareQuoteEntity(totalFare: 10));
  }
}

class ScreenRideRoom extends RideRoomController {
  FindRideParams? submitted;
  @override
  RideRoomState build() => const RideRoomState();
  @override
  Future<void> findRide(FindRideParams params) async {
    submitted = params;
  }
}

class ScreenCarpool extends CarpoolController {
  @override
  CarpoolState build() => const CarpoolState();
}

const saved = SavedLocationEntity(
  id: 'saved',
  name: 'Saved pickup',
  address: 'Saved address',
  city: '',
  state: '',
  country: '',
  lat: 28.6,
  lng: -81.5,
  order: 0,
  isDeleted: false,
);

class ScreenSavedLocations extends SavedLocationsNotifier {
  @override
  SavedLocationsState build() => const SavedLocationsState(locations: [saved]);
}

class FakeMaps extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox.expand();
}

void main() {
  final previousConfig = remoteConfigModel;
  final previousMaps = GoogleMapsFlutterPlatform.instance;
  late ScreenLocationService location;
  late FakeTransport transport;
  late ScreenFareUseCase fare;
  late ProviderContainer container;
  late List<Map<String, Object>> events;
  late TestRepository repository;
  GoRouter? router;

  setUp(() async {
    remoteConfigModel = previousConfig.copyWith(
      addressSearchV2Enabled: true,
      mapApiKey: 'test-only',
      serviceRegionId: 'global',
      useOsrmInDebug: true,
    );
    ServiceRegionConfig.setActiveByKey('global');
    GoogleMapsFlutterPlatform.instance = FakeMaps();
    SharedPreferences.setMockInitialValues({});
    transport = FakeTransport();
    events = [];
    location = ScreenLocationService(
      StorageService(await SharedPreferences.getInstance()),
      Dio()..httpClientAdapter = transport,
      events.add,
    );
    repository = TestRepository();
    fare = ScreenFareUseCase();
    locator.registerSingleton<LocationService>(location);
    locator.registerSingleton<GetRecentLocationsUseCase>(
      GetRecentLocationsUseCase(repository),
    );
    locator.registerSingleton<SaveRecentLocationUseCase>(
      SaveRecentLocationUseCase(repository),
    );
    locator.registerSingleton<CalculateFareUseCase>(fare);
    locator.registerSingleton<ApplyPromoCodeUseCase>(PromoUseCase());
    final routeDio = Dio()..httpClientAdapter = FakeRoutes();
    container = ProviderContainer(
      overrides: [
        mapProvider.overrideWith(() => ScreenMapProvider(routeDio)),
        rideRoomProvider.overrideWith(ScreenRideRoom.new),
        carpoolProvider.overrideWith(ScreenCarpool.new),
        savedLocationsProvider.overrideWith(ScreenSavedLocations.new),
      ],
    );
  });
  tearDown(() async {
    router?.dispose();
    router = null;
    container.dispose();
    await locator.reset();
    remoteConfigModel = previousConfig;
    GoogleMapsFlutterPlatform.instance = previousMaps;
  });

  Future<void> readyMap(WidgetTester tester) async {
    await tester.runAsync(() async {
      await container.read(mapProvider.future);
    });
    await container.read(mapProvider.notifier).setSelectedRideType('economy');
    expect(location.reasons, ['initial_position']);
    location.reasons.clear();
    location.freshLookups = 0;
  }

  Future<void> show(
    WidgetTester tester,
    Widget widget, {
    bool canPop = false,
  }) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await flushReview(tester);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final oldRouter = router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => canPop ? const Scaffold() : widget,
        ),
        if (canPop) GoRoute(path: '/picker', builder: (_, _) => widget),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await flushReview(tester);
    oldRouter?.dispose();
    if (canPop) {
      unawaited(router!.push('/picker'));
      await tester.pump(const Duration(milliseconds: 350));
      await flushReview(tester);
    }
  }

  Future<void> search(
    WidgetTester tester, {
    int field = 0,
    int index = 0,
    String id = 'one',
  }) async {
    await tester.enterText(find.byType(TextField).at(field), 'sample $id');
    await tester.pump(const Duration(milliseconds: 400));
    await flushReview(tester);
    transport.respond(index, predictions(id));
    await flushReview(tester);
  }

  Future<void> select(
    WidgetTester tester, {
    int index = 1,
    String id = 'one',
    double lat = 28.6,
    String city = 'Sample Town',
  }) async {
    await tester.tap(find.text('Sample business'));
    await flushReview(tester);
    final data = details(id, latitude: lat)
      ..['location'] = {'latitude': lat, 'longitude': -81.5};
    (data['addressComponents'] as List).insert(0, {
      'longText': city,
      'types': ['locality'],
    });
    transport.respond(index, data);
    await flushReview(tester);
  }

  Future<void> expectRideCity(WidgetTester tester, String city) async {
    final map = container.read(mapProvider.notifier);
    if (container.read(mapProvider).value!.dropOff == null) {
      await tester.runAsync(
        () => map.setDropOffLocation(
          const LatLng(28.8, -81.8),
          name: 'Dropoff',
          resolveNameIfMissing: false,
        ),
      );
    }
    expect(fare.params.last.pickupCity, city);
    await show(tester, const Scaffold(body: SelectRideSheet()));
    final findRide = find.text('Find Ride');
    await tester.ensureVisible(findRide);
    await tester.pumpAndSettle();
    await tester.tap(findRide);
    await flushReview(tester);
    final params =
        (container.read(rideRoomProvider.notifier) as ScreenRideRoom).submitted;
    expect(params, isNotNull);
    expect(params!.pickupCity, city);
    expect(params.toJson()['pickupCity'], city);
    await tester.pumpWidget(const SizedBox());
    await flushReview(tester);
  }

  testWidgets(
    'EnterRouteScreen disposal abandons interaction and cleans up without ref access',
    (tester) async {
      await readyMap(tester);
      await show(
        tester,
        const EnterRouteScreen(purpose: RideLocationType.pickup),
      );
      await search(tester);
      await tester.pumpWidget(const SizedBox());
      await flushReview(tester);
      expect(tester.takeException(), isNull);
      expect(
        events.where((e) => e['event'] == 'interaction_abandoned'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'v2 pickup reaches fare and find ride with city and zero reverse geocodes',
    (tester) async {
      await readyMap(tester);
      await show(
        tester,
        const EnterRouteScreen(purpose: RideLocationType.pickup),
      );
      await search(tester);
      await select(tester);
      expect(transport.requests, hasLength(2));
      expect(location.reasons, isEmpty);
      await expectRideCity(tester, 'Sample Town');
      expect(location.reasons, isEmpty);
    },
  );

  testWidgets(
    'saved pickup fills city through documented fallback and reaches fare and find ride',
    (tester) async {
      await readyMap(tester);
      await show(
        tester,
        const EnterRouteScreen(purpose: RideLocationType.pickup),
      );
      await tester.tap(find.text('Saved pickup'));
      await flushReview(tester);
      expect(location.reasons, ['pickup_city_fallback']);
      expect(transport.requests, isEmpty);
      await expectRideCity(tester, 'Fallback City');
    },
  );

  testWidgets(
    'swap moves both complete resolved locations and city without address requests',
    (tester) async {
      await readyMap(tester);
      await show(
        tester,
        const EnterRouteScreen(purpose: RideLocationType.pickup),
      );
      await search(tester);
      await select(tester, city: 'First City');
      await search(tester, field: 1, index: 2, id: 'two');
      await select(tester, index: 3, id: 'two', lat: 28.9, city: 'Second City');
      final before = container.read(mapProvider).value!;
      await tester.tap(find.byTooltip('Swap locations'));
      await flushReview(tester);
      final after = container.read(mapProvider).value!;
      expect(after.pickup!.resolvedPlace, same(before.dropOff!.resolvedPlace));
      expect(after.dropOff!.resolvedPlace, same(before.pickup!.resolvedPlace));
      expect(after.pickup!.city, 'Second City');
      expect(after.dropOff!.city, 'First City');
      expect(transport.requests, hasLength(4));
      expect(location.reasons, isEmpty);
      await expectRideCity(tester, 'Second City');
    },
  );

  testWidgets(
    'typing keeps promo while invalidating pickup; selection shows removal warning',
    (tester) async {
      await readyMap(tester);
      // Apply the same state fields populated by the promo API, using the real map notifier.
      final notifier = container.read(mapProvider.notifier);
      (notifier as ScreenMapProvider).seedPromo();
      await show(
        tester,
        const EnterRouteScreen(purpose: RideLocationType.pickup),
      );
      await tester.enterText(find.byType(TextField).first, 'a');
      await flushReview(tester);
      expect(container.read(mapProvider).value!.pickup, isNull);
      expect(container.read(mapProvider).value!.hasAppliedPromoCode, isTrue);
      await tester.tap(find.text('Confirm Route'));
      await flushReview(tester);
      expect(
        container.read(rideRoomProvider).currentSheet,
        RideSheetsType.whereToGoSheet,
      );
      await search(tester);
      await select(tester);
      expect(
        find.text('Changing this will remove your applied promo code.'),
        findsOneWidget,
      );
      expect(container.read(mapProvider).value!.hasAppliedPromoCode, isTrue);
      await tester.tap(find.text('OK'));
      await flushReview(tester);
      expect(container.read(mapProvider).value!.hasAppliedPromoCode, isFalse);
      expect(container.read(mapProvider).value!.pickup, isNotNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'screen double tap resolves once and edited text rejects pending Details',
    (tester) async {
      await readyMap(tester);
      await show(
        tester,
        const EnterRouteScreen(purpose: RideLocationType.pickup),
      );
      await search(tester);
      await tester.tap(find.text('Sample business'));
      await tester.tap(find.text('Sample business'));
      await flushReview(tester);
      expect(transport.requests, hasLength(2));
      await tester.enterText(find.byType(TextField).first, 'changed');
      transport.respond(1, details('one', latitude: 28.6));
      await flushReview(tester);
      expect(container.read(mapProvider).value!.pickup, isNull);
      expect(repository.saved, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'changed',
      );
      await tester.pumpWidget(const SizedBox());
      await flushReview(tester);
    },
  );

  testWidgets(
    'flag-off ride uses 1 character, 300ms, fresh origin, legacy Details and pickup city fallback',
    (tester) async {
      remoteConfigModel = remoteConfigModel.copyWith(
        addressSearchV2Enabled: false,
      );
      await readyMap(tester);
      container.read(mapProvider.notifier).clearPickupLocation();
      await show(
        tester,
        const EnterRouteScreen(purpose: RideLocationType.pickup),
      );
      await tester.enterText(find.byType(TextField).first, 'a');
      await tester.pump(const Duration(milliseconds: 299));
      expect(location.legacyQueries, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await flushReview(tester);
      expect(location.legacyQueries, ['a']);
      expect(location.freshLookups, 1);
      await tester.tap(find.text('Legacy'));
      await flushReview(tester);
      expect(location.legacyDetails, 1);
      expect(location.reasons, ['pickup_city_fallback']);
      expect(transport.requests, isEmpty);
      await expectRideCity(tester, 'Fallback City');
    },
  );

  testWidgets(
    'legacy profile typing does not clear metadata or write the parent field',
    (tester) async {
      remoteConfigModel = remoteConfigModel.copyWith(
        addressSearchV2Enabled: false,
      );
      final text = TextEditingController(text: 'Confirmed address');
      var clears = 0, callbacks = 0;
      await show(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: AddressSearchField(
              controller: text,
              locationService: location,
              onAddressCleared: () => clears++,
              onDetailsFetched: (_) => callbacks++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Confirmed address'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 400));
      await flushReview(tester);
      expect(clears, 0);
      expect(text.text, 'Confirmed address');
      expect(location.freshLookups, 0);
      expect(location.legacyQueries, ['a']);
      await tester.tap(find.text('Legacy address'));
      await flushReview(tester);
      expect(location.profileDetails, 1);
      expect(location.legacyDetails, 0);
      expect(callbacks, 1);
      await tester.pumpWidget(const SizedBox());
      text.dispose();
      await flushReview(tester);
    },
  );

  testWidgets(
    'flag-off picker keeps one-character search, 300ms and legacy resolution counts',
    (tester) async {
      remoteConfigModel = remoteConfigModel.copyWith(
        addressSearchV2Enabled: false,
      );
      await show(tester, const PlacePickerScreen(), canPop: true);
      await tester.pump(const Duration(milliseconds: 400));
      await flushReview(tester);
      expect(location.freshLookups, 1);
      expect(location.reasons, ['initial_position']);
      location.reasons.clear();
      await tester.enterText(find.byType(TextField).first, 'a');
      await tester.pump(const Duration(milliseconds: 299));
      expect(location.legacyQueries, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await flushReview(tester);
      expect(location.legacyQueries, ['a']);
      await tester.tap(find.text('Legacy address'));
      await flushReview(tester);
      expect(location.legacyDetails, 1);
      expect(location.reasons, ['legacy_selection_fallback']);
      expect(transport.requests, isEmpty);
    },
  );

  testWidgets(
    'flag-off dropoff keeps one legacy Details and no extra name lookup',
    (tester) async {
      remoteConfigModel = remoteConfigModel.copyWith(
        addressSearchV2Enabled: false,
      );
      await readyMap(tester);
      await show(tester, const EnterRouteScreen());
      await tester.enterText(find.byType(TextField).at(1), 'a');
      await tester.pump(const Duration(milliseconds: 300));
      await flushReview(tester);
      await tester.tap(find.text('Legacy'));
      await flushReview(tester);
      expect(location.legacyQueries, ['a']);
      expect(location.legacyDetails, 1);
      expect(location.reasons, isEmpty);
      expect(transport.requests, isEmpty);
    },
  );
  testWidgets(
    'flag-off ride picker confirm retains the legacy coordinate lookup',
    (tester) async {
      remoteConfigModel = remoteConfigModel.copyWith(
        addressSearchV2Enabled: false,
      );
      await readyMap(tester);
      await show(
        tester,
        const RidePlacePickerScreen(
          args: RidePlacePickerArgs(purpose: RideLocationType.pickup),
        ),
        canPop: true,
      );
      await tester.pump(const Duration(milliseconds: 400));
      await flushReview(tester);
      location.reasons.clear();
      final picker = container.read(placePickerProvider.notifier);
      picker.onMapGestureStarted();
      picker.onCameraMove(const LatLng(28.7, -81.6));
      picker.onCameraIdle();
      await flushReview(tester);
      await tester.tap(find.text('Confirm Pickup'));
      await flushReview(tester);
      expect(location.reasons, ['manual_pin', 'pickup_city_fallback']);
      expect(transport.requests, isEmpty);
      expect(container.read(mapProvider).value!.pickup!.city, 'Fallback City');
    },
  );

  for (final manual in [false, true]) {
    testWidgets(
      'picker confirm ${manual ? 'manual pin' : 'search selection'} preserves resolved data and lookup counts',
      (tester) async {
        await readyMap(tester);
        await show(
          tester,
          manual
              ? const RidePlacePickerScreen(
                  args: RidePlacePickerArgs(purpose: RideLocationType.pickup),
                )
              : const PlacePickerScreen(),
          canPop: true,
        );
        await tester.pump(const Duration(milliseconds: 400));
        await flushReview(tester);
        location.reasons.clear();
        final picker = container.read(placePickerProvider.notifier);
        if (manual) {
          picker.onMapGestureStarted();
          picker.onCameraMove(const LatLng(28.7, -81.6));
          picker.onCameraIdle();
          await tester.pump(const Duration(milliseconds: 400));
          await flushReview(tester);
        } else {
          await tester.enterText(find.byType(TextField).first, 'sample');
          await tester.pump(const Duration(milliseconds: 400));
          await flushReview(tester);
          transport.respond(0, predictions('one'));
          await flushReview(tester);
          await tester.tap(find.text('Sample business, sample street'));
          await flushReview(tester);
          final data = details('one', latitude: 28.6)
            ..['location'] = {'latitude': 28.6, 'longitude': -81.5};
          transport.respond(1, data);
          await flushReview(tester);
          picker.onCameraIdle();
          await tester.pump(const Duration(milliseconds: 500));
          await show(
            tester,
            RidePlacePickerScreen(
              args: RidePlacePickerArgs(
                purpose: RideLocationType.pickup,
                initialAddress: container
                    .read(placePickerProvider)
                    .selectedAddress,
              ),
            ),
            canPop: true,
          );
        }
        await tester.tap(find.text('Confirm Pickup'));
        await flushReview(tester);
        expect(location.reasons, manual ? ['manual_pin'] : isEmpty);
        expect(transport.requests, hasLength(manual ? 0 : 2));
        final city = manual ? 'Manual City' : 'Sample Town';
        expect(container.read(mapProvider).value!.pickup!.city, city);
        if (!manual) {
          expect(
            container.read(mapProvider).value!.pickup!.resolvedPlace,
            isNotNull,
          );
        }
        await expectRideCity(tester, city);
        expect(location.reasons, manual ? ['manual_pin'] : isEmpty);
      },
    );
  }
}
