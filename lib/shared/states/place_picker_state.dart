import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/location/service_region.dart';
import 'package:ride_app/shared/models/selected_location.dart';

import '../../core/services/places_search_service.dart';

class PlacePickerState {
  final PlacesFailure? searchError;
  final LatLng currentPosition;
  final String address;
  final String mapStyle;
  final bool isFetchingAddress;
  final bool isFetchingSuggestions;
  final List<Map<String, dynamic>> suggestions;
  final Address selectedAddress;
  final String? regionErrorMessage;

  PlacePickerState({
    this.searchError,
    required this.currentPosition,
    required this.address,
    required this.mapStyle,
    required this.isFetchingAddress,
    required this.isFetchingSuggestions,
    required this.suggestions,
    required this.selectedAddress,
    this.regionErrorMessage,
  });

  factory PlacePickerState.initial() {
    return PlacePickerState(
      currentPosition: ServiceRegionConfig.active.center,
      address: 'Select a location',
      mapStyle: '',
      isFetchingAddress: false,
      isFetchingSuggestions: false,
      suggestions: [],
      selectedAddress: Address.idle(),
      regionErrorMessage: null,
    );
  }

  PlacePickerState copyWith({
    PlacesFailure? searchError,
    bool clearSearchError = false,
    LatLng? currentPosition,
    String? address,
    String? mapStyle,
    bool? isFetchingAddress,
    bool? isFetchingSuggestions,
    List<Map<String, dynamic>>? suggestions,
    Address? selectedAddress,
    String? regionErrorMessage,
    bool clearRegionErrorMessage = false,
  }) {
    return PlacePickerState(
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      currentPosition: currentPosition ?? this.currentPosition,
      address: address ?? this.address,
      mapStyle: mapStyle ?? this.mapStyle,
      isFetchingAddress: isFetchingAddress ?? this.isFetchingAddress,
      isFetchingSuggestions:
          isFetchingSuggestions ?? this.isFetchingSuggestions,
      suggestions: suggestions ?? this.suggestions,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      regionErrorMessage: clearRegionErrorMessage
          ? null
          : (regionErrorMessage ?? this.regionErrorMessage),
    );
  }
}
