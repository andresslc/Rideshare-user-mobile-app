import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/date_extension.dart';
import 'package:ride_app/core/navigation/routes.dart';
import 'package:ride_app/core/params/find_ride_params.dart';
import 'package:ride_app/core/theme/app_colors.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';
import 'package:ride_app/features/ride_room/screens/drag_handler.dart';
import 'package:ride_app/features/ride_room/screens/horizontal_image_selector.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';
import 'package:ride_app/shared/widgets/input_dialogue.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';
import 'package:ride_app/shared/widgets/recenter_route_button.dart';
import 'package:ride_app/shared/widgets/ride_stats_row.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../core/extensions/theme_extension.dart';
import '../../../core/utils/app_status_dialogue.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_gradient_box.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/custom_dialogue.dart';
import '../domain/entities/location_entity.dart';
import '../enums/ride_enum.dart';
import '../presentation/states/map_state.dart';
import 'payment_selector_widget.dart';

class RideType {
  final String id;
  final String name;
  final String subtitle;
  final String image;

  const RideType({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.image,
  });
}

/// The categories a rider may request. `private` — where the rider picked from
/// a list of driver offers — is retired: the backend rejects it and dispatches
/// `economy` and `luxury` to the nearest driver instead.
List<RideType> _rideTypes(BuildContext context) {
  final l10n = context.l10n;
  const defaultEtaMinutes = 5;
  final String etaLabel = '$defaultEtaMinutes ${l10n.mins_label}';
  return [
    RideType(
      id: 'economy',
      name: l10n.ride_type_economy,
      subtitle: '$etaLabel - ${l10n.ride_type_economy}',
      image: AppImages.economy,
    ),
    RideType(
      id: 'luxury',
      name: l10n.ride_type_luxury,
      subtitle: '$etaLabel - ${l10n.ride_type_luxury}',
      image: AppImages.luxury,
    ),
    RideType(
      id: 'carpool',
      name: l10n.carpool,
      subtitle: '$etaLabel - ${l10n.carpool}',
      image: AppImages.carpool,
    ),
  ];
}

class SelectRideSheet extends ConsumerStatefulWidget {
  const SelectRideSheet({super.key});

  @override
  ConsumerState<SelectRideSheet> createState() => _SelectRideSheetState();
}

