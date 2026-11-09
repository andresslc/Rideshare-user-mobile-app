import 'package:ride_app/features/ride_room/domain/entities/ride_search_status_entity.dart';

/// One side of an upgrade offer: a category and the fare the backend quoted
/// for it. The app never computes these fares.
class RideUpgradeFareEntity {
  final String category;
  final double fare;

  const RideUpgradeFareEntity({required this.category, required this.fare});
}

/// The rider's promo code does not apply to the offered category and is lost
/// if they accept.
class RideUpgradePromoEntity {
  final bool dropped;
  final String? reason;

  /// Amount the rider gives up by accepting.
  final double? lostDiscount;

  const RideUpgradePromoEntity({
    required this.dropped,
    this.reason,
    this.lostDiscount,
  });
}

/// The Economy ladder ran out and the backend offers to search again for a
/// higher category on the same ride (`ride:upgrade:offer`).
///
/// Re-sent on `ride:resume` with the remaining time, so the countdown always
/// comes from [expiresAt], never from a local timer.
class RideUpgradeOfferEntity {
  final String? rideId;
  final RideUpgradeFareEntity from;
  final RideUpgradeFareEntity to;

  /// Null when the ride had no promo code.
  final RideUpgradePromoEntity? promoCode;
  final int decisionSeconds;

  /// Null only if the backend sent something unparseable; the offer is then
  /// treated as already expired.
  final DateTime? expiresAt;

  /// Already translated and filled in by the backend. Editable from the panel,
  /// so it wins over the app's own copy.
  final String? message;
  final int searchAttempt;

  const RideUpgradeOfferEntity({
    this.rideId,
    required this.from,
    required this.to,
    this.promoCode,
    required this.decisionSeconds,
    this.expiresAt,
    this.message,
    this.searchAttempt = 0,
  });

  bool get dropsPromoCode => promoCode?.dropped == true;

  Duration remaining([DateTime? now]) {
    final DateTime? end = expiresAt;
    if (end == null) return Duration.zero;
    final Duration left = end.difference(now ?? DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool isExpired([DateTime? now]) => remaining(now) == Duration.zero;
}

/// How an upgrade offer ended (`ride:upgrade:result`).
class RideUpgradeResultEntity {
  final String? rideId;

  /// `accepted`, `declined`, `timed_out`, `payment_failed` or `superseded`.
  final String outcome;
  final String? rideType;
  final double? rideFare;
  final int searchAttempt;
  final String? message;

  const RideUpgradeResultEntity({
    this.rideId,
    required this.outcome,
    this.rideType,
    this.rideFare,
    this.searchAttempt = 0,
    this.message,
  });

  bool get isAccepted => outcome == RideUpgradeOutcome.accepted;
}

class RideUpgradeOutcome {
  RideUpgradeOutcome._();

  static const String accepted = 'accepted';
  static const String declined = 'declined';
  static const String timedOut = 'timed_out';
  static const String paymentFailed = 'payment_failed';
  static const String superseded = 'superseded';
}

/// Ack of `ride:upgrade:decide`. On success the new search has already begun;
/// on refusal [reason] says why.
class RideUpgradeDecisionEntity {
  final bool success;
  final String? message;
  final String? reason;
  final String? rideId;
  final String? rideType;
  final double? rideFare;
  final int? searchAttempt;

  /// First ring of the new search, already open when the ack lands.
  final RideSearchStatusEntity? search;

  const RideUpgradeDecisionEntity({
    required this.success,
    this.message,
    this.reason,
    this.rideId,
    this.rideType,
    this.rideFare,
    this.searchAttempt,
    this.search,
  });
}

/// Refusal reasons of `ride:upgrade:decide`.
class RideUpgradeRefusal {
  RideUpgradeRefusal._();

  static const String offerNotPending = 'OFFER_NOT_PENDING';
  static const String offerExpired = 'OFFER_EXPIRED';
  static const String rideAlreadyAccepted = 'RIDE_ALREADY_ACCEPTED';
  static const String insufficientWalletBalance =
      'INSUFFICIENT_WALLET_BALANCE';
  static const String noActiveCard = 'NO_ACTIVE_CARD';
  static const String notYourRide = 'NOT_YOUR_RIDE';
}

enum RideUpgradeDecision {
  accept('accept'),
  decline('decline');

  const RideUpgradeDecision(this.value);
  final String value;
}
