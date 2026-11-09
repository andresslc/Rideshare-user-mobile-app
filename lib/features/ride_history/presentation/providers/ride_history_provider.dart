import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/params/carpool_detail_params.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/params/carpool_param.dart';
import '../../../../core/params/ride_history_detail_params.dart';
import '../../../../core/params/ride_history_param.dart';
import '../../domain/enitities/carpool_history_entities.dart';
import '../../domain/enitities/ride_history_entites.dart';
import '../../domain/use_case/carpool_history_detail_usecase.dart';
import '../../domain/use_case/carpool_history_usecase.dart';
import '../../domain/use_case/ride_history_detail_usecase.dart';
import '../../domain/use_case/ride_history_usecase.dart';
import '../states/ride_history_states.dart';

final completedRideProvider =
    NotifierProvider<RideHistoryController, RideHistoryStates>(
      RideHistoryController.new,
    );

final cancelledRideProvider =
    NotifierProvider<RideHistoryController, RideHistoryStates>(
      RideHistoryController.new,
    );
final rideDetailProvider =
    NotifierProvider<RideDetailController, RideHistoryStates>(
      RideDetailController.new,
    );

final carpoolRideHistoryProvider =
    NotifierProvider<CarpoolRideHistoryController, CarpoolRideHistoryStates>(
      CarpoolRideHistoryController.new,
    );

final carpoolDetailProvider =
    NotifierProvider<CarpoolDetailController, CarpoolDetailStates>(
      CarpoolDetailController.new,
    );

class RideHistoryController extends Notifier<RideHistoryStates> {
  GetRideHistoryUseCase get _useCase => locator<GetRideHistoryUseCase>();

  //  Pagination Variables
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  List<RideEntity> _rides = [];

  // Current filters
  String? _currentStatus;
  String? _currentCancelledBy;

  @override
  RideHistoryStates build() {
    return const RideHistoryInitial();
  }

  void resetState() {
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    _rides.clear();
    _currentStatus = null;
    _currentCancelledBy = null;

    state = const RideHistoryInitial();
  }

  /// ------------------------------
  /// FIRST PAGE LOAD
  /// ------------------------------
  Future<void> fetchRideHistory() async {
    await fetchRideHistoryWithFilters(null, null);
  }

  Future<void> fetchRideHistoryWithFilters(
    String? status,
    String? cancelledBy, {
    bool force = false,
  }) async {
    if (_currentStatus == status &&
        _currentCancelledBy == cancelledBy &&
        _rides.isNotEmpty &&
        !force) {
      return;
    }
    _currentStatus = status;
    _currentCancelledBy = cancelledBy;
    _currentPage = 1;
    _rides.clear();
    state = const RideHistoryLoading();

    final result = await _useCase(
      params: RideHistoryRequestParams(
        page: _currentPage,
        status: _currentStatus,
        cancelledBy: _currentCancelledBy,
      ),
    );

    result.fold((failure) => state = RideHistoryError(failure.message), (
      response,
    ) {
      _rides = response.rides;

      _hasMore =
          response.pagination.currentPage < response.pagination.totalPages;

      state = RidehistorySucces(rides: _rides, hasMore: _hasMore);
    });
  }

  /// ------------------------------
  /// LOAD MORE (Pagination)
  /// ------------------------------
  // Future<void> loadMore() async {
  //   if (!_hasMore || _isLoadingMore) return;

  //   _isLoadingMore = true;
  //   _currentPage++;

  //   final result = await _useCase(
  //     params: RideHistoryRequestParams(
  //       page: _currentPage,
  //       status: _currentStatus,
  //       cancelledBy: _currentCancelledBy,
  //     ),
  //   );

  //   result.fold((failure) {}, (response) {
  //     _rides.addAll(response.rides);

  //     _hasMore =
  //         response.pagination.currentPage < response.pagination.totalPages;

  //     state = RidehistorySucces(rides: _rides, hasMore: _hasMore);
  //   });

  //   _isLoadingMore = false;
  // }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    _currentPage++;

    final result = await _useCase(
      params: RideHistoryRequestParams(
        page: _currentPage,
        status: _currentStatus,
        cancelledBy: _currentCancelledBy,
      ),
    );

    result.fold((failure) {}, (response) {
      _rides.addAll(response.rides);

      _hasMore =
          response.pagination.currentPage < response.pagination.totalPages;

      state = RidehistorySucces(rides: _rides, hasMore: _hasMore);
    });

    _isLoadingMore = false;
  }
}

class RideDetailController extends Notifier<RideHistoryStates> {
  RideHistoryDetailUsecase get _ridedetail =>
      locator<RideHistoryDetailUsecase>();

  @override
  RideHistoryStates build() => const RideHistoryInitial();

  Future<void> fetchRideDetail(RideHistoryDetailParams params) async {
    state = const RideHistoryLoading();

    final result = await _ridedetail.call(params: params);

    result.fold(
      (failure) => state = RideHistoryError(failure.message),
      (response) => state = RideDetailSuccess(ride: response.ride),
    );
  }
}

class CarpoolDetailController extends Notifier<CarpoolDetailStates> {
  CarpoolHistoryDetailUsecase get _carpoolDetail =>
      locator<CarpoolHistoryDetailUsecase>();

  @override
  CarpoolDetailStates build() => const CarpoolDetailInitial();

  Future<void> fetchCarpoolDetail(CarpoolDetailParams params) async {
    state = const CarpoolDetailLoading();

    final result = await _carpoolDetail.call(params: params);

    result.fold(
      (failure) => state = CarpoolDetailError(failure.message),
      (response) => state = CarpoolDetailSuccess(carpool: response),
    );
  }
}

class CarpoolRideHistoryController extends Notifier<CarpoolRideHistoryStates> {
  GetCarpoolUseCase get _useCase => locator<GetCarpoolUseCase>();

  /// Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasFetchedOnce = false;
  List<CarpoolRideEntity> _rides = [];

  String? _currentStatus;

  @override
  CarpoolRideHistoryStates build() {
    return const CarpoolRideHistoryInitial();
  }

  void resetState() {
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;

    _rides.clear();

    _hasFetchedOnce = false;
    _currentStatus = null;

    state = const CarpoolRideHistoryInitial();
  }

  /// FIRST LOAD
  Future<void> fetchCarpoolHistory(
    String? status, {
    required bool force,
  }) async {
    if (!force && _hasFetchedOnce && _rides.isNotEmpty) return;

    _currentStatus = status;
    _currentPage = 1;
    _rides.clear();

    state = const CarpoolRideHistoryLoading();

    final result = await _useCase(
      params: CarpoolParam(page: _currentPage, status: _currentStatus),
    );

    result.fold((failure) => state = CarpoolRideHistoryError(failure.message), (
      response,
    ) {
      _rides = response.rides;

      _hasMore =
          response.pagination.currentPage < response.pagination.totalPages;
      _hasFetchedOnce = true;

      state = CarpoolRideHistorySuccess(rides: _rides, hasMore: _hasMore);
    });
  }

  /// PAGINATION
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    _currentPage++;

    final result = await _useCase(
      params: CarpoolParam(page: _currentPage, status: _currentStatus),
    );

    result.fold((failure) {}, (response) {
      _rides.addAll(response.rides);

      _hasMore =
          response.pagination.currentPage < response.pagination.totalPages;

      state = CarpoolRideHistorySuccess(rides: _rides, hasMore: _hasMore);
    });

    _isLoadingMore = false;
  }
}
