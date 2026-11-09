import 'package:ride_app/features/ride_history/domain/enitities/carpool_history_detail_entities.dart';
import 'package:ride_app/features/ride_history/domain/enitities/ride_history_detail_entities.dart';
import 'package:ride_app/features/ride_history/domain/enitities/ride_history_entites.dart';

import '../../domain/enitities/carpool_history_entities.dart';

sealed class RideHistoryStates {
  const RideHistoryStates();
}

class RideHistoryInitial extends RideHistoryStates {
  const RideHistoryInitial();
}

class RideHistoryLoading extends RideHistoryStates {
  const RideHistoryLoading();
}

class RideHistoryError extends RideHistoryStates {
  final String message;
  const RideHistoryError(this.message);
}

class RidehistorySucces extends RideHistoryStates {
  final List<RideEntity> rides;
  final bool hasMore;

  const RidehistorySucces({required this.rides, required this.hasMore});
}

class RideDetailSuccess extends RideHistoryStates {
  final RideDetailEntity ride;

  const RideDetailSuccess({required this.ride});
}

//Carpool state

sealed class CarpoolRideHistoryStates {
  const CarpoolRideHistoryStates();
}

class CarpoolRideHistoryInitial extends CarpoolRideHistoryStates {
  const CarpoolRideHistoryInitial();
}

class CarpoolRideHistoryLoading extends CarpoolRideHistoryStates {
  const CarpoolRideHistoryLoading();
}

class CarpoolRideHistoryError extends CarpoolRideHistoryStates {
  final String message;
  const CarpoolRideHistoryError(this.message);
}

class CarpoolRideHistorySuccess extends CarpoolRideHistoryStates {
  final List<CarpoolRideEntity> rides;
  final bool hasMore;

  const CarpoolRideHistorySuccess({required this.rides, required this.hasMore});
}

//carpoool detail

sealed class CarpoolDetailStates {
  const CarpoolDetailStates();
}

class CarpoolDetailInitial extends CarpoolDetailStates {
  const CarpoolDetailInitial();
}

class CarpoolDetailLoading extends CarpoolDetailStates {
  const CarpoolDetailLoading();
}

class CarpoolDetailError extends CarpoolDetailStates {
  final String message;

  const CarpoolDetailError(this.message);
}

class CarpoolDetailSuccess extends CarpoolDetailStates {
  final CarpoolEntity carpool;

  const CarpoolDetailSuccess({required this.carpool});
}
