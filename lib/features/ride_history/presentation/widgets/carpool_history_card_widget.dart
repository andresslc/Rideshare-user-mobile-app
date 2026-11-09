import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/extensions/string_extension.dart';
import 'package:ride_app/features/ride_history/domain/enitities/carpool_history_entities.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';
import 'package:ride_app/shared/widgets/ride_driver_info.dart';
import 'package:ride_app/shared/widgets/rider_history_header.dart';
import 'package:ride_app/shared/widgets/verticle_location_stepper.dart';

class CarpoolHistoryCard extends StatelessWidget {
  final CarpoolRideEntity carpoolride;

  const CarpoolHistoryCard({super.key, required this.carpoolride});

  @override
  Widget build(BuildContext context) {
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

      isPlain: true,
      padding: const EdgeInsets.all(16),
      radius: 24,

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
          // const SizedBox(height: 10.0),
          // RideStatsRow(
          //   totalTime: "${carpoolride.avgTime.toStringAsFixed(0)} ${l10n.min}",
          //   totalDistance:
          //       "${carpoolride.distance.toStringAsFixed(2)}  ${l10n.miles}",
          //   totalAmount: '\$${carpoolride.fareCharged.toStringAsFixed(2)}',
          //   showAvgTime: true,
          //   showTotalFare: true,
          // ),
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
