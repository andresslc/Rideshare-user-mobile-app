import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/services/location_service.dart';
import 'package:ride_app/shared/models/selected_location.dart';

import '../../core/services/address_search_controller.dart';
import '../../core/services/places_search_service.dart';
import '../states/place_picker_state.dart';

class PlacePickerNotifier extends StateNotifier<PlacePickerState> {
  final LocationService _locationService;
  late AddressSearchController _search;
  Timer? _pinDebounce;
  int _pinGeneration = 0;
  LatLng? _programmaticTarget;
  DateTime? _programmaticDeadline;
  LatLng? _pendingPin;
  LatLng? _searchOrigin;

  PlacePickerNotifier(this._locationService)
    : super(PlacePickerState.initial()) {
    _search = _locationService.createAddressSearch(
      origin: () => _searchOrigin,
      onLegacyOriginResolved: (value) => _searchOrigin = value,
      onChanged: () {
        if (!mounted) return;
        state = state.copyWith(
          suggestions: _search.suggestions.map((s) => s.toUiMap()).toList(),
          isFetchingSuggestions: _search.loading,
          isFetchingAddress: _search.selecting,
          searchError: _search.error,
          clearSearchError: _search.error == null,
        );
      },
    );
  }

  Future<void> setMapStyle(Brightness brightness) async {
    if (!mounted) return;
    final assetPath = brightness == Brightness.dark
        ? 'assets/map_style/dark_map.json'
        : 'assets/map_style/light_map.json';

    try {
      final mapStyle = await rootBundle.loadString(assetPath);
      if (!mounted) return;
      state = state.copyWith(mapStyle: mapStyle);
    } catch (e) {
      log('Error loading map style: $e', name: 'PlacePickerNotifier');
    }
  }

  Future<LatLng?> setInitialLocation({
    Address? initialAddress,
    bool openSettingsIfNeeded = false,
  }) async {
    if (!mounted) return null;

    final Address? normalizedInitialAddress = _normalizedAddress(
      initialAddress,
    );
    if (normalizedInitialAddress != null) {
      if (_search.enabled &&
          !_locationService.activeRegion.contains(
            LatLng(
              normalizedInitialAddress.latitiude,
              normalizedInitialAddress.longitude,
            ),
          )) {
        state = state.copyWith(regionErrorMessage: _outsideRegionMessage());
        return null;
      }
      final LatLng latLng = _clampToActiveRegion(
        LatLng(
          normalizedInitialAddress.latitiude,
          normalizedInitialAddress.longitude,
        ),
      );
      _searchOrigin ??= latLng;
      state = state.copyWith(
        currentPosition: latLng,
        address: normalizedInitialAddress.formattedAddress,
        selectedAddress: normalizedInitialAddress.copyWith(
          latitiude: latLng.latitude,
          longitude: latLng.longitude,
        ),
      );
      if (_search.enabled &&
          normalizedInitialAddress.formattedAddress.isNotEmpty &&
          normalizedInitialAddress.city.isNotEmpty &&
          normalizedInitialAddress.state.isNotEmpty) {
        markProgrammaticMove(latLng);
        return latLng;
      }
      await _reverseGeocode(
        latLng,
        reason: 'initial_address_fallback',
        fallbackAddress: normalizedInitialAddress.copyWith(
          latitiude: latLng.latitude,
          longitude: latLng.longitude,
        ),
      );
      if (!mounted) return null;
      return latLng;
    }

    try {
      final position = await _locationService.getCurrentLocation();
      final LatLng deviceLatLng = LatLng(position.latitude, position.longitude);
      _searchOrigin = deviceLatLng;
      if (!_locationService.activeRegion.contains(deviceLatLng)) {
        if (openSettingsIfNeeded) {
          state = state.copyWith(regionErrorMessage: _outsideRegionMessage());
          return null;
        }

        final LatLng fallbackPosition = _clampToActiveRegion(
          state.currentPosition,
        );
        updatePosition(fallbackPosition, reason: 'initial_position');
        return fallbackPosition;
      }

      final LatLng latLng = deviceLatLng;
      updatePosition(latLng, reason: 'initial_position');
      return latLng;
    } catch (e) {
      if (openSettingsIfNeeded && e is LocationException) {
        if (e.message.contains('permanently denied')) {
          await _locationService.openLocationSettings();
        } else if (e.message.contains('services are disabled')) {
          await Geolocator.openLocationSettings();
        }
      }
      final LatLng fallbackPosition = _clampToActiveRegion(
        state.currentPosition,
      );
      await _reverseGeocode(fallbackPosition, reason: 'initial_position');
      if (!mounted) return null;
      return fallbackPosition;
    }
  }

