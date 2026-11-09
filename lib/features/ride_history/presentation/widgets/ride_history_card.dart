import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/ride_history/domain/enitities/ride_history_entites.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';
import 'package:ride_app/shared/widgets/ride_driver_info.dart';
import 'package:ride_app/shared/widgets/ride_stats_row.dart';
import 'package:ride_app/shared/widgets/rider_history_header.dart';
import 'package:ride_app/shared/widgets/verticle_location_stepper.dart';

class RideHistoryCard extends StatelessWidget {
  final RideEntity ride;

  const RideHistoryCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timeFormatter = DateFormat('h:mm a', 'en');
    final localizedRideType = _localizedRideType(context, ride.rideType);
    final localizedStatus = _localizedStatus(context, ride.rideStatus);
    final rideStartLocal = ride.createdAt.toLocal();
    return PlainBackgroundWidget(
      isAllRounded: true,
      radius: 24,
      isPlain: true,

      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RideTopInfo(
                  rideType: localizedRideType,
                  status: localizedStatus,
                  statusKey: ride.rideStatus,
                ),
                const SizedBox(height: 8.0),
                DriverInfoSection(
                  driverId: ride.driver.id,
                  profileImage: ride.driver.profilePicture,
                  userName: ride.driver.fullName.titleCase,
                  rating: ride.driver.rating.toDouble(),
                  carImage: AppImages.sedan,
                  carMake:
                      "${ride.driver.vehicle?.make ?? ""} ${ride.driver.vehicle?.vehicleType ?? ""}",
                  plateNo:
                      "  ${ride.driver.vehicle?.licensePlateNumber ?? ""}-${ride.driver.vehicle?.model ?? ""}",
                  showCarInfo: true,
                ),
                const SizedBox(height: 8.0),
                VerticleLocationStepper(
                  locationList: [
                    ride.pickupPoint.placeName,
                    ride.dropOffPoint.placeName,
                  ],
                  startTime: timeFormatter.format(rideStartLocal),
                  endTime: timeFormatter.format(
                    rideStartLocal.add(Duration(minutes: ride.averageTime)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          RideStatsRow(
            totalTime: (ride.averageTime.toDouble()).formatAvgTime(context),
            totalDistance:
                "${ride.rideDistance.toStringAsFixed(2)} ${l10n.miles}",
            estimateFare: "\$${ride.rideFare.toStringAsFixed(2)}",
          ),
        ],
      ),
    );
  }
}

String _localizedRideType(BuildContext context, String rideType) {
  switch (rideType.toLowerCase()) {
    case 'economy':
      return context.l10n.ride_type_economy;
    case 'private':
      return context.l10n.ride_type_private;
    case 'luxury':
      return context.l10n.ride_type_luxury;
    case 'standard':
      return context.l10n.ride_type_standard;
    default:
      return rideType.capitalised;
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
