import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeHelper {
  static Future<void> confirmWalletTopUp({
    required String clientSecret,
    required String paymentMethodId,
    required VoidCallback onSuccess,
    required Function(String error) onFailure,
  }) async {
    try {
      // final paymentIntent = await Stripe.instance.confirmPayment(
      //   paymentIntentClientSecret: clientSecret,
      //   data: PaymentMethodParams.cardFromMethodId(
      //     paymentMethodData: PaymentMethodDataCardFromMethod(
      //       paymentMethodId: paymentMethodId,
      //     ),
      //   ),
      // );
      await Stripe.instance.handleNextAction(clientSecret);

      // if (paymentIntent.status == PaymentIntentsStatus.RequiresAction) {
      //   await Stripe.instance.handleNextAction(clientSecret);
      // }

      onSuccess();
    } on StripeException catch (e) {
      onFailure(e.error.localizedMessage ?? 'Payment failed');
    } catch (e, st) {
      log('Error confirming wallet top-up: $e', stackTrace: st);
      onFailure('Payment failed');
    }
  }
}
