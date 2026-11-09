import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';

import '../../../../core/services/places_search_service.dart';

class EnterRouteState {
  final bool isLoading;
  final bool isFetchingSuggestions, isResolvingSelection;
  final PlacesFailure? searchError;
  final List<LocationEntity> recents;
  final List<LocationEntity> popularLocations;
  final String searchQuery;
  final List<PlaceSuggestion> searchResults;
  final String? errorMessage;

  const EnterRouteState({
    this.isLoading = false,
    this.isFetchingSuggestions = false,
    this.isResolvingSelection = false,
    this.searchError,
    this.recents = const [],
    this.popularLocations = const [],
    this.searchQuery = '',
    this.searchResults = const [],
    this.errorMessage,
  });

  bool get hasRecent => recents.isNotEmpty;
  bool get isSearching => searchQuery.trim().isNotEmpty;

  List<Object> get listToRender =>
      isSearching ? searchResults : (hasRecent ? recents : popularLocations);

  EnterRouteState copyWith({
    bool? isLoading,
    bool? isFetchingSuggestions,
    bool? isResolvingSelection,
    PlacesFailure? searchError,
    List<LocationEntity>? recents,
    List<LocationEntity>? popularLocations,
    String? searchQuery,
    List<PlaceSuggestion>? searchResults,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EnterRouteState(
      isLoading: isLoading ?? this.isLoading,
      isFetchingSuggestions:
          isFetchingSuggestions ?? this.isFetchingSuggestions,
      isResolvingSelection: isResolvingSelection ?? this.isResolvingSelection,
      searchError: clearError ? null : (searchError ?? this.searchError),
      recents: recents ?? this.recents,
      popularLocations: popularLocations ?? this.popularLocations,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