  void setSearchOrigin(LatLng? origin) {
    _searchOrigin = origin;
  }

  void markProgrammaticMove(LatLng target) {
    _programmaticTarget = target;
    _programmaticDeadline = DateTime.now().add(const Duration(seconds: 3));
  }

  bool _samePoint(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < 0.00001 &&
      (a.longitude - b.longitude).abs() < 0.00001;

  void onMapGestureStarted() {
    if (!mounted) return;
    _programmaticTarget = null;
    _programmaticDeadline = null;
    _search.abandon();
    _pinGeneration++;
    _pinDebounce?.cancel();
    _pendingPin = null;
    state = state.copyWith(address: '', selectedAddress: Address.idle());
  }

  void onCameraIdle() =>
      updatePosition(state.currentPosition, reason: 'manual_pin');

  void updatePosition(
    LatLng position, {
    bool consumePendingFallback = true,
    required String reason,
  }) {
    if (!mounted) return;
    if (!_search.enabled) {
      final clamped = _clampToActiveRegion(position);
      state = state.copyWith(
        currentPosition: clamped,
        address: '',
        selectedAddress: Address.idle(),
        clearRegionErrorMessage: true,
      );
      _reverseGeocode(clamped, reason: reason);
      return;
    }
    final target = _programmaticTarget;
    if (target != null &&
        _programmaticDeadline!.isAfter(DateTime.now()) &&
        _samePoint(target, position)) {
      _programmaticTarget = null;
      return;
    }
    _programmaticTarget = null;
    final selected = state.selectedAddress;
    if (selected.formattedAddress.isNotEmpty &&
        _samePoint(LatLng(selected.latitiude, selected.longitude), position)) {
      return;
    }
    final clampedPosition = _clampToActiveRegion(position);
    if (_pendingPin != null && _samePoint(_pendingPin!, clampedPosition)) {
      return;
    }
    _search.abandon();
    _pinDebounce?.cancel();
    _pendingPin = clampedPosition;
    final generation = ++_pinGeneration;
    state = state.copyWith(
      currentPosition: clampedPosition,
      address: '',
      selectedAddress: Address.idle(),
      isFetchingAddress: true,
      clearRegionErrorMessage: true,
    );
    _pinDebounce = Timer(const Duration(milliseconds: 400), () async {
      await _reverseGeocode(
        clampedPosition,
        generation: generation,
        reason: reason,
      );
      if (generation == _pinGeneration) _pendingPin = null;
    });
  }

  void onCameraMove(LatLng position) {
    if (!mounted) return;
    state = state.copyWith(
      currentPosition: _clampToActiveRegion(position),
      clearRegionErrorMessage: true,
    );
  }

  void clearRegionErrorMessage() {
    if (!mounted) return;
    state = state.copyWith(clearRegionErrorMessage: true);
  }

  Future<void> _reverseGeocode(
    LatLng position, {
    Address? fallbackAddress,
    int? generation,
    required String reason,
  }) async {
    final requestGeneration = generation ?? ++_pinGeneration;
    if (!mounted) return;
    state = state.copyWith(isFetchingAddress: true);

    try {
      final response = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
        reason: reason,
      );

      if (!mounted || requestGeneration != _pinGeneration) return;

      if (response != null && (response['results'] as List).isNotEmpty) {
        final result = response['results'][0];
        final components = result['address_components'] as List;
        final formattedAddress = result['formatted_address'] as String;

        // String streetNumber = '';
        // String route = '';
        String city = '';
        String stateName = '';
        String country = '';
        String zipCode = '';
        String countryCode = '';

        for (var component in components) {
          final types = component['types'] as List;
          if (types.contains('street_number')) {
            // streetNumber = component['long_name'];
          } else if (types.contains('route')) {
            // route = component['long_name'];
          } else if (types.contains('locality')) {
            city = component['long_name'];
          } else if (types.contains('administrative_area_level_1')) {
            stateName = component['long_name'];
          } else if (types.contains('country')) {
            country = component['long_name'];
            countryCode = component['short_name'];
          } else if (types.contains('postal_code')) {
            zipCode = component['long_name'];
          }
        }

        // final streetAddress = streetNumber.isNotEmpty
        //     ? '$streetNumber $route'
        //     : route;

        final bestFormattedAddress =
            (fallbackAddress?.formattedAddress ?? '').trim().isNotEmpty
            ? fallbackAddress!.formattedAddress
            : formattedAddress;

        final address = Address(
          latitiude: position.latitude,
          longitude: position.longitude,

          city: city,
          state: stateName,
          country: country,
          zipCode: zipCode,
          countryCode: countryCode,
          formattedAddress: bestFormattedAddress,
        );

        state = state.copyWith(
          address: bestFormattedAddress,
          selectedAddress: address,
        );
      }
    } catch (e) {
      if (!mounted || requestGeneration != _pinGeneration) return;
      log('📍 Error in _reverseGeocode: $e', name: 'PlacePickerNotifier');
      state = state.copyWith(address: '', selectedAddress: Address.idle());
    } finally {
      if (mounted && requestGeneration == _pinGeneration) {
        state = state.copyWith(isFetchingAddress: false);
      }
    }
  }

