import 'package:ride_app/features/ride_room/domain/entities/payment_verification_entity.dart';

class PaymentVerificationModel extends PaymentVerificationEntity {
  const PaymentVerificationModel({
    required super.requiresAction,
    required super.clientSecret,
    required super.paymentIntentId,
  });

  factory PaymentVerificationModel.fromEntity(
    PaymentVerificationEntity entity,
  ) {
    return PaymentVerificationModel(
      requiresAction: entity.requiresAction,
      clientSecret: entity.clientSecret,
      paymentIntentId: entity.paymentIntentId,
    );
  }

  factory PaymentVerificationModel.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationModel(
      requiresAction: json['requiresAction'] as bool? ?? false,
      clientSecret: json['clientSecret']?.toString() ?? '',
      paymentIntentId: json['paymentIntentId']?.toString() ?? '',
    );
  }
}
