import 'package:flutter_test/flutter_test.dart';
import 'package:ride_app/core/params/find_ride_params.dart';
import 'package:ride_app/features/app_config/data/models/ride_app_config_model.dart';
import 'package:ride_app/features/ride_room/data/models/ride_upgrade_model.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_upgrade_entity.dart';

// Payloads mirror the examples in the backend contract.
void main() {
  group('RideUpgradeOfferModel', () {
    test('parses the full offer, including the dropped promo code', () {
      final offer = RideUpgradeOfferModel.fromJson(<String, dynamic>{
        'rideId': '665f',
        'from': <String, dynamic>{'category': 'economy', 'fare': 18.50},
        'to': <String, dynamic>{
          'category': 'luxury',
          'fare': 31.20,
          'pricingSource': 'city',
          'city': 'miami',
        },
        'promoCode': <String, dynamic>{
          'dropped': true,
          'reason': 'PROMO_CODE_INVALID_RIDE_TYPE',
          'lostDiscount': 4.00,
        },
        'decisionSeconds': 30,
        'expiresAt': '2026-09-22T18:04:31.000Z',
        'message': 'server copy',
        'searchAttempt': 0,
      });

      expect(offer.rideId, '665f');
      expect(offer.from.category, 'economy');
      expect(offer.from.fare, 18.50);
      expect(offer.to.category, 'luxury');
      expect(offer.to.fare, 31.20);
      expect(offer.dropsPromoCode, isTrue);
      expect(offer.promoCode?.lostDiscount, 4.00);
      expect(offer.decisionSeconds, 30);
      expect(offer.expiresAt, DateTime.utc(2026, 9, 22, 18, 4, 31));
      expect(offer.message, 'server copy');
    });

    test('has no promo code when the field is omitted', () {
      final offer = RideUpgradeOfferModel.fromJson(<String, dynamic>{
        'from': <String, dynamic>{'category': 'economy', 'fare': '18.5'},
        'to': <String, dynamic>{'category': 'luxury', 'fare': '31.2'},
      });

      expect(offer.promoCode, isNull);
      expect(offer.dropsPromoCode, isFalse);
      expect(offer.from.fare, 18.5);
      expect(offer.to.fare, 31.2);
    });

    test('remaining time comes from expiresAt, not from decisionSeconds', () {
      final DateTime now = DateTime.utc(2026, 9, 22, 18, 4, 25);
      final offer = RideUpgradeOfferModel.fromJson(<String, dynamic>{
        'from': <String, dynamic>{'category': 'economy', 'fare': 1},
        'to': <String, dynamic>{'category': 'luxury', 'fare': 2},
        'decisionSeconds': 30,
        'expiresAt': '2026-09-22T18:04:31.000Z',
      });

      expect(offer.remaining(now), const Duration(seconds: 6));
      expect(offer.isExpired(now), isFalse);
      expect(offer.isExpired(DateTime.utc(2026, 9, 22, 18, 5)), isTrue);
    });

    test('an unparseable expiresAt reads as already expired', () {
      final offer = RideUpgradeOfferModel.fromJson(<String, dynamic>{
        'from': <String, dynamic>{'category': 'economy', 'fare': 1},
        'to': <String, dynamic>{'category': 'luxury', 'fare': 2},
        'expiresAt': 'not a date',
      });

      expect(offer.isExpired(), isTrue);
    });
  });

  group('RideUpgradeResultModel', () {
    test('parses an outcome the rider did not trigger', () {
      final result = RideUpgradeResultModel.fromJson(<String, dynamic>{
        'rideId': '665f',
        'outcome': 'timed_out',
        'rideType': 'economy',
        'rideFare': 18.50,
        'searchAttempt': 0,
      });

      expect(result.outcome, RideUpgradeOutcome.timedOut);
      expect(result.isAccepted, isFalse);
      expect(result.rideFare, 18.50);
    });
  });

  group('RideUpgradeDecisionModel', () {
    test('success ack carries the new fare and the first ring', () {
      final ack = RideUpgradeDecisionModel.fromAck(
        success: true,
        message: '',
        data: <String, dynamic>{
          'rideId': '665f',
          'rideType': 'luxury',
          'rideFare': 31.20,
          'searchAttempt': 1,
          'search': <String, dynamic>{
            'ring': 1,
            'radiusMiles': 1,
            'driversNotified': 3,
            'totalNotified': 3,
          },
        },
      );

      expect(ack.success, isTrue);
      expect(ack.message, isNull);
      expect(ack.rideType, 'luxury');
      expect(ack.rideFare, 31.20);
      expect(ack.search?.ring, 1);
      expect(ack.search?.radiusMiles, 1);
      expect(ack.search?.totalNotified, 3);
      expect(ack.search?.rideId, '665f');
    });

    test('refusal ack exposes the reason', () {
      final ack = RideUpgradeDecisionModel.fromAck(
        success: false,
        message: 'Not enough balance',
        data: <String, dynamic>{'reason': 'INSUFFICIENT_WALLET_BALANCE'},
      );

      expect(ack.success, isFalse);
      expect(ack.reason, RideUpgradeRefusal.insufficientWalletBalance);
      expect(ack.message, 'Not enough balance');
      expect(ack.search, isNull);
    });
  });

  group('ride config categoryUpgrade', () {
    test('is off and uses the plain search length when absent', () {
      final config = DispatchConfigModel.fromJson(<String, dynamic>{
        'totalRings': 4,
        'ringTimeoutSeconds': 10,
        'maxSearchSeconds': 40,
      });

      expect(config.categoryUpgrade.enabled, isFalse);
      expect(config.maxSearchSecondsWithUpgrade, isNull);
      expect(config.effectiveMaxSearchSeconds, 40);
    });

    test('uses the longer search length only when the feature is on', () {
      Map<String, dynamic> json(bool enabled) => <String, dynamic>{
        'totalRings': 4,
        'ringTimeoutSeconds': 10,
        'maxSearchSeconds': 40,
        'maxSearchSecondsWithUpgrade': 110,
        'categoryUpgrade': <String, dynamic>{
          'enabled': enabled,
          'decisionSeconds': 30,
          'map': <String, dynamic>{'economy': 'luxury'},
        },
      };

      final on = DispatchConfigModel.fromJson(json(true));
      final off = DispatchConfigModel.fromJson(json(false));

      expect(on.categoryUpgrade.enabled, isTrue);
      expect(on.categoryUpgrade.decisionSeconds, 30);
      expect(on.categoryUpgrade.map, <String, String>{'economy': 'luxury'});
      expect(on.effectiveMaxSearchSeconds, 110);
      expect(off.effectiveMaxSearchSeconds, 40);
    });

    test('survives a round trip through toJson', () {
      final original = DispatchConfigModel.fromJson(<String, dynamic>{
        'totalRings': 4,
        'ringTimeoutSeconds': 10,
        'maxSearchSeconds': 40,
        'maxSearchSecondsWithUpgrade': 110,
        'categoryUpgrade': <String, dynamic>{
          'enabled': true,
          'decisionSeconds': 30,
          'map': <String, dynamic>{'economy': 'luxury'},
        },
      });
      final copy = DispatchConfigModel.fromJson(original.toJson());

      expect(copy.categoryUpgrade.enabled, isTrue);
      expect(copy.maxSearchSecondsWithUpgrade, 110);
    });
  });

  group('FindRideParams', () {
    FindRideParams params({String? pickupCity}) => FindRideParams(
      pickupPoint: const FindRidePointParams(
        placeName: 'A',
        location: FindRideLocationParams(coordinates: <double>[0, 0]),
      ),
      dropOffPoint: const FindRidePointParams(
        placeName: 'B',
        location: FindRideLocationParams(coordinates: <double>[1, 1]),
      ),
      category: 'economy',
      rideDistance: 3,
      rideFare: 14.50,
      averageTime: 10,
      paymentMethod: 'attached_card',
      specialRequest: '',
      codeId: 'code',
      campaignId: 'campaign',
      originalRideFare: 18.50,
      discountAmount: 4,
      pickupCity: pickupCity,
    );

    test('sends pickupCity only when there is one', () {
      expect(params(pickupCity: 'Miami').toJson()['pickupCity'], 'Miami');
      expect(params(pickupCity: '  ').toJson().containsKey('pickupCity'), isFalse);
      expect(params().toJson().containsKey('pickupCity'), isFalse);
    });

    test('upgradedTo switches category and fare and drops a lost promo', () {
      final upgraded = params(pickupCity: 'Miami').upgradedTo(
        category: 'luxury',
        rideFare: 31.20,
        dropPromoCode: true,
      );
      final json = upgraded.toJson();

      expect(json['category'], 'luxury');
      expect(json['rideFare'], 31.20);
      expect(json['pickupCity'], 'Miami');
      expect(json['paymentMethod'], 'attached_card');
      expect(json.containsKey('codeId'), isFalse);
      expect(json.containsKey('campaignId'), isFalse);
      expect(json.containsKey('originalRideFare'), isFalse);
    });

    test('upgradedTo keeps a promo code that still applies', () {
      final json = params()
          .upgradedTo(category: 'luxury', rideFare: 31.20, dropPromoCode: false)
          .toJson();

      expect(json['codeId'], 'code');
      expect(json['campaignId'], 'campaign');
      expect(json.containsKey('originalRideFare'), isFalse);
    });
  });
}
