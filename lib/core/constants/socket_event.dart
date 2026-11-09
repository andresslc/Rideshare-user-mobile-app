class SocketEvent {
  SocketEvent._();

  // Ride
  // Events
  static const String rideRequest = 'ride:request:create';
  static const String rideCancel = 'ride:cancel';

  // Listenners
  static const String driverLocationUpdate = 'driver:location:update';
  static const String rideStatusUpdate = 'ride:status:update';
  static const String rideResume = 'ride:resume';
  static const String ridePaymentVerification = 'ride:payment:verification';

  /// Dispatch progress: one event per ring of the escalating driver search.
  static const String rideSearchStatus = 'ride:search:status';

  /// The ladder ran out of rings without a driver taking the ride.
  static const String rideSearchExhausted = 'ride:search:exhausted';

  /// The Economy ladder ran out and the backend offers the same ride as
  /// Luxury. Sent instead of [rideSearchExhausted] when the feature is on.
  static const String rideUpgradeOffer = 'ride:upgrade:offer';

  /// Rider's answer to [rideUpgradeOffer], with ack.
  static const String rideUpgradeDecide = 'ride:upgrade:decide';

  /// How an upgrade offer ended, including outcomes the rider didn't trigger.
  static const String rideUpgradeResult = 'ride:upgrade:result';

  static const String chatReceive = 'chat:receive';
  static const String chatRead = 'chat:read';
  static const String chatStatusUpdated = 'chat:status_updated';

  // Carpool Ride

  static const String carpoolIncomingMatches = 'carpool:incoming_matches';
  static const String carpoolJoin = 'carpool:join';
  static const String carpoolCancelRequest = 'carpool:cancel_request';
  static const String carpoolComplete = 'carpool:complete';

  // Carpool Listenners
  static const String carpoolBookingStatus = 'carpool:booking_status';
  static const String carpoolRideStarted = 'carpool:ride_started';
  static const String carpoolPassengerPickedUp = 'carpool:passenger_picked_up';
  static const String carpoolRideCompleted = 'carpool:ride_completed';
  static const String carpoolPaymentVerification =
      'carpool:payment:verification';
  static const String carpoolStopArrived = 'carpool:stop_arrived';
  static const String carpoolResume = 'carpool:resume';
  static const String carpoolRouteUpdate = 'carpool:route_update';

  // User
  static const String userLocationUpdate = 'user:location:update';

  // Generic
  static const String socketError = 'error';
}
