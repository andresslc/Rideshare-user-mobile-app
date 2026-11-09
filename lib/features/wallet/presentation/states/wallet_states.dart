import 'package:ride_app/features/wallet/domain/entities/transaction_entity.dart';
import 'package:ride_app/shared/entities/card_entity.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

enum WalletStatus { initial, loading, success, failure, loadingMore }

class WalletState {
  final double balance;
  final double rewardedBalance;
  final double totalBalance;
  final List<TransactionEntity> transactions;
  final WalletStatus status;
  final String? errorMessage;
  final Pagination? pagination;
  final List<BankCardEntity> cards;
  final bool isAddingFunds;
  final bool isFetchingCards;
  final String selectedFilter;
  final bool hasReachedEnd;

  const WalletState({
    this.balance = 0.0,
    this.rewardedBalance = 0.0,
    this.totalBalance = 0.0,
    this.transactions = const [],
    this.status = WalletStatus.initial,
    this.errorMessage,
    this.pagination,
    this.cards = const [],
    this.isAddingFunds = false,
    this.isFetchingCards = false,
    this.selectedFilter = 'all',
    this.hasReachedEnd = false,
  });

  WalletState copyWith({
    double? balance,
    double? rewardedBalance,
    double? totalBalance,
    List<TransactionEntity>? transactions,
    WalletStatus? status,
    String? errorMessage,
    Pagination? pagination,
    List<BankCardEntity>? cards,
    bool? isAddingFunds,
    bool? isFetchingCards,
    String? selectedFilter,
    bool? hasReachedEnd,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      rewardedBalance: rewardedBalance ?? this.rewardedBalance,
      totalBalance: totalBalance ?? this.totalBalance,
      transactions: transactions ?? this.transactions,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      pagination: pagination ?? this.pagination,
      cards: cards ?? this.cards,
      isAddingFunds: isAddingFunds ?? this.isAddingFunds,
      isFetchingCards: isFetchingCards ?? this.isFetchingCards,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletState &&
          runtimeType == other.runtimeType &&
          balance == other.balance &&
          rewardedBalance == other.rewardedBalance &&
          totalBalance == other.totalBalance &&
          transactions == other.transactions &&
          status == other.status &&
          errorMessage == other.errorMessage &&
          pagination == other.pagination &&
          cards == other.cards &&
          isAddingFunds == other.isAddingFunds &&
          isFetchingCards == other.isFetchingCards &&
          selectedFilter == other.selectedFilter &&
          hasReachedEnd == other.hasReachedEnd;

  @override
  int get hashCode =>
      balance.hashCode ^
      rewardedBalance.hashCode ^
      totalBalance.hashCode ^
      transactions.hashCode ^
      status.hashCode ^
      errorMessage.hashCode ^
      pagination.hashCode ^
      cards.hashCode ^
      isAddingFunds.hashCode ^
      isFetchingCards.hashCode ^
      selectedFilter.hashCode ^
      hasReachedEnd.hashCode;
}
