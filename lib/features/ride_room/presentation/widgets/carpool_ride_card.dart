import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_option_entity.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/ride_driver_info.dart';
import 'package:ride_app/shared/widgets/ride_stats_row.dart';
import 'package:ride_app/shared/widgets/slide_animated_button.dart';
import 'package:ride_app/shared/widgets/verticle_location_stepper.dart';

class CarpoolRideCard extends StatelessWidget {
  const CarpoolRideCard({
    super.key,
    required this.option,
    this.requestSent = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.useSlideButton = true,
    this.showFarePerPerson = false,
    this.actionText,
    this.onActionPressed,
  });

  final CarpoolOptionEntity option;
  final bool requestSent;
  final bool isLoading;
  final bool isDisabled;
  final bool useSlideButton;
  final bool showFarePerPerson;
  final String? actionText;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    const hp = EdgeInsets.symmetric(horizontal: AppSizes.p16);
    final fareText = '\$${option.fareMax.toStringAsFixed(2)}';
    final avgTimeStr = (option.avgTimeMinutes).formatAvgTime(context);
    // (carpoolride.avgTime).formatAvgTime(context)
    final distanceStr =
        '${option.totalDistanceKm.toStringAsFixed(2)} ${l10n.miles}';

    return AppGradientBox(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.p16,
        // horizontal: AppSizes.p16,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.carpool_ride,
              style: context.textTheme.titleMedium?.copyWith(
                color: colors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: AppSizes.p20),
            DriverInfoSection(
              profileImage: option.driverProfileImage,
              userName: option.driverName,
              rating: option.driverRating,
              carImage: AppImages.sedan,
              wantChatIcon: false,
              showCarInfo: true,
              showTopBorder: false,
              carMake: option.carName,
              plateNo: option.plate,
            ),
            const Divider(height: AppSizes.p20),
            Padding(
              padding: hp,
              child: _CarpoolLocationSection(stops: option.locationStops),
            ),
            const Divider(height: AppSizes.p20),
            Padding(
              padding: hp,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.ride_start_time,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    option.rideStartTime,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p8),

            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.appColors.border, width: 1),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p8),
            Padding(
              padding: hp,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.available_seats_label,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    l10n.seats_count(option.availableSeats),
                    style: context.textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // const Divider(height: AppSizes.p16),
            const SizedBox(height: AppSizes.p16),
            RideStatsRow(
              totalTime: avgTimeStr,
              totalDistance: distanceStr,
              estimateFare: fareText,
              totalAmountSuffix: showFarePerPerson ? l10n.persen : null,
            ),
            const Divider(height: AppSizes.p12),
            const SizedBox(height: AppSizes.p16),
            useSlideButton
                ? SlideToConfirm(
                    text: actionText ?? l10n.send_request,
                    acceptedText: l10n.request_sent,
                    isLoading: isLoading,
                    isAccepted: requestSent,
                    isDisabled: isDisabled || requestSent || isLoading,
                    onSubmit: onActionPressed,
                  )
                : AppButton(
                    text: isLoading
                        ? l10n.please_wait
                        : (requestSent
                              ? l10n.request_sent
                              : (actionText ?? l10n.send_request)),
                    onPressed: isDisabled || requestSent || isLoading
                        ? null
                        : onActionPressed,
                    isDisable: isDisabled || requestSent || isLoading,
                  ),
          ],
        ),
      ),
    );
  }
}

class _CarpoolLocationSection extends StatelessWidget {
  const _CarpoolLocationSection({required this.stops});

  final List<String> stops;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    if (stops.isEmpty) return const SizedBox();
    if (stops.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.location,
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          Text(
            stops.first,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return VerticleLocationStepper(
      locationList: stops,
      showTopBorder: false,
      startTime: '--:--',
      endTime: '--:--',
    );
  }
}
