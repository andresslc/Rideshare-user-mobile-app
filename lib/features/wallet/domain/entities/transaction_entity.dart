import '../../../../shared/entities/card_entity.dart';

class TransactionEntity {
  final String id;
  final double amount;
  final String type;
  // final String identifierKey;
  final BankCardEntity? card;
  final String status;
  final DateTime createdAt;
  final double rewardedAmount;
  final bool isRewarded;
  final String? balanceSource;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    // required this.identifierKey,
    this.card,
    required this.status,
    required this.createdAt,
    this.rewardedAmount = 0.0,
    this.isRewarded = false,
    this.balanceSource,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          type == other.type &&
          // identifierKey == other.identifierKey &&
          card == other.card &&
          status == other.status &&
          createdAt == other.createdAt &&
          rewardedAmount == other.rewardedAmount &&
          isRewarded == other.isRewarded &&
          balanceSource == other.balanceSource;

  @override
  int get hashCode =>
      id.hashCode ^
      amount.hashCode ^
      type.hashCode ^
      // identifierKey.hashCode ^
      card.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      rewardedAmount.hashCode ^
      isRewarded.hashCode ^
      balanceSource.hashCode;
}

