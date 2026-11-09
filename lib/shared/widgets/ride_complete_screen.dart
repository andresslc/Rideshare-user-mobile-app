// import 'package:ride_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/shared.dart';
import 'package:ride_app/shared/widgets/custom_dialogue.dart';
import 'package:ride_app/shared/widgets/input_dialogue.dart';
import 'package:ride_app/shared/widgets/loader.dart';

import '../../core/params/report_params.dart';
import '../../features/reviews/presentation/providers/report_provider.dart';
import '../../features/reviews/presentation/states/report_state.dart';
import '../../features/ride_room/presentation/providers/ride_room_provider.dart';

class RideCompleteScreen extends ConsumerStatefulWidget {
  const RideCompleteScreen({super.key});

  @override
  ConsumerState<RideCompleteScreen> createState() => _RideCompleteScreenState();
}

class _RideCompleteScreenState extends ConsumerState<RideCompleteScreen> {
  final CustomLoader loader = CustomLoader();
  void showReportDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (_) => InputDialog(
        isRequired: false,
        title: l10n.report_driver,
        subtitle: l10n.we_appreciate_issue,
        hintText: l10n.reason,
        buttonText: l10n.submit,
        textCapitalization: TextCapitalization.sentences,
        onSubmit: (description) {
          context.pop();
          submitReport(description);
        },
      ),
    );
  }

  void submitReport(String description) {
    final rideState = ref.read(rideRoomProvider);
    final String entityId =
        rideState.currentRide?.driverId ??
        rideState.currentRide?.driver?.id ??
        '';
    final String rideId = rideState.currentRide?.id ?? '';
    final String trimmedDescription = description.trim();
    if (entityId.trim().isEmpty) {
      context.showErrorToast(context.l10n.somethingWentWrong);
      return;
    }
    if (rideId.trim().isEmpty) {
      context.showErrorToast(context.l10n.somethingWentWrong);
      return;
    }
    if (trimmedDescription.isEmpty) {
      context.showToast(context.l10n.please_reason);
      return;
    }

    final param = ReportParam(
      entityId: entityId,
      entityType: "Driver",
      // reason: "Inappropriate behavior",
      reason: trimmedDescription,
      supportingEntityId: rideId,
      supportingEntityType: "Ride",
    );

    ref.read(reportProvider.notifier).reportsubmit(param);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenWidth = MediaQuery.of(context).size.width;
    final rideState = ref.watch(rideRoomProvider);
    final ride = rideState.currentRide;
    final String totalDistanceText = ride == null
        ? '--'
        : '${ride.rideDistance.toStringAsFixed(2)}  ${l10n.miles}';

    final String rideTimeText = ride == null
        ? '--'
        : (ride.averageTime).formatAvgTime(context);
    final String totalFareText = ride == null
        ? '--'
        : ride.rideFare.toStringAsFixed(2);
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
          if (context.mounted) {
            context.pop(); // close dialog
            context.pop(); // redirect to home
          }
        });
      }
    });

    return AppScaffold(
      scrollable: true,
      resizeToAvoidBottomInset: true,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        title: Text(l10n.ride_complete)
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // mainAxisAlignment: MainAxisAlignment.str,
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
                          'driver': ride!.driver,
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const Gap(10),
            AppButton(
              // fontColor: context.appColors.textPrimary,
              fontColor: context.appColors.brand,
              backgroundColor: context.appColors.lightButton,
              text: l10n.skip,
              onPressed: () {
                context.pop();
              },
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          // clipBehavior: Clip.none,
          // alignment: Alignment.topCenter,
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
                  Image.asset(AppIcons.tick, height: context.screenWidth * 0.2)
                      .animate()
                      .scale(
                        begin: const Offset(0.3, 0.3),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(),
                  const SizedBox(height: 24),
                  TextComponent(
                        text: l10n.thank_you_for_riding,
                        style: context.textTheme.labelLarge?.copyWith(
                          fontSize: 25,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                  const Gap(8),
                  Text(
                    l10n.see_you_on_your_next_trip,
                    style: context.textTheme.bodyLarge,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                ],
              ),
            ),
            // const Gap(155),
            // Ride Details Box
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  RideDetailRow(
                    label: l10n.total_distance,
                    value: totalDistanceText,
                    // '${startRideController.onGoingRide.value!.rideDistance} KM',
                  ),
                  const Gap(12),
                  RideDetailRow(label: l10n.ride_time, value: rideTimeText),
                  const Gap(12),
                  RideDetailRow(
                    label: l10n.total_fare,
                    value: totalFareText,
                    showCurrency: true,
                    // '\$${startRideController.onGoingRide.value?.actualFare?.toStringAsFixed(2) ?? "--"}',
                    isPrimary: true,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
            // const Gap(141),
          ],
        ),
      ),
    );
  }
}

class RideDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;
  final bool showCurrency;
  const RideDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.isPrimary = false,
    this.showCurrency = false,
  });
  @override
  Widget build(BuildContext context) {
    final displayValue = showCurrency ? '\$$value' : value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextComponent(text: label, fontsize: 14, fontWeight: FontWeight.w500),
        TextComponent(
          text: displayValue,
          fontsize: isPrimary ? 25 : 14,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}

class TextComponent extends StatelessWidget {
  const TextComponent({
    super.key,
    required this.text,
    this.fontsize = 14,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.style,
  });

  final String text;
  final double fontsize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style:
          style ??
          TextStyle(
            fontSize: fontsize,
            fontWeight: fontWeight,
            color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
          ),
    );
  }
}
