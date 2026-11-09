import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/core/params/find_ride_params.dart';
import 'package:ride_app/core/services/storage_service.dart';
import 'package:ride_app/features/ride_history/data/models/ride_history_model.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_option_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_response_entity.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/carpool_state.dart';
import 'package:ride_app/features/ride_room/presentation/widgets/carpool_ride_card.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/shared.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/routes.dart';
import '../../enums/ride_enum.dart';
import '../../presentation/helpers/ride_cancel_flow_helper.dart';
import '../../presentation/providers/ride_room_provider.dart';

class RequestedCarpoolScreen extends ConsumerWidget {
  const RequestedCarpoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final CarpoolState state = ref.watch(carpoolProvider);
    final CarpoolRideEntity? ride = state.requestedRide;
    final FindRideParams? params = state.params;

    if (ride == null || !state.hasRequestedRide) {
      return AppScaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.requested_carpool),
        ),
        child: Center(
          child: Text(
            l10n.no_requested_carpool,
            style: context.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final CarpoolOptionEntity option = _toOption(context, ride, params, l10n);

    ref.listen<CarpoolState>(carpoolProvider, (previous, next) {
      final bool becameCompleted =
          previous?.isCompleted != true && next.isCompleted;
      if (becameCompleted && context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.pushNamed(Routes.carpoolRideComplete.name);
        });
        return;
      }

      final bool becameActiveRide =
          (previous?.isAccepted == true || previous?.isInProgress == true) !=
              true &&
          (next.isAccepted || next.isInProgress);
      if (becameActiveRide && context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.goNamed(Routes.home.name);
        });
        return;
      }

      final bool cancelled =
          previous?.hasRequestedRide == true &&
          !next.hasRequestedRide &&
          previous?.isCompleted != true;
      if (cancelled && context.mounted) {
        ref
            .read(rideRoomProvider.notifier)
            .updateCurrentSheet(RideSheetsType.whereToGoSheet);
        if ((next.actionMessage?.trim().isNotEmpty ?? false)) {
          final String message = next.actionMessage!.trim();
          final String translatedMessage = _translateMessage(context, message);
          final String messageLower = translatedMessage.toLowerCase();
          if (messageLower.contains('rejected') ||
              messageLower.contains('cancelled') ||
              messageLower.contains('declined') ||
              messageLower.contains('rechazada') ||
              messageLower.contains('cancelada') ||
              messageLower.contains('rechazado')) {
            context.showErrorToast(translatedMessage);
          } else {
            context.showSuccessToast(translatedMessage);
          }
        }
        if ((next.errorMessage?.trim().isNotEmpty ?? false)) {
          context.showErrorToast(
            _translateMessage(context, next.errorMessage!),
          );
        }
        context.pop();
      }
    });

    return PopScope(
      canPop: false,
      child: AppScaffold(
        // padding: EdgeInsets.all(0),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.requested_carpool),
          centerTitle: true,
        ),
        child: ListView(
          children: <Widget>[
            if (state.joinedCarpool?.bookingId.trim().isNotEmpty ??
                false) ...<Widget>[
              Text(
                l10n.booking_id_with_id(state.joinedCarpool!.bookingId),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.p12),
            ],
            CarpoolRideCard(
              option: option,
              showFarePerPerson: true,
              actionText: l10n.cancel_request,
              useSlideButton: false,
              isLoading: state.isCancellingRequest,
              onActionPressed: () async {
                final bool confirmed = await showCancelRideConfirmation(
                  context,
                );
                if (confirmed) {
                  await ref
                      .read(carpoolProvider.notifier)
                      .cancelRequestedRide();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  CarpoolOptionEntity _toOption(
    BuildContext context,
    CarpoolRideEntity ride,
    FindRideParams? params,
    AppLocalizations l10n,
  ) {
    final String? userJson = locator<StorageService>().getUser;
    final UserModel user = UserModel.fromJson(
      userJson?.isNotEmpty == true
          ? jsonDecode(userJson!)
          : <String, dynamic>{},
    );
    final String currentUserId = user.id.trim().toLowerCase();
    CarpoolRideBookingEntity? matchedBooking;
    for (final CarpoolRideBookingEntity booking in ride.bookings) {
      if (booking.passengerId.trim().toLowerCase() == currentUserId) {
        matchedBooking = booking;
        break;
      }
    }

    final List<String> routeStops = ride.routes.isNotEmpty
        ? ride.routes
              .map((CarpoolRideStopEntity stop) => stop.placeName)
              .where((String name) => name.trim().isNotEmpty)
              .toList()
        : [];
    //  <String>[
    //     ride.resolvedPickupStop?.placeName ?? '',
    //     ride.resolvedDropOffStop?.placeName ?? '',
    //     params?.pickupPoint.placeName ?? '',
    //     params?.dropOffPoint.placeName ?? '',
    //   ].where((String name) => name.trim().isNotEmpty).toList();

    final String driverName =
        ride.driver == null || ride.driver!.fullName.trim().isEmpty
        ? l10n.carpool_driver
        : ride.driver!.fullName;

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
      rideStartTime: _formatRideStartTime(context, ride.graceTime),
      availableSeats: ride.availableSeats,
      avgTimeMinutes: matchedBooking != null && matchedBooking.avgTime > 0
          ? matchedBooking.avgTime
          : ride.avgTime,
      totalDistanceKm: matchedBooking != null && matchedBooking.distance > 0
          ? matchedBooking.distance
          : ride.distance,
      fareMax: matchedBooking != null && matchedBooking.fareCharged > 0
          ? matchedBooking.fareCharged / matchedBooking.requiredSeats
          : ride.fare / ride.requiredSeats,
    );
  }

  String _formatRideStartTime(BuildContext context, DateTime? value) {
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

  String _translateMessage(BuildContext context, String message) {
    if (message.isEmpty) return '';
    final l10n = context.l10n;
    switch (message) {
      case 'carpool_request_cancelled_fallback':
        return l10n.carpool_request_cancelled_fallback;
      case 'carpool_request_rejected_fallback':
        return l10n.carpool_request_rejected_fallback;
      case 'carpool_request_accepted_fallback':
        return l10n.carpool_request_accepted_fallback;
      case 'carpool_ride_started_fallback':
        return l10n.carpool_ride_started_fallback;
      case 'payment_verification_missing_client_secret':
        return l10n.payment_verification_missing_client_secret;
      default:
        return message;
    }
  }
}
