import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

enum SavedLocationsStatus { initial, loading, success, error }

class SavedLocationsState {
  static const Object _keepError = Object();

  final SavedLocationsStatus status;
  final List<SavedLocationEntity> locations;
  final Pagination? pagination;
  final String? errorMessage;
  final bool isSaving;
  final bool isDeleting;
  final bool isReordering;
  final bool hasReachedEnd;
  final int currentPage;

  const SavedLocationsState({
    this.status = SavedLocationsStatus.initial,
    this.locations = const <SavedLocationEntity>[],
    this.pagination,
    this.errorMessage,
    this.isSaving = false,
    this.isDeleting = false,
    this.isReordering = false,
    this.hasReachedEnd = false,
    this.currentPage = 1,
  });

  SavedLocationsState copyWith({
    SavedLocationsStatus? status,
    List<SavedLocationEntity>? locations,
    Pagination? pagination,
    Object? errorMessage = _keepError,
    bool? isSaving,
    bool? isDeleting,
    bool? isReordering,
    bool? hasReachedEnd,
    int? currentPage,
  }) {
    return SavedLocationsState(
      status: status ?? this.status,
      locations: locations ?? this.locations,
      pagination: pagination ?? this.pagination,
      errorMessage: errorMessage == _keepError
          ? this.errorMessage
          : errorMessage as String?,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      isReordering: isReordering ?? this.isReordering,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}
