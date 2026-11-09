import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/chat/data/models/chat_message_model.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_socket_datasource.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/carpool_state.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';
import 'package:ride_app/features/ride_room/screens/drag_handler.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/chat_icon_widget.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';
import 'package:ride_app/shared/widgets/recenter_route_button.dart';
import 'package:ride_app/shared/widgets/ride_stats_row.dart';
import 'package:ride_app/shared/widgets/verticle_location_stepper.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_images.dart';
import '../../../../../shared/widgets/ride_driver_info.dart';
import '../../../ride_history/data/models/ride_history_model.dart';
import '../../domain/entities/carpool_ride_response_entity.dart';
import '../../presentation/helpers/ride_cancel_flow_helper.dart';

class CarpoolAcceptedRideSheet extends ConsumerStatefulWidget {
  const CarpoolAcceptedRideSheet({super.key});

  @override
  ConsumerState<CarpoolAcceptedRideSheet> createState() =>
      _CarpoolAcceptedRideSheetState();
}

class _CarpoolAcceptedRideSheetState
    extends ConsumerState<CarpoolAcceptedRideSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _showRideDetails = false;
  StreamSubscription<ChatMessageModel>? _chatReceiveSub;

  static const double maxChildSize = 0.7;
  static const double minChildSize = 0.32;
  static const String _sosDialNumber = '911';

  @override
  void initState() {
    super.initState();
    _registerChatBadgeSocketListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final String booking = ref.read(carpoolProvider).bookingId.trim();
      if (booking.isEmpty) return;
      ref
          .read(rideRoomProvider.notifier)
          .applyPersistedRideChatBadge(currentScopeKey: 'carpool:$booking');
    });
  }

  @override
  void dispose() {
    unawaited(_chatReceiveSub?.cancel());
    super.dispose();
  }

  void _registerChatBadgeSocketListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final datasource = locator<RideSocketDataSource>();
      await datasource.connect();
      if (!mounted) return;
      await _chatReceiveSub?.cancel();
      _chatReceiveSub = datasource.chatReceiveUpdates().listen(
        (ChatMessageModel msg) {
          if (!mounted) return;
          final carpool = ref.read(carpoolProvider);
          final myId = ref.read(userProfileProvider).profile?.user.id ?? '';
          final String driverFromCarpool =
              carpool.requestedRide?.driver?.id.trim() ?? '';
          final String driverFromRide =
              ref.read(rideRoomProvider).activeRide?.driver?.id.trim() ?? '';
          final String driverId = driverFromCarpool.isNotEmpty
              ? driverFromCarpool
              : driverFromRide;
          final String bookingId = carpool.bookingId.trim();
          ref
              .read(rideRoomProvider.notifier)
              .showChatBadgeForIncomingMessage(
                msg,
                passengerUserId: myId,
                driverUserId: driverId,
                persistUnreadScopeKey: bookingId.isNotEmpty
                    ? 'carpool:$bookingId'
                    : null,
              );
        },
        onError: (e, st) {
          debugPrint('[chat:receive] carpool sheet: $e\n$st');
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final CarpoolState carpoolState = ref.watch(carpoolProvider);
    // Must watch here (not only inside _sheetContent) or the sheet does not
    // rebuild when [rideRoomProvider.showBadge] changes without a carpool update.
    final RideRoomState rideRoomState = ref.watch(rideRoomProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      controller: _sheetController,
      snap: true,
      snapSizes: const [minChildSize, maxChildSize],
      builder: (context, controller) {
        return Stack(
          children: [
            Positioned.fill(
              top: 60,
              child: PlainBackgroundWidget(
                child: Column(
                  children: [
                    DragHandlerWidget(
                      controller: _sheetController,
                      minChildSize: minChildSize,
                      maxChildSize: maxChildSize,
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(top: 16),
                        controller: controller,
                        children: [_sheetContent(carpoolState, rideRoomState)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 0,
              right: 8,
              child: RecenterRouteButton(isCarpool: true),
            ),
          ],
        );
      },
    );
  }

  Widget _sheetContent(CarpoolState carpoolState, RideRoomState rideRoomState) {
    final l10 = context.l10n;
    final colors = context.appColors;

    final userJson = locator<StorageService>().getUser;
    final user = UserModel.fromJson(jsonDecode(userJson ?? '{}'));
    final CarpoolRideEntity? ride = carpoolState.requestedRide;
    final driver = ride?.driver;
    final vehicle = ride?.vehicle;
    final List<CarpoolRideStopEntity> routes =
        ride?.routes ?? const <CarpoolRideStopEntity>[];
    final List<CarpoolRideBookingEntity> matchedBookings =
        ride?.bookings
            .where(
              (CarpoolRideBookingEntity booking) =>
                  booking.passengerId.trim() == user.id,
            )
            .toList() ??
        const <CarpoolRideBookingEntity>[];
    final CarpoolRideBookingEntity? matchedBooking = matchedBookings.isNotEmpty
        ? matchedBookings.first
        : null;

    final driverName = (driver?.fullName.trim().isNotEmpty ?? false)
        ? driver!.fullName
        : l10.driver_label;
    final profileImage = driver?.profilePicture ?? '';
    final driverRating = driver?.rating ?? 0.0;
    final plate = (vehicle?.numberPlate?.trim().isNotEmpty ?? false)
        ? vehicle!.numberPlate!
        : l10.tbd;
    final carName = [
      vehicle?.name?.trim(),
      vehicle?.model?.trim(),
    ].whereType<String>().where((String e) => e.isNotEmpty).join(', ');
    final pickup =
        ride?.resolvedPickupStop?.placeName ??
        (routes.isNotEmpty ? routes.first.placeName : '--');
    final dropOff =
        ride?.resolvedDropOffStop?.placeName ??
        (routes.isNotEmpty ? routes.last.placeName : '--');
    final List<String> routeStops = [
      pickup,
      ...routes.map((CarpoolRideStopEntity stop) => stop.placeName),
      dropOff,
    ];
    final fare = matchedBooking != null && matchedBooking.fareCharged > 0
        ? matchedBooking.fareCharged / matchedBooking.requiredSeats
        : (ride?.fare ?? 0.0);
    final distance = matchedBooking != null && matchedBooking.distance > 0
        ? matchedBooking.distance
        : (ride?.distance ?? 0.0);
    final int avgTime = matchedBooking != null && matchedBooking.avgTime > 0
        ? matchedBooking.avgTime
        : (ride?.avgTime ?? 0);
    final String bookingOtp = matchedBooking?.otp.trim() ?? '';
    final String rideOtp = carpoolState.rideOtp.trim().isNotEmpty
        ? carpoolState.rideOtp.trim()
        : (bookingOtp.isNotEmpty ? bookingOtp : (ride?.otp.trim() ?? ''));
    final CarpoolRideStopEntity? latestArrivedStop = routes
        .where(
          (CarpoolRideStopEntity stop) =>
              stop.status.trim().toLowerCase() == 'arrived',
        )
        .fold<CarpoolRideStopEntity?>(null, (
          CarpoolRideStopEntity? latest,
          CarpoolRideStopEntity stop,
        ) {
          if (latest == null || stop.order > latest.order) {
            return stop;
          }
          return latest;
        });
    final String paymentMethod = ride?.paymentMethod ?? '';
    final bool canCancelBeforeOtpVerification = !carpoolState.otpVerified;
    final bool canEndRideAfterOtpVerification =
        carpoolState.otpVerified && !carpoolState.isCompleted;
    final bool hasCarpoolEta =
        carpoolState.latestDriverLocation?.hasValidEta ?? false;
    final String? carpoolEta = carpoolState.latestDriverLocation?.eta?.trim();
    final bool isCarpoolDriverOnTheWay =
        !carpoolState.otpVerified && carpoolState.isInProgress;

    const hp = EdgeInsets.symmetric(horizontal: 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: hp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      (carpoolState.otpVerified)
                          ? l10.ride_in_progress
                          : carpoolState.isInProgress
                          ? l10.driver_on_the_way
                          : l10.ride_accepted_successfully,
                      style: context.textTheme.headlineMedium,
                      textAlign: TextAlign.start,
                    ),
                  ),
                  if (hasCarpoolEta && isCarpoolDriverOnTheWay) ...[
                    const SizedBox(width: 8),
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.brand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.brand.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_filled_rounded,
                                size: 14,
                                color: colors.brand,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                carpoolEta!,
                                style: context.textTheme.labelLarge?.copyWith(
                                  color: colors.brand,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 250.ms)
                        .scale(begin: const Offset(0.9, 0.9)),
                  ],
                ],
              ),
              if (latestArrivedStop != null) ...[
                const SizedBox(height: AppSizes.p8),
                Text(
                  l10.driver_arrived_at_location(latestArrivedStop.placeName),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        const Divider(height: AppSizes.p20),
        Padding(
          padding: hp,
          child: DriverInfoSection(
            driverId: driver?.id ?? '',
            profileImage: profileImage,
            userName: driverName,
            rating: driverRating,
            carImage: AppImages.sedan,
            wantChatIcon: false,
            showCarInfo: true,
            showTopBorder: false,
            carMake: carName.isEmpty ? l10.carpool_ride : carName.capitalised,
            plateNo: plate,
          ),
        ),
        const Divider(height: AppSizes.p20),
        Padding(
          padding: hp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10.contact_driver,
                      style: context.textTheme.bodyMedium,
                      textAlign: TextAlign.start,
                    ),
                    ChatIconButton(
                      showBadge: rideRoomState.showBadge,
                      onTap: () {
                        final String rideId = carpoolState.bookingId;
                        final String driverId = driver?.id ?? '';
                        if (rideId.isEmpty || driverId.isEmpty) {
                          return;
                        }
                        context.pushNamed(
                          Routes.chat.name,
                          queryParameters: {
                            'rideId': rideId,
                            'isCarpool': 'true',
                            'driverId': driverId,
                            'driverName': driverName,
                            if (profileImage.isNotEmpty)
                              'driverProfileImage': profileImage,
                          },
                        );
                        ref.read(rideRoomProvider.notifier).clearChatBadge();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: AppSizes.p16),
              if (rideOtp.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10.ride_verification_code,
                      style: context.textTheme.bodyMedium,
                      textAlign: TextAlign.start,
                    ),
                    Text(
                      rideOtp,
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: colors.brand,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p8),
                Text(
                  l10.ride_verification_code_disclaimer,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const Divider(height: AppSizes.p16),
              ],
              if (!_showRideDetails) ...[
                const SizedBox(height: AppSizes.p16),
                AppButton(
                  text: l10.ride_details,
                  onPressed: () async {
                    setState(() {
                      _showRideDetails = true;
                    });
                    await _sheetController.animateTo(
                      maxChildSize,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ],
              if (_showRideDetails) ...[
                VerticleLocationStepper(
                  locationList: routeStops,
                  startTime: '--:--',
                  endTime: '--:--',
                  showTopBorder: false,
                ),
                const SizedBox(height: AppSizes.p16),
                const Divider(height: AppSizes.p4),
                const SizedBox(height: AppSizes.p16),
                Text(
                  l10.payment_method,
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: AppSizes.p8),
                SizedBox(
                  width: double.infinity,
                  child: AppGradientBox(
                    cornerRadius: 12,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                      ).copyWith(left: 16),
                      child: Text(
                        paymentMethod == 'attached_card'
                            ? l10.via_card
                            : l10.via_wallet,
                        style: context.textTheme.bodyMedium,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.p16),
                RideStatsRow(
                  totalTime: (avgTime).formatAvgTime(context),
                  totalDistance: '${distance.toStringAsFixed(1)} ${l10.miles}',
                  estimateFare: '\$${fare.toStringAsFixed(2)}',
                  totalAmountSuffix: l10.persen,
                ),
                const Divider(height: AppSizes.p12),
                const SizedBox(height: AppSizes.p32),
                if (canCancelBeforeOtpVerification) ...[
                  AppButton(
                    text: carpoolState.isCancellingRequest
                        ? ''
                        : l10.cancel_request,
                    backgroundColor: context.appColors.border,
                    fontColor: context.appColors.brand,
                    isDisable: carpoolState.isCancellingRequest,
                    onPressed: _onCancelRideTap,
                    child: carpoolState.isCancellingRequest
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.button,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSizes.p16),
                ],
                if (canEndRideAfterOtpVerification) ...[
                  AppButton(
                    text: carpoolState.isCompletingRide ? '' : l10.end_ride,
                    backgroundColor: colors.brand,
                    isDisable: carpoolState.isCompletingRide,
                    onPressed: _onEndRideTap,
                    child: carpoolState.isCompletingRide
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.button,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppSizes.p16),
                ],
                AppButton(text: l10.sos, onPressed: _onSosTap),
                const SizedBox(height: AppSizes.p32),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p32),
      ],
    );
  }

  Future<void> _onCancelRideTap() async {
    if (!mounted) return;
    final bool confirmed = await showCancelRideConfirmation(context);
    if (confirmed) {
      await ref.read(carpoolProvider.notifier).cancelRequestedRide();
    }
  }

  Future<void> _onEndRideTap() async {
    if (!mounted) return;
    await ref.read(carpoolProvider.notifier).completeRide();
  }

  Future<void> _onSosTap() async {
    final Uri dialUri = Uri(scheme: 'tel', path: _sosDialNumber);
    final bool canLaunch = await canLaunchUrl(dialUri);
    if (!canLaunch) {
      if (!mounted) return;
      context.showErrorToast(context.l10n.somethingWentWrong);
      return;
    }
    await launchUrl(dialUri);
  }
}
