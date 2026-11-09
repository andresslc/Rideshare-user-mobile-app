import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/chat/data/models/chat_message_model.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_socket_datasource.dart';
import 'package:ride_app/features/ride_room/enums/ride_enum.dart';
import 'package:ride_app/features/ride_room/presentation/helpers/ride_cancel_flow_helper.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_eta_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';
import 'package:ride_app/features/ride_room/screens/drag_handler.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/chat_icon_widget.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';
import 'package:ride_app/shared/widgets/recenter_route_button.dart';
import 'package:ride_app/shared/widgets/ride_stats_row.dart';
import 'package:ride_app/shared/widgets/special_request_widget.dart';
import 'package:ride_app/shared/widgets/verticle_location_stepper.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../shared/widgets/ride_driver_info.dart';

class OnGoingRideStatusSheet extends ConsumerStatefulWidget {
  final OnGoingRideStatus status;
  const OnGoingRideStatusSheet({super.key, required this.status});

  @override
  ConsumerState<OnGoingRideStatusSheet> createState() =>
      _OnGoingRideStatusSheetState();
}

class _OnGoingRideStatusSheetState
    extends ConsumerState<OnGoingRideStatusSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const double maxChildSize = 0.7;
  static const double minChildSize = 0.3;
  static const String _sosDialNumber = '911';
  // static const double maxChildSize = 0.6;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(rideRoomProvider.notifier)
          .hydrateActiveRideDetailsIfNeeded(),
    );
    _registerSocketListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final RideRoomState ride = ref.read(rideRoomProvider);
      final String id =
          (ride.activeRide?.id ?? ride.latestRideStatus?.rideId ?? '').trim();
      if (id.isEmpty) return;
      ref
          .read(rideRoomProvider.notifier)
          .applyPersistedRideChatBadge(currentScopeKey: 'normal:$id');
    });
  }

  StreamSubscription<ChatMessageModel>? _chatReceiveSub;

  /// Live messages flow through [RideSocketListener] + [RideSocketDataSource]
  /// (same socket session as `ride:resume`), not a raw `SocketService.on`.
  void _registerSocketListener() {
    // if (widget.args == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final datasource = locator<RideSocketDataSource>();

      /// 🔥 Ensure socket is connected before listening
      await datasource.connect();

      if (!mounted) return;

      await _chatReceiveSub?.cancel();

      _chatReceiveSub = datasource.chatReceiveUpdates().listen(
        (ChatMessageModel msg) {
          if (!mounted) return;
          final rideState = ref.read(rideRoomProvider);
          final myId = ref.read(userProfileProvider).profile?.user.id ?? '';
          final driverId = rideState.activeRide?.driver?.id ?? '';
          ref
              .read(rideRoomProvider.notifier)
              .showChatBadgeForIncomingMessage(
                msg,
                passengerUserId: myId,
                driverUserId: driverId,
              );
        },
        onError: (e, st) {
          debugPrint('[chat:receive] stream error: $e\n$st');
        },
      );

      debugPrint('[chat:receive] subscribed via RideSocketDataSource');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: maxChildSize,
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
                        children: [_sheetContent()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 0,
              right: 8,
              child: RecenterRouteButton(isCarpool: false),
            ),
          ],
        );
      },
    );
  }

  // ---------------- UI PARTS ----------------

  Widget _sheetContent() {
    final l10 = context.l10n;
    final rideState = ref.watch(rideRoomProvider);
    final ride = rideState.activeRide;
    final driverName = ride?.driver?.fullName.trim().isNotEmpty == true
        ? ride!.driver!.fullName
        : 'Driver';
    final profileImage = ride?.driver?.profilePicture ?? "";
    final driverRating = ride?.driver?.rating ?? 0.0;
    final sr = ride?.specialRequest.trim() ?? '';
    final plate = ride?.vehicle?.numberPlate ?? '--';
    final carName = [
      ride?.vehicle?.name?.trim(),
      ride?.vehicle?.model?.trim(),
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
    final pickup = ride?.pickupPoint?.placeName ?? '--';
    final dropOff = ride?.dropOffPointRequested?.placeName ?? '--';
    // final otp = rideState.rideOTP ?? ride?.otp ?? '--';

    final fare = ride?.rideFare ?? 0.0;
    final distance = ride?.rideDistance ?? 0.0;
    final avgTime = ride?.averageTime ?? 0;
    final colors = context.appColors;
    final bool isDriverOnTheWay = widget.status == OnGoingRideStatus.onTheWay;

    const hp = EdgeInsets.symmetric(horizontal: 16);
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: hp,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.status.text(context),
                      style: context.textTheme.headlineMedium,
                      textAlign: TextAlign.start,
                    ),
                  ),
                  if (isDriverOnTheWay)
                    Consumer(
                      builder: (context, ref, _) {
                        final String? eta = ref.watch(rideEtaProvider);
                        final bool hasEta = eta != null &&
                            eta.trim().isNotEmpty &&
                            !eta.trim().startsWith('0');
                        if (!hasEta) return const SizedBox.shrink();

                        return Container(
                              margin: const EdgeInsets.only(left: 8),
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
                                    eta,
                                    style:
                                        context.textTheme.titleLarge?.copyWith(
                                      color: colors.brand,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 250.ms)
                            .scale(begin: const Offset(0.9, 0.9));
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.p12),

            const Divider(height: AppSizes.p20),
            Padding(
              padding: hp,
              child: DriverInfoSection(
                driverId: ride?.driver?.id ?? '',
                profileImage: profileImage,
                userName: driverName,
                rating: driverRating,
                carImage: AppImages.sedan,
                wantChatIcon: false,
                showCarInfo: true,
                showTopBorder: false,
                carMake: carName.capitalised,
                plateNo: plate,
              ),
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
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
                          showBadge: rideState.showBadge,
                          onTap: () {
                            final ride = rideState.activeRide;
                            final rideId = ride?.id;
                            final driverId = ride?.driver?.id;
                            if (rideId == null ||
                                rideId.isEmpty ||
                                driverId == null ||
                                driverId.isEmpty) {
                              return;
                            }
                            context.pushNamed(
                              Routes.chat.name,
                              queryParameters: {
                                'rideId': rideId,
                                'driverId': driverId,
                                'driverName': driverName,
                                if (profileImage.isNotEmpty)
                                  'driverProfileImage': profileImage,
                              },
                            );
                            ref
                                .read(rideRoomProvider.notifier)
                                .clearChatBadge();
                          },
                        ),
                      ],
                    ),
                  ),

                  // const Divider(height: AppSizes.p20),

                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text(
                  //       l10.ride_verification_code,
                  //       style: context.textTheme.bodyMedium,
                  //       textAlign: TextAlign.start,
                  //     ),
                  //     Text(
                  //       otp,
                  //       style: context.textTheme.headlineMedium?.copyWith(
                  //         color: colors.brand,
                  //       ),
                  //       textAlign: TextAlign.start,
                  //     ),
                  //   ],
                  // ),
                  const Divider(height: AppSizes.p16),
                  VerticleLocationStepper(
                    locationList: [pickup, dropOff],
                    startTime: "--:--",
                    endTime: "--:--",
                    showTopBorder: false,
                  ),
                  if (sr.isNotEmpty) ...[
                    const Divider(height: AppSizes.p16),
                    SpecialRequest(
                      title: l10.special_request,
                      showTopBorder: false,
                      description: sr,
                    ),
                  ],

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
                          ride?.paymentMethod == 'attached_card'
                              ? l10.via_card
                              : l10.via_wallet,
                          style: context.textTheme.bodyMedium,
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ),
                  // const CardWidget(card: BankCardEntity(status: "card")),
                  const SizedBox(height: AppSizes.p16),
                  RideStatsRow(
                    totalTime: (avgTime).formatAvgTime(context),
                    totalDistance:
                        "${distance.toStringAsFixed(1)} ${l10.miles}",
                    estimateFare: "\$${fare.toStringAsFixed(2)}",
                  ),
                  // const Divider(height: AppSizes.p12),
                  const SizedBox(height: AppSizes.p32),

                  if (widget.status == OnGoingRideStatus.onTheWay)
                    AppButton(
                      backgroundColor: context.appColors.border,
                      fontColor: context.appColors.brand,
                      text: l10.cancel_rid,
                      isDisable: rideState.status == RideRoomStatus.loading,
                      onPressed: () {
                        _onCancelRideTap(ride?.id);
                      },
                    )
                  else if (widget.status ==
                      OnGoingRideStatus.reachedDestination)
                    AppButton(text: l10.sos, onPressed: _onSosTap)
                  else ...[
                    AppButton(
                      backgroundColor: context.appColors.border,
                      fontColor: context.appColors.brand,
                      text: l10.cancel_rid,
                      isDisable: rideState.status == RideRoomStatus.loading,
                      onPressed: () {
                        _onCancelRideTap(ride?.id);
                      },
                    ),
                    const SizedBox(height: AppSizes.p16),
                    AppButton(text: l10.sos, onPressed: _onSosTap),
                  ],
                  const SizedBox(height: AppSizes.p32),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p32),
          ],
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(
          begin: 0.08,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 300.ms,
        );
  }

  // ---------------- LOGIC ----------------

  Future<void> _onCancelRideTap(String? rideId) async {
    if (!mounted) return;
    await cancelRideWithConfirmation(
      isPendingRequestCancelled: false,
      context: context,
      ref: ref,
      rideId: rideId,
    );
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

  @override
  void dispose() {
    unawaited(_chatReceiveSub?.cancel());
    super.dispose();
  }
}
