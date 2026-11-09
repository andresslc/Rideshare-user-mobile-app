import 'package:ride_app/shared/entities/card_entity.dart';

enum PaymentStatus { initial, loading, success, error }

enum PaymentAction {
  none,
  getCards,
  addCard,
  deleteCard,
  setDefaultCard,
  createPaymentMethod,
}

class PaymentState {
  final PaymentStatus status;
  final PaymentAction action;
  final String? message;
  final List<BankCardEntity> cards;
  final BankCardEntity? defaultCard;
  final String? paymentMethodId;

  const PaymentState({
    this.status = PaymentStatus.initial,
    this.action = PaymentAction.none,
    this.message,
    this.cards = const [],
    this.defaultCard,
    this.paymentMethodId,
  });

  PaymentState copyWith({
    PaymentStatus? status,
    PaymentAction? action,
    String? message,
    List<BankCardEntity>? cards,
    BankCardEntity? defaultCard,
    String? paymentMethodId,
  }) {
    return PaymentState(
      status: status ?? this.status,
      action: action ?? this.action,
      message: message,
      cards: cards ?? this.cards,
      defaultCard: defaultCard ?? this.defaultCard,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    );
  }
}
