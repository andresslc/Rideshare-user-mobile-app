class PaymentVerificationEntity {
  final bool requiresAction;
  final String clientSecret;
  final String paymentIntentId;

  const PaymentVerificationEntity({
    required this.requiresAction,
    required this.clientSecret,
    required this.paymentIntentId,
  });
}
