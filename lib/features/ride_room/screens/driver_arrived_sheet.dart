import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_details_remote_data_source.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/screens/drag_handler.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';
import 'package:ride_app/shared/widgets/recenter_route_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../shared/widgets/ride_driver_info.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/services/sound_service.dart';
import '../../../shared/widgets/chat_icon_widget.dart';
import '../../chat/data/models/chat_message_model.dart';
import '../data/datasources/ride_socket_datasource.dart';
import '../presentation/helpers/ride_cancel_flow_helper.dart';
import '../presentation/states/ride_room_state.dart';

/// Backend marks the passenger as en route (e.g. after `/coming` or on `rideResume`).
bool _isComingRideStatus(String? raw) {
  final normalized = (raw ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('-', '')
      .replaceAll('_', '');
  return normalized == 'coming';
}

bool _rideStateMarksRiderComing(RideRoomState rideState) {
  if (rideState.currentRideType == RideType.coming) return true;
  final ride = rideState.activeRide ?? rideState.latestRideStatus?.ride;
  if (_isComingRideStatus(ride?.rideStatus)) return true;
  if (_isComingRideStatus(rideState.latestRideStatus?.type)) return true;
  return false;
}

class DriverArrivedSheet extends ConsumerStatefulWidget {
  const DriverArrivedSheet({super.key});

  @override
  ConsumerState<DriverArrivedSheet> createState() => _DriverArrivedSheetState();
}

class _DriverArrivedSheetState extends ConsumerState<DriverArrivedSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const double maxChildSize = 0.55;
  static const double minChildSize = 0.3;

  static const int _pickupCountdownTotalSeconds = 5 * 60;

  static const String _prefsPickupRideIdKey = 'driver_arrived_pickup_ride_id';
  static const String _prefsPickupEndMsKey = 'driver_arrived_pickup_end_ms';

  // static const double maxChildSize = 0.6;

  bool _iamComingLoading = false;
  bool _iamComingSent = false;
  String? _iamComingRideId;

  Timer? _pickupCountdownTimer;
  bool _pickupCountdownVisible = false;
  int _pickupSecondsRemaining = _pickupCountdownTotalSeconds;

  StreamSubscription<ChatMessageModel>? _chatReceiveSub;

  void _syncIAmComingRideContext(String? rideId) {
    if (rideId != _iamComingRideId) {
      if (_iamComingRideId != null) {
        _clearPickupDeadlinePersisted();
      }
      _iamComingRideId = rideId;
      _iamComingSent = false;
      _iamComingLoading = false;
      _pickupCountdownTimer?.cancel();
      _pickupCountdownTimer = null;
      _pickupCountdownVisible = false;
      _pickupSecondsRemaining = _pickupCountdownTotalSeconds;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncArrivalCountdownWithRideState(ref.read(rideRoomProvider));
      });
    }
  }

  void _clearPickupDeadlinePersisted() {
    final prefs = locator<SharedPreferences>();
    prefs.remove(_prefsPickupRideIdKey);
    prefs.remove(_prefsPickupEndMsKey);
  }

  void _persistPickupDeadline(String rideId, int endAtMs) {
    final prefs = locator<SharedPreferences>();
    prefs.setString(_prefsPickupRideIdKey, rideId);
    prefs.setInt(_prefsPickupEndMsKey, endAtMs);
  }

  /// Null if nothing stored or [rideId] does not match persisted ride.
  int? _readPersistedRemainingSeconds(String rideId) {
    final prefs = locator<SharedPreferences>();
    final id = prefs.getString(_prefsPickupRideIdKey);
    final endMs = prefs.getInt(_prefsPickupEndMsKey);
    if (id == null || endMs == null || id != rideId) return null;
    final end = DateTime.fromMillisecondsSinceEpoch(endMs);
    var rem = end.difference(DateTime.now()).inSeconds;
    if (rem < 0) rem = 0;
    if (rem > _pickupCountdownTotalSeconds) {
      rem = _pickupCountdownTotalSeconds;
    }
    return rem;
  }

  void _stopAndHidePickupCountdown() {
    _clearPickupDeadlinePersisted();
    final hadTimer = _pickupCountdownTimer != null;
    _pickupCountdownTimer?.cancel();
    _pickupCountdownTimer = null;
    if (!mounted) return;
    if (hadTimer || _pickupCountdownVisible) {
      setState(() => _pickupCountdownVisible = false);
    }
  }

  /// Five-minute pickup window when driver has arrived ([RideType.arrived]).
  /// Persists the deadline so the countdown survives app restarts.
  void _startArrivalCountdownIfNeeded(String rideId) {
    if (_pickupCountdownTimer != null) return;
    if (_pickupCountdownVisible && _pickupSecondsRemaining <= 0) return;

    final persisted = _readPersistedRemainingSeconds(rideId);
    int remaining;
    if (persisted != null) {
      remaining = persisted;
    } else {
      final endAtMs = DateTime.now()
          .add(const Duration(seconds: _pickupCountdownTotalSeconds))
          .millisecondsSinceEpoch;
      _persistPickupDeadline(rideId, endAtMs);
      remaining = _pickupCountdownTotalSeconds;
    }

    setState(() {
      _pickupCountdownVisible = true;
      _pickupSecondsRemaining = remaining;
    });

    if (remaining <= 0) {
      return;
    }

    _pickupCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_pickupSecondsRemaining > 0) {
          _pickupSecondsRemaining -= 1;
        }
        if (_pickupSecondsRemaining <= 0) {
          _pickupCountdownTimer?.cancel();
          _pickupCountdownTimer = null;
          _pickupSecondsRemaining = 0;
        }
      });
    });
  }

  void _syncArrivalCountdownWithRideState(RideRoomState next) {
    if (_rideStateMarksRiderComing(next)) {
      _stopAndHidePickupCountdown();
      return;
    }
    if (_iamComingSent) {
      _stopAndHidePickupCountdown();
      return;
    }
    if (next.currentRideType != RideType.arrived) {
      _stopAndHidePickupCountdown();
      return;
    }

    final String? rideId = next.activeRide?.id ?? next.latestRideStatus?.rideId;
    if (rideId == null || rideId.trim().isEmpty) return;

    if (_pickupCountdownTimer != null) return;
    if (_pickupCountdownVisible && _pickupSecondsRemaining <= 0) return;

    _startArrivalCountdownIfNeeded(rideId.trim());
  }

  String _formatCountdownMmSs(int totalSeconds) {
    final s = totalSeconds.clamp(0, _pickupCountdownTotalSeconds);
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pickupCountdownTimer?.cancel();
    _chatReceiveSub?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

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
      _syncArrivalCountdownWithRideState(ref.read(rideRoomProvider));
    });
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

  Future<void> _onCancelRideTap(String? rideId) async {
    if (!mounted) return;
    await cancelRideWithConfirmation(
      isPendingRequestCancelled: false,
      context: context,
      ref: ref,
      rideId: rideId,
    );
  }

  Future<void> _onIAmComingTap(String? rideId) async {
    locator<SoundService>().stopRepeatingSound();
    final String? id = rideId?.trim();
    if (id == null ||
        id.isEmpty ||
        _iamComingLoading ||
        _iamComingSent ||
        _rideStateMarksRiderComing(ref.read(rideRoomProvider)) ||
        !mounted) {
      return;
    }
    setState(() => _iamComingLoading = true);
    final result = await locator<RideDetailsRemoteDataSource>()
        .notifyRiderComing(id);
    if (!mounted) return;
    setState(() => _iamComingLoading = false);
    result.fold((failure) => context.showErrorToast(failure.message), (_) {
      _clearPickupDeadlinePersisted();
      _pickupCountdownTimer?.cancel();
      _pickupCountdownTimer = null;
      setState(() {
        _iamComingSent = true;
        _pickupCountdownVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RideRoomState>(rideRoomProvider, (previous, next) {
      _syncArrivalCountdownWithRideState(next);
    });

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
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      DragHandlerWidget(
                        controller: _sheetController,
                        minChildSize: minChildSize,
                        maxChildSize: maxChildSize,
                      ),
                      Expanded(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 16),
                          controller: controller,
                          children: [_sheetContent()],
                        ),
                      ),
                    ],
                  ),
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
    final l10n = context.l10n;
    final rideState = ref.watch(rideRoomProvider);
    final ride = rideState.activeRide;
    final driverName = ride?.driver?.fullName.trim().isNotEmpty == true
        ? ride!.driver!.fullName
        : l10n.driver_label;
    final driverRating = ride?.driver?.rating ?? 0.0;
    final plate = ride?.vehicle?.numberPlate ?? '--';
    final carName = [
      ride?.vehicle?.name?.trim(),
      ride?.vehicle?.model?.trim(),
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
    // final pickup = ride?.pickupPoint?.placeName ?? '--';
    final otp = rideState.rideOTP ?? ride?.otp ?? '--';
    // final phone = ride?.driver?.phone ?? '--';
    final profileImage = ride?.driver?.profilePicture ?? '';

    final String? resolvedRideId = () {
      final raw = ride?.id ?? rideState.latestRideStatus?.rideId;
      if (raw == null) return null;
      final t = raw.trim();
      return t.isEmpty ? null : t;
    }();
    _syncIAmComingRideContext(resolvedRideId);
    final riderComingFromServer = _rideStateMarksRiderComing(rideState);

    final colors = context.appColors;
    const hp = EdgeInsets.symmetric(horizontal: 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: hp,
          child: Text(
            l10n.driver_arrived_at_pickup,
            style: context.textTheme.headlineMedium,
            textAlign: TextAlign.start,
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
        if (_pickupCountdownVisible && !riderComingFromServer) ...[
          const SizedBox(height: AppSizes.p12),
          Padding(
            padding: hp,
            child: Text(
              l10n.driver_arrived_sheet_warning,
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.start,
            ),
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: AppSizes.p12),
          Padding(
            padding: hp,
            child:
                Text(
                      _formatCountdownMmSs(_pickupSecondsRemaining),
                      style: context.textTheme.displayLarge?.copyWith(
                        color: colors.brand,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.start,
                    )
                    .animate(delay: 150.ms)
                    .fadeIn()
                    .scale(begin: const Offset(0.9, 0.9)),
          ),
        ],
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
            carMake: carName,
            plateNo: plate,
          ),
        ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.2),
        const Divider(height: AppSizes.p20),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.contact_driver,
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.start,
              ),
              // Text(
              //   phone,
              //   style: context.textTheme.headlineMedium?.copyWith(
              //     color: colors.brand,
              //   ),
              //   textAlign: TextAlign.start,
              // ),
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
                  ref.read(rideRoomProvider.notifier).clearChatBadge();
                },
              ),
            ],
          ),
        ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2),

        const Divider(height: AppSizes.p20),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.ride_verification_code,
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.start,
              ),
              Text(
                otp,
                style: context.textTheme.headlineMedium?.copyWith(
                  color: colors.brand,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.ride_verification_code_disclaimer,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ).animate(delay: 320.ms).fadeIn(),

        const Divider(height: AppSizes.p24),

        Padding(
          padding: hp,
          child: AppButton(
            text: l10n.i_am_coming,
            isDisable:
                _iamComingLoading ||
                _iamComingSent ||
                riderComingFromServer ||
                rideState.status == RideRoomStatus.loading,
            child: _iamComingLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.button,
                    ),
                  )
                : null,
            onPressed: () => _onIAmComingTap(ride?.id),
          ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.2),
        ),
        const SizedBox(height: AppSizes.p16),
        Padding(
          padding: hp,
          child: AppButton(
            backgroundColor: context.appColors.border,
            fontColor: context.appColors.brand,
            text: l10n.cancel_rid,
            isDisable: rideState.status == RideRoomStatus.loading,
            onPressed: () {
              _onCancelRideTap(rideState.activeRide?.id);
            },
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),
        ),
        const SizedBox(height: AppSizes.p16),
      ],
    );
  }
}
