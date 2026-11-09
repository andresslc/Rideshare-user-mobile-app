class BankCardEntity {
  final String? id;
  final String? userId;
  final String? brand;
  final String? last4;
  final int? expMonth;
  final int? expYear;
  final String? paymentMethodId;
  final bool? isDefault;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BankCardEntity({
    this.id,
    this.userId,
    this.brand,
    this.last4,
    this.expMonth,
    this.expYear,
    this.paymentMethodId,
    this.isDefault,
    this.status,
    this.createdAt,
    this.updatedAt,
  });
}


class BankCardsResponseEntity {
  final List<BankCardEntity> cards;

  const BankCardsResponseEntity({required this.cards});
}
