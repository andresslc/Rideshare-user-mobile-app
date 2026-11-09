import 'package:ride_app/shared/entities/card_entity.dart';

class BankCardModel extends BankCardEntity {
  const BankCardModel({
    super.id,
    super.userId,
    super.brand,
    super.last4,
    super.expMonth,
    super.expYear,
    super.paymentMethodId,
    super.isDefault,
    super.status,
    super.createdAt,
    super.updatedAt,
  });

  factory BankCardModel.fromJson(Map<String, dynamic> json) {
    return BankCardModel(
      id: json['_id'] as String?,
      userId: json['user'] as String?,
      brand: json['brand'] as String?,
      last4: json['last4'] as String?,
      expMonth: json['expMonth'] as int?,
      expYear: json['expYear'] as int?,
      paymentMethodId: json['paymentMethodId'] as String?,
      isDefault: json['default'] as bool?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'brand': brand,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
      'paymentMethodId': paymentMethodId,
      'default': isDefault,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  BankCardEntity toEntity() {
    return BankCardEntity(
      id: id,
      userId: userId,
      brand: brand,
      last4: last4,
      expMonth: expMonth,
      expYear: expYear,
      paymentMethodId: paymentMethodId,
      isDefault: isDefault,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class BankCardsResponseModel extends BankCardsResponseEntity {
  const BankCardsResponseModel({required super.cards});

  factory BankCardsResponseModel.fromJson(Map<String, dynamic> json) {
    final cardsJson = json['data']['cards'] as List<dynamic>? ?? [];
    final cardsList = cardsJson
        .map((card) => BankCardModel.fromJson(card))
        .toList();
    return BankCardsResponseModel(cards: cardsList);
  }

  Map<String, dynamic> toJson() {
    return {
      'cards': cards.map((card) => (card as BankCardModel).toJson()).toList(),
    };
  }
}
