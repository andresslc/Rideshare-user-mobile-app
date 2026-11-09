import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/ride_room/enums/ride_enum.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_text_field.dart';
import 'package:ride_app/shared/widgets/custom_dialogue.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';

import '../states/carpool_state.dart';
import '../states/ride_room_state.dart';

Future<bool> showCancelRideConfirmation(BuildContext context) async {
  final l10n = context.l10n;
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return GradientSideDialog(
        title: l10n.cancel_ride_request,
        subtitle: l10n.cancel_ride_confirmation,
        // Same warning icon as the "no drivers" panel and dialog.
        imagePath: AppIcons.danger,
        buttons: [
          AppButton(
            text: l10n.cancel,
            fontColor: context.appColors.brand,
            backgroundColor: context.appColors.border,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton(
            text: l10n.confirm,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}

Future<void> cancelRideWithConfirmation({
  required BuildContext context,
  required WidgetRef ref,
  required String? rideId,
  bool askCancellationReason = true,
  required bool isPendingRequestCancelled,
}) async {
  final bool shouldCancel = await showCancelRideConfirmation(context);
  if (!shouldCancel) return;
  if (!context.mounted) return;

  String? cancellationReason;
  if (askCancellationReason) {
    final rideState = ref.read(rideRoomProvider);
    final carpoolState = ref.read(carpoolProvider);
    final bool showPickupTooLongReason = !_shouldHidePickupTooLongReason(
      rideState,
      carpoolState,
    );
    cancellationReason = await showCancelRideReasonDialog(
      context,
      showPickupTooLongReason: showPickupTooLongReason,
    );
    if (cancellationReason == null) return;
    if (!context.mounted) return;
  }

  await ref
      .read(rideRoomProvider.notifier)
      .cancelRide(
        rideId: rideId,
        isPendingRequestCancelled: isPendingRequestCancelled,
        cancellationReason: cancellationReason,
      );

  final rideState = ref.read(rideRoomProvider);
  if (rideState.currentSheet == RideSheetsType.whereToGoSheet) {
    ref.read(mapProvider.notifier).clearRideMapData();
  }
}

bool _shouldHidePickupTooLongReason(
  RideRoomState rideState,
  CarpoolState carpoolState,
) {
  final bool normalRidePickedUp =
      rideState.currentRideType == RideType.inprogress ||
      rideState.currentRideType == RideType.completed ||
      rideState.currentRideType == RideType.cancelled;
  final bool carpoolPickedUp =
      carpoolState.isInProgress || carpoolState.otpVerified;
  return normalRidePickedUp || carpoolPickedUp;
}

Future<String?> showCancelRideReasonDialog(
  BuildContext context, {
  required bool showPickupTooLongReason,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CancelRideReasonSheet(
      showPickupTooLongReason: showPickupTooLongReason,
    ),
  );
}

class _CancelRideReasonSheet extends StatefulWidget {
  const _CancelRideReasonSheet({required this.showPickupTooLongReason});

  final bool showPickupTooLongReason;

  @override
  State<_CancelRideReasonSheet> createState() => _CancelRideReasonSheetState();
}

class _CancelRideReasonSheetState extends State<_CancelRideReasonSheet> {
  static List<String> _presetLabels(
    AppLocalizations l10n, {
    required bool showPickupTooLongReason,
  }) => <String>[
    l10n.rider_cancel_reason_driver_not_responding,
    l10n.rider_cancel_reason_driver_asked_cancel,
    if (showPickupTooLongReason) l10n.rider_cancel_reason_pickup_too_long,
    l10n.rider_cancel_reason_changed_plans,
    l10n.rider_cancel_reason_booked_mistake,
    l10n.rider_cancel_reason_other,
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  int _selectedIndex = 0;

  bool get _shouldShowCustomReason =>
      _selectedIndex ==
      _presetLabels(
            context.l10n,
            showPickupTooLongReason: widget.showPickupTooLongReason,
          ).length -
          1;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit(List<String> presetLabels) {
    if (_shouldShowCustomReason && !_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _shouldShowCustomReason
          ? _reasonController.text.trim()
          : presetLabels[_selectedIndex],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final presetLabels = _presetLabels(
      l10n,
      showPickupTooLongReason: widget.showPickupTooLongReason,
    );
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PlainBackgroundWidget(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset + 12),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ).copyWith(top: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.appColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.cancellationReason,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontSize: 20,
                          ),
                        ),
                      ),
                      CustomTap(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.cancel_ride_question,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(presetLabels.length, (index) {
                    final reason = presetLabels[index];
                    final selected = _selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                            if (!_shouldShowCustomReason) {
                              _reasonController.clear();
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? context.appColors.border
                                : Colors.transparent,
                            border: Border.all(
                              color: selected
                                  ? context.appColors.brand
                                  : context.appColors.border,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reason,
                                  style: context.textTheme.bodyLarge,
                                ),
                              ),
                              Radio<int>(
                                value: index,
                                // ignore: deprecated_member_use
                                groupValue: _selectedIndex,
                                // ignore: deprecated_member_use
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedIndex = value;
                                    if (!_shouldShowCustomReason) {
                                      _reasonController.clear();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_shouldShowCustomReason) ...[
                    const SizedBox(height: 6),
                    AppTextField(
                      radius: 10,
                      hintText: l10n.reason,
                      maxLength: 300,
                      controller: _reasonController,
                      validator: Validators.requiredFieldValidator,
                      maxlines: 3,
                      isPlain: true,
                      autoFocus: true,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: l10n.cancel,
                          fontColor: context.appColors.brand,
                          backgroundColor: context.appColors.border,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: l10n.submit,
                          onPressed: () => _submit(presetLabels),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
