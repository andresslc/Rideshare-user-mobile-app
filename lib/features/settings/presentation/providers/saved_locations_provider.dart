import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/params/location_params.dart';
import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';
import 'package:ride_app/features/settings/domain/usecases/delete_location_usecase.dart';
import 'package:ride_app/features/settings/domain/usecases/get_saved_locations_usecase.dart';
import 'package:ride_app/features/settings/domain/usecases/reorder_saved_locations_usecase.dart';
import 'package:ride_app/features/settings/domain/usecases/save_location_usecase.dart';
import 'package:ride_app/features/settings/domain/usecases/update_location_usecase.dart';
import 'package:ride_app/features/settings/presentation/states/saved_locations_state.dart';

final savedLocationsProvider =
    NotifierProvider.autoDispose<SavedLocationsNotifier, SavedLocationsState>(
  SavedLocationsNotifier.new,
);

class SavedLocationsNotifier extends Notifier<SavedLocationsState> {
  late GetSavedLocationsUseCase _getSavedLocationsUseCase;
  late SaveLocationUseCase _saveLocationUseCase;
  late UpdateLocationUseCase _updateLocationUseCase;
  late DeleteLocationUseCase _deleteLocationUseCase;
  late ReorderSavedLocationsUseCase _reorderSavedLocationsUseCase;

  @override
  SavedLocationsState build() {
    _getSavedLocationsUseCase = locator<GetSavedLocationsUseCase>();
    _saveLocationUseCase = locator<SaveLocationUseCase>();
    _updateLocationUseCase = locator<UpdateLocationUseCase>();
    _deleteLocationUseCase = locator<DeleteLocationUseCase>();
    _reorderSavedLocationsUseCase = locator<ReorderSavedLocationsUseCase>();
    return const SavedLocationsState();
  }

  Future<void> fetchSavedLocations({bool refresh = true}) async {
    if (state.status == SavedLocationsStatus.loading) return;
    if (!refresh && state.hasReachedEnd) return;

    final nextPage = refresh ? 1 : state.currentPage + 1;
    state = state.copyWith(
      status: SavedLocationsStatus.loading,
      errorMessage: null,
      hasReachedEnd: refresh ? false : state.hasReachedEnd,
    );

    final result = await _getSavedLocationsUseCase(page: nextPage);
    if (!ref.mounted) return;
    result.fold(
      (failure) {
        state = state.copyWith(
          status: SavedLocationsStatus.error,
          errorMessage: failure.message,
        );
      },
      (response) {
        final (locations, pagination) = response;
        final reachedEnd =
            (pagination?.currentPage ?? 1) >= (pagination?.totalPages ?? 1);
        state = state.copyWith(
          status: SavedLocationsStatus.success,
          locations: refresh
              ? locations
              : <SavedLocationEntity>[
                  ...state.locations,
                  ...locations,
                ],
          pagination: pagination,
          currentPage: pagination?.currentPage?.toInt() ?? nextPage,
          hasReachedEnd: reachedEnd,
          errorMessage: null,
        );
      },
    );
  }

  Future<bool> saveLocation(SaveLocationParams params) async {
    if (state.isSaving) return false;

    final name = params.name.trim();
    final address = params.address.trim();
    if (name.isEmpty || address.isEmpty) {
      state = state.copyWith(errorMessage: 'Name and location are required');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    final result = await _saveLocationUseCase(
      SaveLocationParams(
        name: name,
        address: address,
        country: params.country.trim(),
        city: params.city.trim(),
        state: params.state.trim(),
        lat: params.lat,
        lng: params.lng,
      ),
    );
    if (!ref.mounted) return false;

    return result.fold((failure) {
      state = state.copyWith(isSaving: false, errorMessage: failure.message);
      return false;
    }, (location) {
      final updated = <SavedLocationEntity>[...state.locations, location]
        ..sort((a, b) => a.order.compareTo(b.order));
      state = state.copyWith(
        status: SavedLocationsStatus.success,
        locations: updated,
        isSaving: false,
        errorMessage: null,
      );
      return true;
    });
  }

  Future<bool> updateLocation({
    required String locationId,
    required SaveLocationParams params,
  }) async {
    if (state.isSaving) return false;

    final name = params.name.trim();
    final address = params.address.trim();
    if (locationId.trim().isEmpty || name.isEmpty || address.isEmpty) {
      state = state.copyWith(errorMessage: 'Invalid location data');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    final result = await _updateLocationUseCase(
      locationId,
      SaveLocationParams(
        name: name,
        address: address,
        country: params.country.trim(),
        city: params.city.trim(),
        state: params.state.trim(),
        lat: params.lat,
        lng: params.lng,
      ),
    );
    if (!ref.mounted) return false;

    return result.fold((failure) {
      state = state.copyWith(isSaving: false, errorMessage: failure.message);
      return false;
    }, (updatedLocation) {
      final updatedList = state.locations.map((location) {
        if (location.id == locationId) {
          return updatedLocation;
        }
        return location;
      }).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      state = state.copyWith(
        status: SavedLocationsStatus.success,
        locations: updatedList,
        isSaving: false,
        errorMessage: null,
      );
      return true;
    });
  }

  Future<bool> deleteLocation(String locationId) async {
    if (state.isDeleting) return false;
    if (locationId.trim().isEmpty) return false;

    final exists = state.locations.any((location) => location.id == locationId);
    if (!exists) return false;

    state = state.copyWith(isDeleting: true, errorMessage: null);
    final result = await _deleteLocationUseCase(locationId);
    if (!ref.mounted) return false;

    return result.fold((failure) {
      state = state.copyWith(isDeleting: false, errorMessage: failure.message);
      return false;
    }, (_) {
      final updated = state.locations
          .where((location) => location.id != locationId)
          .toList();
      state = state.copyWith(
        status: SavedLocationsStatus.success,
        locations: _assignSequentialOrder(updated),
        isDeleting: false,
        errorMessage: null,
      );
      return true;
    });
  }

  Future<bool> reorderLocation(int oldIndex, int newIndex) async {
    if (state.isReordering || state.locations.length < 2) return false;
    if (oldIndex < 0 || oldIndex >= state.locations.length) return false;
    if (newIndex < 0 || newIndex > state.locations.length) return false;

    var updatedNewIndex = newIndex;
    if (updatedNewIndex > oldIndex) {
      updatedNewIndex -= 1;
    }
    if (updatedNewIndex == oldIndex) return false;

    final previous = <SavedLocationEntity>[...state.locations];
    final reordered = <SavedLocationEntity>[...state.locations];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(updatedNewIndex, moved);

    state = state.copyWith(
      locations: _assignSequentialOrder(reordered),
      isReordering: true,
      errorMessage: null,
    );

    final ids = reordered.map((location) => location.id).toList();
    final result = await _reorderSavedLocationsUseCase(ids);
    if (!ref.mounted) return false;

    return result.fold((failure) {
      state = state.copyWith(
        locations: previous,
        isReordering: false,
        errorMessage: failure.message,
      );
      return false;
    }, (_) {
      state = state.copyWith(
        locations: _assignSequentialOrder(reordered),
        isReordering: false,
        errorMessage: null,
      );
      return true;
    });
  }

  List<SavedLocationEntity> _assignSequentialOrder(
    List<SavedLocationEntity> locations,
  ) {
    return List<SavedLocationEntity>.generate(locations.length, (index) {
      return locations[index].copyWith(order: index + 1);
    });
  }
}
