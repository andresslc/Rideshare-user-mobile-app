import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/params/find_ride_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_option_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_response_entity.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/carpool_state.dart';
import 'package:ride_app/features/ride_room/presentation/widgets/carpool_ride_card.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/shared.dart';

import '../../../../core/extensions/theme_extension.dart';
import '../../../../core/navigation/routes.dart';

class AvailableCarpoolRidesScreen extends ConsumerStatefulWidget {
  const AvailableCarpoolRidesScreen({super.key, this.params});

  final FindRideParams? params;

  @override
  ConsumerState<AvailableCarpoolRidesScreen> createState() =>
      _AvailableCarpoolRidesScreenState();
}

class _AvailableCarpoolRidesScreenState
    extends ConsumerState<AvailableCarpoolRidesScreen> {
  static const Duration _apiPollingInterval = Duration(seconds: 10);

  Timer? _apiPollingTimer;
  String? _joiningRideId;
  String? _lastShownErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final FindRideParams? params = widget.params;
      if (!mounted || params == null) return;
      await ref.read(carpoolProvider.notifier).searchBySocket(params);
      _startApiPolling();
    });
  }

  @override
  void dispose() {
    _apiPollingTimer?.cancel();
    super.dispose();
  }

  void _startApiPolling() {
    _apiPollingTimer?.cancel();
    _apiPollingTimer = Timer.periodic(_apiPollingInterval, (Timer timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final CarpoolState currentState = ref.read(carpoolProvider);
      if (currentState.hasRides) {
        timer.cancel();
        return;
      }

      await ref.read(carpoolProvider.notifier).refreshByApi();

      if (ref.read(carpoolProvider).hasRides) {
        timer.cancel();
      }
    });
  }

  Future<void> _onSendRequest(CarpoolRideEntity ride) async {
    if (_joiningRideId != null || ref.read(carpoolProvider).isJoiningRequest) return;
    setState(() {
      _joiningRideId = ride.id;
    });

    final bool joined = await ref.read(carpoolProvider.notifier).joinRide(ride);

    if (!mounted) return;
    setState(() {
      _joiningRideId = null;
    });

    final CarpoolState nextState = ref.read(carpoolProvider);
    if (joined) {
      if ((nextState.actionMessage?.trim().isNotEmpty ?? false)) {
        context.showSuccessToast(nextState.actionMessage!);
      }
      return;
    }

    if ((nextState.errorMessage?.trim().isNotEmpty ?? false)) {
      context.showErrorToast(nextState.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final FindRideParams? params = widget.params;
    final l10n = context.l10n;
    if (params == null) {
      return AppScaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
          title: Text(
            l10n.requested_carpool,
          ), // or should it be available carpool? let's use available if I added it. Actually I used requested_carpool in previous screen. I'll use requested_carpool for now if that's what I defined. wait, let me check.
        ),
        child: Center(child: Text(l10n.somethingWentWrong)),
      );
    }

    ref.listen<CarpoolState>(carpoolProvider, (previous, next) {
      final bool hasNewSearchError =
          previous?.errorMessage != next.errorMessage &&
          next.status == CarpoolSearchStatus.error &&
          (next.errorMessage?.trim().isNotEmpty ?? false);
      if (!hasNewSearchError || !mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final String message = next.errorMessage!.trim();
        if (_lastShownErrorMessage != message) {
          _lastShownErrorMessage = message;
          context.showErrorToast(message);
        }
        context.goNamed(Routes.home.name);
      });
    });

    final CarpoolState state = ref.watch(carpoolProvider);

    final int itemCount = state.rides.length;
    final bool isAnyJoining =
        _joiningRideId != null || state.isJoiningRequest;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.requested_carpool),
        centerTitle: true,
      ),
      child: itemCount > 0
          ? ListView.separated(
              // padding: const EdgeInsets.all(AppSizes.p4),
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(height: AppSizes.p16),
              itemBuilder: (BuildContext context, int index) {
                final CarpoolRideEntity ride = state.rides[index];

                final CarpoolOptionEntity option = _toOption(
                  ride,
                  params,
                  l10n,
                );
                final bool isThisJoining =
                    _joiningRideId == ride.id && state.isJoiningRequest;
                return CarpoolRideCard(
                  showFarePerPerson: true,
                  option: option,
                  isLoading: isThisJoining,
                  isDisabled: isAnyJoining && !isThisJoining,
                  onActionPressed: () => _onSendRequest(ride),
                );
              },
            )
          : _SearchingState(
              isSearching: state.isSearching,
              errorMessage: state.errorMessage,
            ),
    );
  }

  CarpoolOptionEntity _toOption(
    CarpoolRideEntity ride,
    FindRideParams params,
    AppLocalizations l10n,
  ) {
    final String driverName =
        ride.driver == null || ride.driver!.fullName.trim().isEmpty
        ? l10n.carpool_driver
        : ride.driver!.fullName;

    final List<String> routeStops = ride.routes.isNotEmpty
        ? ride.routes
              .map((CarpoolRideStopEntity stop) => stop.placeName)
              .where((String name) => name.trim().isNotEmpty)
              .toList()
        : [];

    return CarpoolOptionEntity(
      id: ride.id,
      driverName: driverName,
      driverRating: ride.driver?.rating ?? 0.0,
      driverProfileImage: ride.driver?.profilePicture ?? '',
      carName: ride.vehicle?.name ?? '',
      plate: ride.vehicle?.numberPlate ?? '',
      locationStops: [
        ride.resolvedPickupStop?.placeName ?? "",
        ...routeStops,
        ride.resolvedDropOffStop?.placeName ?? "",
      ],
      rideStartTime: _formatRideStartTime(ride.graceTime),
      availableSeats: ride.availableSeats,
      // from bc
      avgTimeMinutes: ride.avgTime,
      totalDistanceKm: ride.distance,

      //from params
      // avgTimeMinutes: params.averageTime,
      // totalDistanceKm: params.rideDistance,
      // fareMin: ride.fare,
      fareMax: ride.fare / ride.requiredSeats,
    );
  }

  String _formatRideStartTime(DateTime? value) {
    if (value == null) return '--:--';
    final DateTime local = value;
    final int hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final String minute = local.minute.toString().padLeft(2, '0');
    final String meridiem = local.hour >= 12
        ? (Localizations.localeOf(context).languageCode == 'es'
              ? 'p. m.'
              : 'PM')
        : (Localizations.localeOf(context).languageCode == 'es'
              ? 'a. m.'
              : 'AM');
    return '${hour.toString().padLeft(2, '0')}:$minute $meridiem';
  }
}

class _SearchingState extends StatelessWidget {
  const _SearchingState({required this.isSearching, this.errorMessage});

  final bool isSearching;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // if (isSearching)
          const CircularProgressIndicator(),
          // if (isSearching)
          const SizedBox(height: AppSizes.p20),
          Text(
            context.l10n.searching_carpool,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium,
          ),
          // const SizedBox(height: AppSizes.p12),
          // Text(
          //   'We will keep checking every 10 seconds and show rides here as soon as they are available.',
          //   textAlign: TextAlign.center,
          //   style: context.textTheme.bodyMedium,
          // ),
          if (errorMessage?.trim().isNotEmpty ?? false) ...<Widget>[
            const SizedBox(height: AppSizes.p16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