class _SelectRideSheetState extends ConsumerState<SelectRideSheet> {
  static const double minChildSize = 0.45;
  static const double maxChildSize = 0.8;
  static const int _minPassengerCount = 1;
  static const int _maxPassengerCount = 4;
  static const double _floatingCurrentLocationTopOffset = 60;
  String? _selectedRideId;
  PaymentMethod _method = PaymentMethod.attached_card;
  bool _isSubmitting = false;
  int _passengerCount = 1;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final specialRequestController = TextEditingController();
  final specialRequestFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final rideRoomState = ref.read(rideRoomProvider);
    specialRequestController.text = rideRoomState.draftSpecialRequest;
    _selectedRideId = ref.read(mapProvider).value?.selectedRideType;
  }

  @override
  void dispose() {
    specialRequestController.dispose();
    specialRequestFocusNode.dispose();
    super.dispose();
  }

  // Future<void> _showPromoDialog() async {
  void _showPromoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, child) {
            final l10n = context.l10n;

            final mapState = ref.watch(mapProvider).value;
            final bool isLoading = mapState?.isApplyingPromoCode ?? false;
            String? error = mapState?.promoErrorMessage;

            return InputDialog(
              title: l10n.promo_code,
              subtitle: l10n.enter_promo,
              showFieldLabel: true,
              hintText: l10n.hint_promo,
              isRequired: false,
              maxLines: 1,
              maxLength: 20,
              buttonText: l10n.apply,
              fieldLabel: l10n.enter_promo,
              isLoading: isLoading,
              errorMessage: error,
              onChange: (v) {
                ref.read(mapProvider.notifier).clearPromoError();
              },
              inputFormatters: [UpperCaseTextFormatter()],
              onSubmit: (code) async {
                if (code.trim().isNotEmpty) {
                  // final bool isCarpool =
                  //     ((mapState?.selectedRideType ?? _selectedRideId) ==
                  //     'carpool');
                  // final num? fare = mapState?.estimatedFare;
                  // final num? totalFare;
                  // if (isCarpool) {
                  //   totalFare = fare != null ? fare * _passengerCount : null;
                  // } else {
                  //   totalFare = fare;
                  // }

                  await ref
                      .read(mapProvider.notifier)
                      .applyPromoCode(
                        code.trim(),
                        // customAmount: totalFare,
                        onSuccess: () {
                          dialogContext.pop();
                          _showSuccessDialog(dialogContext, l10n.promo_code);
                        },
                      );
                }
              },
            );
          },
        );
      },
    );
  }

  void _showPromoRemovalConfirmation({
    required VoidCallback onConfirm,
    String? title,
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return GradientSideDialog(
          title: (title ?? context.l10n.warning),
          subtitle: message ?? context.l10n.promo_removal_warning,

          icon: Icons.warning_amber_rounded,
          buttons: [
            AppButton(
              text: (context).l10n.cancel,
              backgroundColor: Colors.transparent,
              fontColor: context.appColors.textPrimary,
              onPressed: () => context.pop(),
            ),
            AppButton(
              text: (context).l10n.ok,
              backgroundColor: context.appColors.brand,
              fontColor: context.appColors.textPrimary,
              onPressed: () {
                context.pop();
                ref.read(mapProvider.notifier).clearPromoCode();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String title) {
    AppToastDialog.show(context, type: DialogToastType.success, title: title);
  }

  Future<void> showSpecialRequestDialog(BuildContext context) async {
    final l10n = context.l10n;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return InputDialog(
          title: l10n.special_request,
          isRequired: false,
          subtitle: l10n.special_request_subtitle,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 255,
          hintText: context.l10n.special_request,
          buttonText: context.l10n.save,
          prefilText: specialRequestController.text,
          onSubmit: (description) => Navigator.pop(context, description),
        );
      },
    );

    if (result != null) {
      specialRequestController.text = result;

      ref.read(rideRoomProvider.notifier).setDraftSpecialRequest(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RideRoomState>(rideRoomProvider, (previous, next) {
      if (next.currentSheet == RideSheetsType.selectRideSheet && mounted) {
        final String draftSpecialRequest = next.draftSpecialRequest;
        if (specialRequestController.text != draftSpecialRequest) {
          specialRequestController.value = TextEditingValue(
            text: draftSpecialRequest,
            selection: TextSelection.collapsed(
              offset: draftSpecialRequest.length,
            ),
          );
        }
      }

      if (_isSubmitting && next.status != RideRoomStatus.loading && mounted) {
        setState(() => _isSubmitting = false);
      }

      if (next.currentSheet == RideSheetsType.selectRideSheet &&
          next.status == RideRoomStatus.error &&
          (next.errorMessage?.isNotEmpty ?? false)) {
        context.showErrorToast(next.errorMessage!);
      }
    });

    ref.listen<AsyncValue<MapState>>(mapProvider, (previous, next) {
      final String? selectedRideType = next.asData?.value.selectedRideType;
      if (!mounted || selectedRideType == null) return;
      if (_selectedRideId == selectedRideType) return;

      setState(() {
        _selectedRideId = selectedRideType;
      });
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: DraggableScrollableSheet(
        initialChildSize: minChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        snap: true,
        controller: _sheetController,
        snapSizes: const [minChildSize, maxChildSize],
        builder: (context, controller) {
          return Stack(
            children: [
              Positioned.fill(
                top: _floatingCurrentLocationTopOffset,

                child: PlainBackgroundWidget(
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            DragHandlerWidget(
                              controller: _sheetController,
                              minChildSize: minChildSize,
                              maxChildSize: maxChildSize,
                            ),
                          ],
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
              ),
              Positioned(
                top: 0,
                left: 8,
                child: PlainBackgroundWidget(
                  isAllRounded: true,
                  child: CustomTap(
                    onTap: _handleBack,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: context.appColors.textPrimary,
                      ),
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
      ),
    );
  }

  Widget _sheetContent() {
    final mapAsync = ref.watch(mapProvider);

    return mapAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox(),
      data: (mapState) {
        return _buildContent(mapState);
      },
    );
  }
  // ---------------- UI PARTS ----------------

  Widget _buildContent(MapState mapState) {
    final l10n = context.l10n;
    const hp = EdgeInsets.symmetric(horizontal: 16);
    final mapNotifier = ref.read(mapProvider.notifier);
    final String pickupName = mapState.pickup?.name ?? '';
    final String dropOffName = mapState.dropOff?.name ?? '';
    final int averageTimeMinutes = _averageTimeMinutes(
      mapState.routeDurationSeconds,
    );
    final String totalTime = _formatAverageTime(averageTimeMinutes);
    final double rideDistanceMiles = mapNotifier.distanceInMiles(
      mapState.routeDistanceKm,
    );
    final String totalDistance = _formatDistanceMiles(rideDistanceMiles);
    final List<RideType> rideOptions = _rideTypes(context);
    final bool isCarpoolSelected =
        (_selectedRideId ?? mapState.selectedRideType) == 'carpool';
    // A promotion can take the whole fare to zero. Such a ride never reaches a
    // payment rail, so the app must not ask for a card or a balance.
    final bool isFreeRide =
        !mapState.isFareLoading &&
        mapState.hasEstimatedFair &&
        _rideFareFor(isCarpoolSelected, mapState) <= 0;

    final String totalAmount = _formatFare(
      getActualFare(isCarpoolSelected, mapState, mapState.payableFare),
      mapState.isFareLoading,
    );

    final String? originalFare =
        (mapState.hasAppliedPromoCode &&
            mapState.appliedPromo != null &&
            mapState.appliedPromo!.fares.isNotEmpty &&
            mapState.appliedPromo!.fares[0].discountApplied)
        ? _formatFare(mapState.appliedPromo!.fares[0].originalFare, false)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: hp,
          child: Text(
            l10n.pickup_location,
            style: context.textTheme.titleSmall,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(height: AppSizes.p14),
        Padding(
          padding: hp,
          child: GestureDetector(
            onTap: () async {
              specialRequestFocusNode.unfocus();
              _sheetController.jumpTo(minChildSize);

              final hasLocation = mapState.pickup != null;
              final hasPromo = mapState.hasAppliedPromoCode;

              Future<void> openPickupPicker() async {
                await context.pushNamed(
                  Routes.enterRoute.name,
                  extra: RideLocationType.pickup,
                );
              }

              if (hasLocation && hasPromo) {
                context.showPromoRemovalWarning(
                  onConfirm: () async {
                    ref.read(mapProvider.notifier).clearPromoCode();
                    await openPickupPicker();
                  },
                );
              } else {
                await openPickupPicker();
              }
            },
            child: AppTextField(
              controller: TextEditingController(text: pickupName),
              readOnly: true,
              enabled: false,
              hintText: l10n.pickup_location,
              prefixIcon: AppIcons.locationFill,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        Padding(
          padding: hp,
          child: Text(
            l10n.dropoff_location,
            style: context.textTheme.titleSmall,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(height: AppSizes.p14),
        GestureDetector(
          onTap: () async {
            specialRequestFocusNode.unfocus();
            _sheetController.jumpTo(minChildSize);

            final hasLocation = mapState.dropOff != null;
            final hasPromo = mapState.hasAppliedPromoCode;

            Future<void> openDropoffPicker() async {
              await context.pushNamed(
                Routes.enterRoute.name,
                extra: RideLocationType.dropoff,
              );
            }

            if (hasLocation && hasPromo) {
              context.showPromoRemovalWarning(
                onConfirm: () async {
                  ref.read(mapProvider.notifier).clearPromoCode();
                  await openDropoffPicker();
                },
              );
            } else {
              await openDropoffPicker();
            }
          },
          child: Padding(
            padding: hp,
            child: AppTextField(
              controller: TextEditingController(text: dropOffName),
              readOnly: true,
              enabled: false,
              hintText: l10n.dropoff_location,
              prefixIcon: AppIcons.locationFill,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        Padding(
          padding: hp,
          child: Text(
            l10n.select_ride,
            style: context.textTheme.titleSmall,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(height: AppSizes.p14),
        HorizontalImageSelector<RideType>(
          items: rideOptions,
          selectedId: _selectedRideId ?? mapState.selectedRideType,
          idBuilder: (ride) => ride.id,
          labelBuilder: (ride) => ride.name,
          imageBuilder: (ride) => ride.image,
          onChanged: (ride) {
            if (mapState.isFareLoading) return;
            final currentId = _selectedRideId ?? mapState.selectedRideType;
            if (ride.id == currentId) return;

            final hasPromo = mapState.hasAppliedPromoCode;
            if (hasPromo) {
              context.showPromoRemovalWarning(
                onConfirm: () {
                  setState(() {
                    _selectedRideId = ride.id;
                    if (ride.id != 'carpool') {
                      _passengerCount = _minPassengerCount;
                    }
                  });
                  ref.read(mapProvider.notifier).clearPromoCode();
                  ref.read(mapProvider.notifier).setSelectedRideType(ride.id);
                },
              );
            } else {
              setState(() {
                _selectedRideId = ride.id;
                if (ride.id != 'carpool') {
                  _passengerCount = _minPassengerCount;
                }
              });
              ref.read(mapProvider.notifier).setSelectedRideType(ride.id);
            }
          },
        ),

        if (!isCarpoolSelected) ...[
          const SizedBox(height: AppSizes.p16),
          Padding(
            padding: hp,
            child: Row(
              children: [
                Image.asset(AppIcons.info, width: 16, height: 16),
                const SizedBox(width: 12),
                Text(
                  "${l10n.special_request} ${l10n.optional}",
                  style: context.textTheme.titleSmall,
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p14),
          Padding(
            padding: hp,
            child: GestureDetector(
              onTap: () => showSpecialRequestDialog(context),
              child: AppTextField(
                enabled: false,
                controller: specialRequestController,
                focusNode: specialRequestFocusNode,
                maxlines: 3,
                maxLength: 250,
                hintText: l10n.special_request,
              ),
            ),
          ),
        ],
        if (isCarpoolSelected) ...[
          const SizedBox(height: AppSizes.p16),
          Padding(
            padding: hp,
            child: Text(
              l10n.number_of_passengers_label,
              style: context.textTheme.titleSmall,
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          Padding(
            padding: hp,
            child: _PassengerCounter(
              value: _passengerCount,
              onDecrement: _passengerCount > _minPassengerCount
                  ? () {
                      setState(() => _passengerCount--);
                    }
                  : null,
              onIncrement: _passengerCount < _maxPassengerCount
                  ? () {
                      setState(() => _passengerCount++);
                    }
                  : null,
            ),
          ),
        ],
        const SizedBox(height: AppSizes.p12),
        Padding(
          padding: hp,
          child: Text(
            isFreeRide ? l10n.free_ride : l10n.payment_method,
            style: context.textTheme.titleSmall,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(height: AppSizes.p16),

        Padding(
          padding: hp,
          child: isFreeRide
              ? Text(
                  l10n.free_ride_no_payment_needed,
                  style: context.textTheme.bodySmall,
                )
              : PaymentMethodSelector(
                  selected: _method,
                  onChanged: (value) {
                    setState(() => _method = value);
                  },
                ),
        ),
        const SizedBox(height: AppSizes.p16),
        Padding(
          padding: hp,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(AppIcons.discount, width: 17, height: 17),
                  const SizedBox(width: 12),
                  Text(l10n.promo_code, style: context.textTheme.titleSmall),
                ],
              ),
              if (mapState.hasAppliedPromoCode)
                IconButton(
                  onPressed: () {
                    _showPromoRemovalConfirmation(
                      onConfirm: () {},
                      title: l10n.remove_promo,
                      message: l10n.remove_promo_message,
                    );
                  },
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: context.appColors.brand,
                    size: 17,
                  ),
                ),
            ],
          ),
        ),
        if (!mapState.hasAppliedPromoCode) const SizedBox(height: 8),
        Padding(
          padding: hp,
          child: mapState.hasAppliedPromoCode
              ? AppTextField(
                  controller: TextEditingController(text: mapState.promoCode),
                  readOnly: true,
                  enabled: false,
                  hintText: l10n.hint_promo,
                )
              : AppButton(
                  text: l10n.hint_promo,
                  isDisable: !mapState.hasEstimatedFair,
                  onPressed: () => _showPromoDialog(context),
                  backgroundColor: Colors.transparent,
                  fontColor: context.appColors.brand,
                  needBorder: true,
                ),
        ),
        const SizedBox(height: AppSizes.p16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: RideStatsRow(
            totalTime: totalTime,
            totalDistance: totalDistance,
            estimateFare: totalAmount,
            originalFare: originalFare,
            totalAmountSuffix: isCarpoolSelected ? l10n.persen : null,
            // showDivider: true,
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: AppSizes.p24),
        Padding(
          padding: hp,
          child: AppButton(
            text: l10n.find_ride,
            isDisable: _isSubmitting,
            onPressed: () {
              _onFindRideTap(mapState);
            },
          ),
        ),
        const SizedBox(height: AppSizes.p24),
      ],
    );
  }

  num getActualFare(
    bool isCarpoolSelected,
    MapState mapState,
    num? totalAmount,
  ) {
    return double.parse((totalAmount ?? 0).toStringAsFixed(2));
  }

  /// What the rider pays once the promotion is applied — carpool multiplies by
  /// the number of seats. Zero means the promotion covers the whole ride.
  num _rideFareFor(bool isCarpoolSelected, MapState mapState) {
    final num unitFare = mapState.payableFare ?? 0;
    return isCarpoolSelected ? unitFare * _passengerCount : unitFare;
  }

  void _handleBack() {
    final mapState = ref.read(mapProvider).value;
    final hasPromo = mapState?.hasAppliedPromoCode ?? false;
    if (hasPromo) {
      context.showPromoRemovalWarning(
        onConfirm: () {
          ref.read(mapProvider.notifier).clearPromoCode();
          ref.read(mapProvider.notifier).clearDropOffLocation();
          ref.read(mapProvider.notifier).clearRideSelection();
          ref.read(rideRoomProvider.notifier).clearDraftSpecialRequest();

          ref
              .read(rideRoomProvider.notifier)
              .updateCurrentSheet(RideSheetsType.whereToGoSheet);
        },
      );
    } else {
      ref.read(mapProvider.notifier).clearDropOffLocation();
      ref.read(mapProvider.notifier).clearRideSelection();
      ref.read(rideRoomProvider.notifier).clearDraftSpecialRequest();

      ref
          .read(rideRoomProvider.notifier)
          .updateCurrentSheet(RideSheetsType.whereToGoSheet);
    }
  }

  int _averageTimeMinutes(int seconds) {
    if (seconds <= 0) return 0;
    return (seconds / 60).ceil();
  }

  String _formatAverageTime(int minutes) {
    if (minutes <= 0) return '-- ${context.l10n.mins_label}';
    return minutes.formatAvgTime(context);
  }

  String _formatDistanceMiles(double distanceMiles) {
    if (distanceMiles <= 0) return '-- ${context.l10n.miles}';
    return '${distanceMiles.toStringAsFixed(2)} ${context.l10n.miles}';
  }

  String _formatFare(num? fare, bool isLoading) {
    if (isLoading) return '...';
    if (fare == null) return '\$--';
    return '\$${fare.toStringAsFixed(2)}';
  }

  Future<void> _onFindRideTap(MapState mapState) async {
    final l10n = context.l10n;
    final pickup = mapState.pickup;
    final dropOff = mapState.dropOff;
    final String? selectedRideType =
        _selectedRideId ?? mapState.selectedRideType;

    if (mapState.isFareLoading) {
      context.showErrorToast(l10n.please_wait_for_calculation);
    }

    if (pickup == null || dropOff == null) {
      context.showErrorToast(l10n.select_pickup_dropoff);
      return;
    }

    if (pickup.latLng == dropOff.latLng) {
      context.showErrorToast("Pickup and dropoff locations cannot be the same");
      return;
    }
    if (selectedRideType == null || selectedRideType.trim().isEmpty) {
      context.showErrorToast(l10n.select_ride_type_error);
      return;
    }
    final bool isCarpool = selectedRideType == 'carpool';
    if (!isCarpool && mapState.estimatedFare == null) {
      context.showErrorToast(l10n.select_ride_type_error);
      return;
    }
    if (mapState.routeDistanceKm <= 0) {
      context.showErrorToast(l10n.unable_calculate_distance);
      return;
    }
    if ((mapState.estimatedFare ?? 0.0) < 1) {
      context.showErrorToast(l10n.fare_too_low);
      return;
    }

    final num unitOriginalFare = mapState.estimatedFare ?? 0;

    final num rideFare = _rideFareFor(isCarpool, mapState);
    // A ride a promotion covers in full never touches Stripe or the wallet, so
    // it goes out without a payment method instead of demanding one.
    final bool isFreeRide = rideFare <= 0;
    final num? originalRideFare =
        (mapState.hasAppliedPromoCode &&
            mapState.appliedPromo != null &&
            mapState.appliedPromo!.fares.isNotEmpty &&
            mapState.appliedPromo!.fares[0].discountApplied)
        ? (isCarpool ? (unitOriginalFare * _passengerCount) : unitOriginalFare)
        : null;

    final params = FindRideParams(
      originalRideFare: originalRideFare,
      specialRequest: specialRequestController.text.trim(),
      pickupPoint: FindRidePointParams(
        placeName: pickup.name,
        location: FindRideLocationParams(
          coordinates: <double>[
            pickup.latLng.longitude,
            pickup.latLng.latitude,
          ],
        ),
      ),
      dropOffPoint: FindRidePointParams(
        placeName: dropOff.name,
        location: FindRideLocationParams(
          coordinates: <double>[
            dropOff.latLng.longitude,
            dropOff.latLng.latitude,
          ],
        ),
      ),
      category: selectedRideType,
      rideDistance: ref
          .read(mapProvider.notifier)
          .distanceInMiles(mapState.routeDistanceKm),
      rideFare: rideFare,
      averageTime: _averageTimeMinutes(mapState.routeDurationSeconds),
      requiredSeats: isCarpool ? _passengerCount : 1,
      paymentMethod: isFreeRide ? null : _method.name,
      codeId: mapState.promoCodeId,
      campaignId: mapState.promoCampaignId,
      // Same value the fare calculator receives, so an upgrade quote uses the
      // city's rate.
      pickupCity: mapState.pickup?.city,
      discountAmount:
          (mapState.hasAppliedPromoCode &&
              mapState.appliedPromo != null &&
              mapState.appliedPromo!.fares.isNotEmpty)
          ? mapState.appliedPromo!.fares[0].discountAmount
          : null,
    );

    setState(() => _isSubmitting = true);
    ref
        .read(rideRoomProvider.notifier)
        .setDraftSpecialRequest(specialRequestController.text);
    if (isCarpool) {
      await context.pushNamed(Routes.availableCarpoolRides.name, extra: params);
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    } else {
      await ref.read(rideRoomProvider.notifier).findRide(params);
    }
  }
}

class _PassengerCounter extends StatelessWidget {
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _PassengerCounter({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget buildCircleButton({
      required IconData icon,
      required VoidCallback? onTap,
    }) {
      final bool isEnabled = onTap != null;
      return CustomTap(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brandLight,
          ),
          child: Icon(
            icon,
            color: isEnabled ? colors.brand : colors.textSecondary,
            size: 18,
          ),
        ),
      );
    }

    return AppGradientBox(
      cornerRadius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildCircleButton(icon: Icons.remove, onTap: onDecrement),
            Text(
              value.toString(),
              style: context.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            buildCircleButton(icon: Icons.add, onTap: onIncrement),
          ],
        ),
      ),
    );
  }
}