  void searchPlaces(String query, {LatLng? origin}) {
    if (origin != null) _searchOrigin = origin;
    _pinGeneration++;
    _pinDebounce?.cancel();
    _pendingPin = null;
    if (_search.enabled)
      state = state.copyWith(address: '', selectedAddress: Address.idle());
    _search.edit(query, field: 'map_picker.address');
  }

  Future<LatLng?> selectSuggestion(Map<String, dynamic> suggestion) async {
    if (_search.selecting) return null;
    if (_search.enabled) {
      final prediction = suggestion['prediction'];
      if (prediction is! PlaceSuggestion) return null;
      _pinGeneration++;
      _pinDebounce?.cancel();
      _pendingPin = null;
      final place = await _search.select(prediction);
      if (!mounted || place == null) return null;
      return _applyResolved(place);
    }
    _search.abandon();
    final placeId = suggestion['place_id'] as String?;
    if (placeId == null) return null;

    // Hide the dropdown immediately.
    if (!mounted) return null;
    state = state.copyWith(suggestions: []);

    final position = await _locationService.getPlaceDetails(placeId);
    if (!mounted) return null;
    if (position == null) return null;

    final LatLng latLng = _clampToActiveRegion(
      LatLng(position.latitude, position.longitude),
    );

    // Optimistically reflect the user's tap in the UI so the bottom card
    // shows what they picked even before reverse geocoding finishes.
    final tappedAddress = Address(
      latitiude: latLng.latitude,
      longitude: latLng.longitude,
      country: '',
      state: '',
      city: '',
      zipCode: '',
      countryCode: '',
      formattedAddress: (suggestion['description'] ?? '').toString().trim(),
    );

    state = state.copyWith(
      currentPosition: latLng,
      address: '',
      selectedAddress: Address.idle(),
    );

    // Fetch full address details and update state when ready.
    await _reverseGeocode(
      latLng,
      fallbackAddress: tappedAddress,
      reason: 'legacy_selection_fallback',
    );
    if (!mounted) return null;
    return latLng;
  }

  LatLng _applyResolved(ResolvedPlace place) {
    final position = LatLng(place.latitude, place.longitude);
    final address = Address.fromResolvedPlace(place);
    markProgrammaticMove(position);
    state = state.copyWith(
      currentPosition: position,
      address: address.formattedAddress,
      selectedAddress: address,
      suggestions: [],
      isFetchingAddress: false,
    );
    return position;
  }

  Future<LatLng?> retrySelection() async {
    if (!_search.canRetrySelection) {
      _search.retrySearch();
      return null;
    }
    final place = await _search.retrySelection();
    return !mounted || place == null ? null : _applyResolved(place);
  }

  @override
  void dispose() {
    _search.dispose();
    _pinDebounce?.cancel();
    _pinGeneration++;
    super.dispose();
  }

  LatLng _clampToActiveRegion(LatLng position) {
    return _locationService.activeRegion.clamp(position);
  }

  Address? _normalizedAddress(Address? address) {
    if (address == null) return null;
    if (!ResolvedPlace.validCoordinates(address.latitiude, address.longitude) ||
        address.formattedAddress.isEmpty) {
      return null;
    }
    return address;
  }

  String _outsideRegionMessage() {
    final regionName = _locationService.activeRegion.displayName;
    return 'You are not in $regionName right now. Please choose a location within $regionName to continue.';
  }
}

final placePickerProvider =
    StateNotifierProvider.autoDispose<PlacePickerNotifier, PlacePickerState>((
      ref,
    ) {
      final locationService = locator<LocationService>();
      return PlacePickerNotifier(locationService);
    });
