import '../../../../shared/models/card_model.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.type,
    // required super.identifierKey,
    super.card,
    required super.status,
    required super.createdAt,
    super.rewardedAmount,
    super.isRewarded,
    super.balanceSource,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      // identifierKey: json['identifierKey'] as String,
      card: json['card'] != null ? BankCardModel.fromJson(json['card']) : null,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rewardedAmount: json['rewardedAmount'] != null
          ? (json['rewardedAmount'] as num).toDouble()
          : 0.0,
      isRewarded: json['isRewarded'] as bool? ?? false,
      balanceSource: json['balanceSource'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'amount': amount,
      'type': type,
      // 'identifierKey': identifierKey,
      'card': card,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'rewardedAmount': rewardedAmount,
      'isRewarded': isRewarded,
      'balanceSource': balanceSource,
    };
  }
}

