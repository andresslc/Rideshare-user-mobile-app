import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/services/location_service.dart';
import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/get_recent_locations_use_case.dart';
import 'package:ride_app/features/ride_room/domain/use_cases/save_recent_location_use_case.dart';
import 'package:ride_app/features/ride_room/presentation/states/enter_route_state.dart';

import '../../../../core/services/address_search_controller.dart';
import '../../../../core/services/places_search_service.dart';

final enterRouteProvider =
    NotifierProvider<EnterRouteNotifier, EnterRouteState>(
      EnterRouteNotifier.new,
    );

class EnterRouteNotifier extends Notifier<EnterRouteState> {
  late GetRecentLocationsUseCase _getRecentLocationsUseCase;
  late SaveRecentLocationUseCase _saveRecentLocationUseCase;
  // late GetPopularLocationsUseCase _getPopularLocationsUseCase;
  late LocationService _locationService;
  late AddressSearchController _search;
  RideLocationType _activeType = RideLocationType.dropoff;
  ResolvedPlace? lastResolvedPlace;

  LatLng? _searchOrigin;

  @override
  EnterRouteState build() {
    _getRecentLocationsUseCase = locator<GetRecentLocationsUseCase>();
    _saveRecentLocationUseCase = locator<SaveRecentLocationUseCase>();
    // _getPopularLocationsUseCase = locator<GetPopularLocationsUseCase>();
    _locationService = locator<LocationService>();
    _search = _locationService.createAddressSearch(
      origin: () => _searchOrigin,
      onLegacyOriginResolved: (value) => _searchOrigin = value,
      onChanged: () {
        if (!ref.mounted) return;
        state = state.copyWith(
          searchResults: _search.suggestions,
          isFetchingSuggestions: _search.loading,
          isResolvingSelection: _search.selecting,
          searchError: _search.error,
          clearError: _search.error == null,
        );
      },
    );
    ref.onDispose(_search.dispose);
    return const EnterRouteState();
  }

  Future<void> initialize({LatLng? initialOrigin}) async {
    _search.abandon();
    _searchOrigin = initialOrigin;
    state = state.copyWith(
      isLoading: true,
      searchQuery: '',
      searchResults: const [],
      clearError: true,
    );
    try {
      final recents = await _getRecentLocationsUseCase();
      if (!ref.mounted) return;
      if (recents.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          recents: recents,
          popularLocations: const [],
          searchQuery: '',
          searchResults: const [],
        );
        return;
      } else {
        state = state.copyWith(
          isLoading: false,
          recents: const [],
          searchQuery: '',
          searchResults: const [],
        );
      }
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        searchQuery: '',
        searchResults: const [],
        errorMessage: 'Unable to load route locations',
      );
    }
  }

  Future<void> saveFromSelection({
    required String fullAddress,
    required double latitude,
    required double longitude,
    required RideLocationType type,
  }) async {
    final trimmedAddress = fullAddress.trim();
    if (trimmedAddress.isEmpty) return;

    final name = _extractName(trimmedAddress);
    final location = LocationEntity(
      id: _createId(trimmedAddress, latitude, longitude),
      name: name,
      address: trimmedAddress,
      latitude: latitude,
      longitude: longitude,
      type: type,
      timestamp: DateTime.now(),
    );

    await _saveRecentLocationUseCase(location);
    await _refreshRecents();
  }

  Future<void> saveFromListItem({
    required Object location,
    required RideLocationType type,
  }) async {
    final updated = await _resolveSelectedLocation(location, type: type);
    if (updated == null) return;

    await _saveRecentLocationUseCase(updated);
    await _refreshRecents();
  }

  Future<LocationEntity?> resolveSelectedLocation({
    required Object location,
    required RideLocationType type,
  }) {
    return _resolveSelectedLocation(location, type: type);
  }

  void setSearchOrigin(LatLng? origin) {
    _searchOrigin = origin;
  }

  void activateField(RideLocationType type) {
    if (_activeType == type) return;
    _activeType = type;
    abandonSearch();
  }

  void abandonSearch({bool notify = true}) {
    _search.abandon(notify: notify);
    // Screen disposal retires requests without notifying a tree being unmounted.
    // Initialization clears the visible state when the screen opens again.
    if (!notify || !ref.mounted) return;
    state = state.copyWith(searchQuery: '', searchResults: const []);
  }

  void onSearchQueryChanged(
    String query, {
    LatLng? origin,
    RideLocationType type = RideLocationType.dropoff,
  }) {
    activateField(type);
    if (origin != null) _searchOrigin = origin;
    state = state.copyWith(searchQuery: query.trim());
    _search.edit(query, field: 'ride.${type.name}');
  }

  Future<LocationEntity?> retrySelection({
    required RideLocationType type,
  }) async {
    if (!_search.canRetrySelection) {
      _search.retrySearch();
      return null;
    }
    final place = await _search.retrySelection();
    if (place == null || !ref.mounted || type != _activeType) return null;
    return _fromResolved(place, type);
  }

  LocationEntity _fromResolved(ResolvedPlace place, RideLocationType type) {
    lastResolvedPlace = place;
    return LocationEntity(
      id: place.placeId,
      name: place.label.split(',').first,
      address: place.formattedAddress,
      latitude: place.latitude,
      longitude: place.longitude,
      type: type,
      timestamp: DateTime.now(),
      resolvedPlace: place,
    );
  }

  Future<void> _refreshRecents() async {
    final recents = await _getRecentLocationsUseCase();
    state = state.copyWith(recents: recents);
  }

  String _extractName(String address) {
    return address.split(',').first.trim();
  }

  Future<LocationEntity?> _resolveSelectedLocation(
    Object location, {
    required RideLocationType type,
  }) async {
    LocationEntity? resolved;
    if (location is PlaceSuggestion) {
      if (_activeType != type) return null;
      final place = await _search.select(location);
      if (place == null || !ref.mounted || _activeType != type) return null;
      resolved = _fromResolved(place, type);
    } else if (location is LocationEntity) {
      abandonSearch();
      resolved = location;
    }
    if (resolved == null ||
        !ResolvedPlace.validCoordinates(
          resolved.latitude,
          resolved.longitude,
        )) {
      return null;
    }
    return resolved.copyWith(
      id: _createId(resolved.address, resolved.latitude, resolved.longitude),
      type: type,
      timestamp: DateTime.now(),
    );
  }

  String _createId(String address, double lat, double lng) {
    final normalized = address.toLowerCase().trim();
    return (normalized.hashCode ^ lat.hashCode ^ lng.hashCode).abs().toString();
  }
}
