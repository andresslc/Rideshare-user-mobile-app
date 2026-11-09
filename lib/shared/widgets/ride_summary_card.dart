import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/ride_driver_info.dart';
import 'package:ride_app/shared/widgets/ride_stats_row.dart';
import 'package:ride_app/shared/widgets/rider_history_header.dart';
import 'package:ride_app/shared/widgets/verticle_location_stepper.dart';

class RideSummaryCard extends StatelessWidget {
  const RideSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGradientBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RideTopInfo(rideType: "Economy Ride", status: "Completed"),
          const SizedBox(height: 8.0),
          const DriverInfoSection(
            profileImage: AppImages.sedan,
            userName: "Joshwa",
            rating: 1.8,
            carImage: AppImages.sedan,
            carMake: "sedan",
            plateNo: "No city",
            showCarInfo: true,
          ),
          const SizedBox(height: 8.0),
          const VerticleLocationStepper(
            locationList: ["123 Main St", "456 Elm St"],
            startTime: "10:00 AM",
            endTime: "10:30 AM",
          ),
          const SizedBox(height: 10.0),
          RideStatsRow(
            totalTime: "40:00",
            totalDistance: "50 ${l10n.miles}",
            estimateFare: "\$45.00",
          ),
        ],
      ),
    );
  }
}
