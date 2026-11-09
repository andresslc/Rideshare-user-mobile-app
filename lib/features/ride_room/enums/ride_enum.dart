import 'package:flutter/material.dart';

import '../../../core/extensions/context_extension.dart';

enum RideSheetsType {
  whereToGoSheet,
  selectRideSheet,
  findingDriverSheet,
  driverArrivedSheet,
  onGoingRideStatusSheet,
  // (onTheWay, rideStarted, inProgress, reachedDestination),
}

// ignore: constant_identifier_names
enum PaymentMethod { attached_card, wallet }

enum OnGoingRideStatus { onTheWay, rideStarted, inProgress, reachedDestination }

extension OnGoingRideStatusX on OnGoingRideStatus {
  String text(BuildContext context) {
    final l10 = context.l10n;

    switch (this) {
      case OnGoingRideStatus.onTheWay:
        return l10.driver_on_the_way;

      case OnGoingRideStatus.rideStarted:
        return l10.ride_started;

      case OnGoingRideStatus.inProgress:
        return l10.ride_in_progress;

      case OnGoingRideStatus.reachedDestination:
        return l10.reached_destination;
    }
  }
}
