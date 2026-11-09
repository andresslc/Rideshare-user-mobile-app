import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';
import 'package:ride_app/shared/widgets/ride_driver_info.dart';
import 'package:ride_app/shared/widgets/ride_stats_row.dart';
import 'package:ride_app/shared/widgets/rider_history_header.dart';
import 'package:ride_app/shared/widgets/verticle_location_stepper.dart';

import '../../domain/enitities/carpool_history_entities.dart';

class CompleteHistoryCard extends StatelessWidget {
  final CarpoolRideEntity carpoolride;

  const CompleteHistoryCard({super.key, required this.carpoolride});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final List<String> locations = [
      carpoolride.startingPoint.placeName,

      ...carpoolride.routes
          .map((r) => r.placeName)
          .where(
            (place) =>
                place != carpoolride.startingPoint.placeName &&
                place != carpoolride.destination.placeName,
          ),

      carpoolride.destination.placeName,
    ];

    return PlainBackgroundWidget(
      isAllRounded: true,
      radius: 24,
      isPlain: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RideTopInfo(
            rideType: context.l10n.carpool_ride,
            status: _localizedStatus(context, carpoolride.status),
            statusKey: carpoolride.status,
          ),
          const SizedBox(height: 8.0),
          DriverInfoSection(
            driverId: carpoolride.driver.id,
            profileImage: carpoolride.driver.profilePicture ?? '',
            userName: carpoolride.driver.fullName.titleCase,
            rating: carpoolride.driver.rating.toDouble(),
            carImage: AppImages.sedan,
            carMake:
                "${carpoolride.driver.vehicleDetails.make} ${carpoolride.driver.vehicleDetails.vehicleType}",
            plateNo:
                "  ${carpoolride.driver.vehicleDetails.licensePlateNumber}-${carpoolride.driver.vehicleDetails.model}",
            showCarInfo: true,
          ),
          const SizedBox(height: 8.0),
          VerticleLocationStepper(
            locationList: locations,
            startTime: context.l10n.start_label,
            endTime: context.l10n.end_label,
          ),
          const SizedBox(height: 10.0),
          RideStatsRow(
            totalTime: (carpoolride.avgTime).formatAvgTime(context),
            totalDistance:
                "${carpoolride.distance.toStringAsFixed(2)}  ${l10n.miles}",
            estimateFare:
                (carpoolride.requiredSeats > 0 &&
                    carpoolride.requiredSeats < 100)
                ? '\$${(carpoolride.fareCharged / carpoolride.requiredSeats).toStringAsFixed(2)}'
                : '\$${carpoolride.fareCharged.toStringAsFixed(2)}',
            totalAmountSuffix: context.l10n.persen,
            // showAvgTime: true,
          ),
        ],
      ),
    );
  }
}

String _localizedStatus(BuildContext context, String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return context.l10n.completed;
    case 'cancelled':
      return context.l10n.cancelled;
    default:
      return status.capitalised;
  }
}
