import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ride_app/core/extensions/date_extension.dart';
import 'package:ride_app/features/ride_history/presentation/widgets/cancel_ride_card_widget.dart';
import 'package:ride_app/features/ride_history/presentation/widgets/carpool_history_card_widget.dart';

import '../../../../core/extensions/context_extension.dart';
import '../../../../core/extensions/theme_extension.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/ride_history_tab_switcher.dart';
import '../providers/ride_history_provider.dart';
import '../states/ride_history_states.dart';
import '../widgets/ride_history_card.dart';

class RideHistoryScreen extends ConsumerStatefulWidget {
  final String initialStatus;

  const RideHistoryScreen({super.key, this.initialStatus = "completed"});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen>
    with TickerProviderStateMixin {
  late final TabController _mainTabController;
  late final TabController _cancelledTabController;

  final ValueNotifier<int> _currentMainTabVN = ValueNotifier(0);
  String _lastCancelledBy = 'user';

  @override
  void initState() {
    super.initState();

    _mainTabController = TabController(length: 3, vsync: this);
    _cancelledTabController = TabController(length: 2, vsync: this);

    _mainTabController.addListener(_onMainTabChanged);
    _cancelledTabController.addListener(_onCancelledTabChanged);

    final status = widget.initialStatus.toLowerCase();

    if (status == "carpool") {
      _currentMainTabVN.value = 2;
    } else if (status.startsWith("cancelled")) {
      _currentMainTabVN.value = 1;
      _cancelledTabController.index = status.contains("driver") ? 1 : 0;
    } else {
      _currentMainTabVN.value = 0;
    }

    _mainTabController.index = _currentMainTabVN.value;
    Future.microtask(_onMainTabChanged);
  }

  void _onMainTabChanged() {
    _currentMainTabVN.value = _mainTabController.index;

    switch (_currentMainTabVN.value) {
      case 0:
        ref
            .read(completedRideProvider.notifier)
            .fetchRideHistoryWithFilters('completed', null);
        break;

      case 1:
        final cancelledBy = _cancelledTabController.index == 0
            ? 'user'
            : 'driver';
        ref
            .read(cancelledRideProvider.notifier)
            .fetchRideHistoryWithFilters('cancelled', cancelledBy);
        break;

      case 2:
        ref
            .read(carpoolRideHistoryProvider.notifier)
            .fetchCarpoolHistory('completed', force: false);
        break;
    }
  }

  void _onCancelledTabChanged() {
    if (_cancelledTabController.indexIsChanging) return;

    final cancelledBy = _cancelledTabController.index == 0 ? 'user' : 'driver';

    if (_lastCancelledBy == cancelledBy) return;
    _lastCancelledBy = cancelledBy;

    ref
        .read(cancelledRideProvider.notifier)
        .fetchRideHistoryWithFilters('cancelled', cancelledBy);
  }

  Future<void> _refreshData(
    String status,
    bool isCancelledTab,
    String? cancelledBy,
    NotifierProvider provider,
  ) async {
    if (status == 'carpool') {
      await ref
          .read(carpoolRideHistoryProvider.notifier)
          .fetchCarpoolHistory('completed', force: true);
    } else if (status == "completed") {
      await ref
          .read(completedRideProvider.notifier)
          .fetchRideHistoryWithFilters('completed', null, force: true);
    } else if (status == "cancelled") {
      await ref
          .read(cancelledRideProvider.notifier)
          .fetchRideHistoryWithFilters('cancelled', cancelledBy, force: true);
    }
  }

  void onPop() {
    ref.read(completedRideProvider.notifier).resetState();
    ref.read(cancelledRideProvider.notifier).resetState();
    ref.read(carpoolRideHistoryProvider.notifier).resetState();
  }

  @override
  void dispose() {
    _mainTabController.removeListener(_onMainTabChanged);
    _cancelledTabController.removeListener(_onCancelledTabChanged);

    _mainTabController.dispose();
    _cancelledTabController.dispose();
    _currentMainTabVN.dispose();

    super.dispose();
  }

  void _goToDetail({
    required String rideId,
    required String rideLabel,
    required String driverId,
    required String rideStatus,
    String? specialRequest,
    String? cancellationReason,
    String? cancelledBy,
  }) {
    context.pushNamed(
      Routes.ridehistorydetail.name,
      extra: {
        "rideId": rideId,
        "rideLabel": rideLabel,
        "rideStatus": rideStatus,
        "driverId": driverId,
        "specialRequest": specialRequest,
        "cancellationReason": cancellationReason,
        "cancelledBy": cancelledBy,
      },
    );
  }

  void _goToCarpoolDetail({
    String? carpoolId,
    required String rideLabel,
    required String profilepicture,
    required String carImage,
    required String carMake,
    required String plateNo,
    required String time,
  }) {
    context.pushNamed(
      Routes.ridedetailcarpool.name,
      extra: {
        "carpoolId": carpoolId,
        "rideLabel": rideLabel,
        "profilepicture": profilepicture,
        "carImage": carImage,
        "carMake": carMake,
        "plateNo": plateNo,
        "time": time,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    void handleBackNavigation() {
      onPop();
      context.goNamed(Routes.home.name);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBackNavigation();
      },
      child: AppScaffold(
        padding: EdgeInsets.zero,
        scrollable: false,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBackNavigation,
          ),
          title: Text(l10n.ride_history)
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: AnimatedBuilder(
                animation: _mainTabController,
                builder: (_, _) {
                  return RideHistoryTabSwitcher(
                        tabs: [l10n.completed, l10n.cancelled, l10n.carpool],
                        currentIndex: _mainTabController.index,
                        onTabChanged: _mainTabController.animateTo,
                      )
                      .animate()
                      .fadeIn(duration: 1000.ms)
                      .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic);
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  _buildRideList(
                        ref.watch(completedRideProvider),
                        "completed",
                        false,
                        null,
                        completedRideProvider,
                      )
                      .animate(key: const ValueKey('completed'))
                      .fadeIn(duration: 700.ms)
                      .slideX(begin: 0.05, end: 0),
                  _buildCancelledRidesTab(context)
                      .animate(key: const ValueKey('cancelled'))
                      .fadeIn(duration: 700.ms)
                      .slideX(begin: 0.05, end: 0),
                  _buildCarpoolList(ref.watch(carpoolRideHistoryProvider))
                      .animate(key: const ValueKey('carpool'))
                      .fadeIn(duration: 700.ms)
                      .slideX(begin: 0.05, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideList(
    RideHistoryStates state,
    String status,
    bool isCancelledTab,
    String? cancelledBy,
    NotifierProvider<RideHistoryController, RideHistoryStates> provider,
  ) {
    if (state is RideHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is RideHistoryError) {
      return Center(child: Text(state.message));
    }

    if (state is RidehistorySucces) {
      final filteredRides = state.rides.where((ride) {
        if (ride.rideStatus != status) return false;
        if (isCancelledTab && cancelledBy != null) {
          return ride.cancelledBy == cancelledBy;
        }
        return true;
      }).toList();

      if (filteredRides.isEmpty) {
        final emptyText = isCancelledTab
            ? cancelledBy == "driver"
                  ? context.l10n.no_rides_cancelled_by_driver
                  : context.l10n.your_have_not_cancelled
            : context.l10n.your_complete_finished_trip;

        return Center(
          child: Text(
            emptyText,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        );
      }
      return RefreshIndicator(
        onRefresh: () =>
            _refreshData(status, isCancelledTab, cancelledBy, provider),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: filteredRides.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filteredRides.length) {
              ref.read(provider.notifier).loadMore();
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final ride = filteredRides[index];

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildRideDateText(
                    context,
                    ride.createdAt,
                  ).animate().fadeIn(delay: (index * 40).ms, duration: 100.ms),

                  const Gap(8),

                  Bounceable(
                        onTap: () => _goToDetail(
                          rideId: ride.id,
                          rideLabel: ride.createdAt.formatRideDate(context),
                          rideStatus: ride.rideStatus,
                          driverId: ride.driver.id,
                          specialRequest: ride.specialRequest,
                          cancellationReason: ride.cancellationReason,
                          cancelledBy: ride.cancelledBy,
                        ),
                        child: isCancelledTab
                            ? CancelRideCard(ride: ride)
                            : RideHistoryCard(ride: ride),
                      )
                      .animate()
                      .fadeIn(
                        delay: (index.clamp(0, 8) * 60).ms,
                        duration: 100.ms,
                      )
                      .slideY(begin: 0.08, end: 0),
                ],
              ),
            );
          },
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildCarpoolList(CarpoolRideHistoryStates state) {
    if (state is CarpoolRideHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CarpoolRideHistoryError) {
      return Center(child: Text(state.message));
    }

    if (state is CarpoolRideHistorySuccess) {
      final rides = state.rides;

      if (rides.isEmpty) {
        return Center(child: Text(context.l10n.carpool_text));
      }

      return RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await _refreshData(
            "carpool",
            false,
            null,
            carpoolRideHistoryProvider,
          );
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];

            final vehicle = ride.driver.vehicleDetails;

            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildRideDateText(
                    context,
                    ride.createdAt,
                  ).animate().fadeIn(delay: (index * 40).ms, duration: 100.ms),

                  const Gap(6),
                  Bounceable(
                    onTap: () => _goToCarpoolDetail(
                      carpoolId: ride.id,
                      profilepicture: ride.driver.profilePicture ?? "",
                      carImage: "",
                      carMake: "${vehicle.make} ${vehicle.model}",
                      plateNo: vehicle.licensePlateNumber,
                      time: DateFormat(
                        'h:mm a',
                        'en',
                      ).format(ride.createdAt.toLocal()),
                      rideLabel: ride.createdAt.formatRideDate(context),
                    ),
                    child: CarpoolHistoryCard(carpoolride: ride)
                        .animate()
                        .fadeIn(delay: (index * 70).ms, duration: 100.ms)
                        .slideX(begin: 0.1, end: 0),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildCancelledRidesTab(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _cancelledTabController,
          indicatorColor: context.appColors.brand,
          labelColor: context.appColors.brand,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: context.l10n.by_user),
            Tab(text: context.l10n.by_driver),
          ],
        ),
        const Gap(16),
        Expanded(
          child: TabBarView(
            controller: _cancelledTabController,
            children: [
              _buildRideList(
                ref.watch(cancelledRideProvider),
                "cancelled",
                true,
                "user",
                cancelledRideProvider,
              ),
              _buildRideList(
                ref.watch(cancelledRideProvider),
                "cancelled",
                true,
                "driver",
                cancelledRideProvider,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget buildRideDateText(BuildContext context, DateTime rideDate) {
  final formatted = rideDate.formatRideDate(context);
  final parts = formatted.split(",");

  if (parts.length == 2) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "${parts[0]}, ",
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: parts[1].trim(),
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.appColors.brand,
            ),
          ),
        ],
      ),
    );
  }

  return Text(
    formatted,
    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  );
}
