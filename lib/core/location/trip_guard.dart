import 'package:ride_app/features/ride_room/domain/entities/ride_entity.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';

/// Shared rules for detecting an in-progress trip (banner vs full slow-network block).
abstract final class TripGuard {
  static bool hasActiveRide(RideEntity? ride) {
    if (ride == null) return false;

    final String rideStatus = ride.rideStatus.trim().toLowerCase();
    if (rideStatus.isEmpty) return true;

    switch (rideStatus) {
      case 'completed':
      case 'cancelled':
      case 'canceled':
      case 'dropped':
        return false;
      default:
        return true;
    }
  }

  static bool hasActiveTripFromState(RideRoomState state) {
    if (hasActiveRide(state.currentRide)) {
      return true;
    }

    switch (state.currentRideType) {
      case RideType.accepted:
      case RideType.arrived:
      case RideType.coming:
      case RideType.inprogress:
        return true;
      case RideType.completed:
      case RideType.cancelled:
      case RideType.locationAccess:
      case RideType.requested:
      case RideType.expired:
      case null:
        break;
    }

    final String? statusType = state.latestRideStatus?.type
        ?.trim()
        .toLowerCase();
    if (statusType == null || statusType.isEmpty) {
      return false;
    }

    switch (statusType) {
      case 'completed':
      case 'cancelled':
      case 'canceled':
      case 'dropped':
        return false;
      case 'accepted':
      case 'arrived':
      case 'coming':
      case 'in-progress':
      case 'inprogress':
      case 'started':
      case 'active':
        return true;
      default:
        return false;
    }
  }
}
