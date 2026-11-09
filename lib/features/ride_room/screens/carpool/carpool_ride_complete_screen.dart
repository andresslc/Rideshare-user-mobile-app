import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/params/report_params.dart';
import 'package:ride_app/features/reviews/presentation/providers/report_provider.dart';
import 'package:ride_app/features/reviews/presentation/states/report_state.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/shared/shared.dart';
import 'package:ride_app/shared/widgets/custom_dialogue.dart';
import 'package:ride_app/shared/widgets/input_dialogue.dart';
import 'package:ride_app/shared/widgets/loader.dart';
import 'package:ride_app/shared/widgets/ride_complete_screen.dart';

import '../../enums/ride_enum.dart';

class CarpoolRideCompleteScreen extends ConsumerStatefulWidget {
  const CarpoolRideCompleteScreen({super.key});

  @override
  ConsumerState<CarpoolRideCompleteScreen> createState() =>
      _CarpoolRideCompleteScreenState();
}

class _CarpoolRideCompleteScreenState
    extends ConsumerState<CarpoolRideCompleteScreen> {
  final CustomLoader loader = CustomLoader();

  void showReportDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (_) => InputDialog(
        title: l10n.report_driver,
        subtitle: l10n.we_appreciate_issue,
        hintText: l10n.reason,
        textCapitalization: TextCapitalization.sentences,
        buttonText: l10n.submit,
        onSubmit: (description) {
          context.pop();
          submitReport(description);
        },
      ),
    );
  }

  void submitReport(String description) {
    final carpoolState = ref.read(carpoolProvider);
    final String entityId = carpoolState.requestedRide?.driver?.id ?? '';
    final String carpoolId =
        carpoolState.completedRide?.carpoolId ??
        carpoolState.requestedRide?.id ??
        '';
    final String trimmedDescription = description.trim();
    if (entityId.trim().isEmpty) {
      context.showErrorToast(context.l10n.somethingWentWrong);
      return;
    }
    if (carpoolId.trim().isEmpty) {
      context.showErrorToast(context.l10n.somethingWentWrong);
      return;
    }
    if (trimmedDescription.isEmpty) {
      context.showErrorToast(context.l10n.please_reason);
      return;
    }

    final param = ReportParam(
      entityId: entityId,
      entityType: "Driver",
      // reason: "",
      reason: trimmedDescription,
      supportingEntityId: carpoolId,
      supportingEntityType: "CarpoolRoute",
    );

    ref.read(reportProvider.notifier).reportsubmit(param);
  }

  void _closeScreen() {
    ref.read(carpoolProvider.notifier).clearCompletedRide();
    final mapNotifier = ref.read(mapProvider.notifier);
    mapNotifier.clearRideMapData();
    unawaited(mapNotifier.refreshCurrentLocation(moveCamera: true));
    ref
        .read(rideRoomProvider.notifier)
        .updateCurrentSheet(RideSheetsType.whereToGoSheet);
    if (GoRouter.of(context).canPop()) {
      context.pop();
      return;
    }
    context.goNamed(Routes.home.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenWidth = MediaQuery.of(context).size.width;
    final carpoolState = ref.watch(carpoolProvider);
    final ride = carpoolState.requestedRide;
    final completedRide = carpoolState.completedRide;
    final String totalDistanceText = ride == null
        ? '--'
        : '${ride.distance.toStringAsFixed(2)}  ${l10n.miles}';

    // '${ride.distance.toStringAsFixed(1)} KM';

    final String rideTimeText = ride == null
        ? '--'
        : (ride.avgTime).formatAvgTime(context);

    final String totalFareText = completedRide == null
        ? (ride?.fare.toStringAsFixed(2) ?? '--')
        : completedRide.fareCharged.toStringAsFixed(2);

    ref.listen<ReportState>(reportProvider, (previous, state) {
      if (state is ReportLoading) {
        loader.showLoader(context);
      } else if (state is ReportError) {
        loader.hideLoader();
        context.showToast(state.message);
      } else if (state is ReportSuccess) {
        loader.hideLoader();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => GradientSideDialog(
            title: context.l10n.report_submitted,
            subtitle: context.l10n.subtitle_dialgue,
            icon: Icons.check_rounded,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (!context.mounted) return;
          context.pop();
          _closeScreen();
        });
      }
    });

    return AppScaffold(
      scrollable: true,
      resizeToAvoidBottomInset: true,
      padding: EdgeInsets.zero,
      appBar: AppBar(title: Text(l10n.ride_complete)),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppButton(
                    backgroundColor: Colors.red,
                    fontColor: Colors.white,
                    text: l10n.report_driver,
                    onPressed: () => showReportDialog(context),
                  ),
                ),
                const Gap(7),
                Expanded(
                  child: AppButton(
                    backgroundColor: AppColors.brand,
                    text: l10n.leave_a_review,
                    onPressed: () {
                      context.pushNamed(
                        Routes.feedback.name,
                        extra: {
                          'rideId': ride?.id ?? '',
                          'carpoolId': ride?.id ?? '',
                          'driver': ride?.driver,
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const Gap(10),
            AppButton(
              fontColor: context.appColors.brand,
              backgroundColor: context.appColors.lightButton,
              text: l10n.skip,
              onPressed: _closeScreen,
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          // clipBehavior: Clip.none,
          // alignment: Alignment.center,
          children: [
            SizedBox(
              width: screenWidth,
              height: context.screenHeight * .62,
              child: Image.asset(AppImages.rideinvice, fit: BoxFit.fill),
            ),
            Positioned(
              top: 25,
              left: 25,
              right: 25,
              child: Column(
                children: [
                  Image.asset(AppIcons.tick, height: context.screenWidth * 0.2),
                  const SizedBox(height: 24),
                  TextComponent(
                    text: l10n.thank_you_for_riding,
                    style: context.textTheme.labelLarge?.copyWith(fontSize: 25),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    l10n.see_you_on_your_next_trip,
                    style: context.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            // const Gap(145),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  RideDetailRow(
                    label: l10n.total_distance,
                    value: totalDistanceText,
                  ),
                  const Gap(12),
                  RideDetailRow(label: l10n.ride_time, value: rideTimeText),
                  const Gap(12),
                  RideDetailRow(
                    label: l10n.total_fare,
                    value: totalFareText,
                    showCurrency: true,
                    isPrimary: true,
                  ),
                ],
              ),
            ),
            // const Gap(141),
          ],
        ),
      ),
    );
  }
}
