import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/params/card_params.dart';
import '../../domain/entities/add_funds_result_entity.dart';
import '../../domain/use_cases/add_funds_usecase.dart';
import '../../domain/use_cases/get_cards_usecase.dart';
import '../../domain/use_cases/get_transaction_history_usecase.dart';
import '../states/wallet_states.dart';

final walletProvider =
    NotifierProvider.autoDispose<WalletNotifier, WalletState>(
      WalletNotifier.new,
    );

class WalletNotifier extends Notifier<WalletState> {
  late GetTransactionHistoryUseCase _getTransactionHistoryUseCase;
  late AddFundsUseCase _addFundsUseCase;
  late GetCardsUseCase _getCardsUseCase;

  @override
  WalletState build() {
    _getTransactionHistoryUseCase = locator<GetTransactionHistoryUseCase>();
    _addFundsUseCase = locator<AddFundsUseCase>();
    _getCardsUseCase = locator<GetCardsUseCase>();
    return const WalletState();
  }

  Future<void> fetchTransactionHistory({
    bool refresh = false,
    String? filter,
  }) async {
    if (state.status == WalletStatus.loading ||
        state.status == WalletStatus.loadingMore) {
      return;
    }

    final currentFilter = filter ?? state.selectedFilter;
    final int page = refresh
        ? 1
        : (state.pagination?.currentPage?.toInt() ?? 0) + 1;

    if (!refresh && state.hasReachedEnd) return;

    state = state.copyWith(
      status: refresh ? WalletStatus.loading : WalletStatus.loadingMore,
      selectedFilter: currentFilter,
      hasReachedEnd: refresh ? false : state.hasReachedEnd,
    );

    final result = await _getTransactionHistoryUseCase(
      TransactionParams(page: page, type: currentFilter),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: WalletStatus.failure,
        errorMessage: failure.message,
      ),
      (data) {
        final reachedEnd =
            (data.pagination?.currentPage ?? 0) >=
            (data.pagination?.totalPages ?? 0);
        state = state.copyWith(
          status: WalletStatus.success,
          balance: data.balance,
          rewardedBalance: data.rewardedBalance,
          totalBalance: data.totalBalance,
          transactions: refresh
              ? data.transactions
              : [...state.transactions, ...data.transactions],
          pagination: data.pagination,
          hasReachedEnd: reachedEnd,
        );
      },
    );
  }

  Future<void> fetchCards() async {
    if (state.isFetchingCards) return;

    state = state.copyWith(isFetchingCards: true, errorMessage: null);
    final result = await _getCardsUseCase();
    result.fold(
      (failure) => state = state.copyWith(
        errorMessage: failure.message,
        isFetchingCards: false,
      ),
      (cards) => state = state.copyWith(cards: cards, isFetchingCards: false),
    );
  }

  Future<AddFundsResultEntity?> addFunds({
    required double amount,
    required String cardId,
  }) async {
    state = state.copyWith(isAddingFunds: true);
    final result = await _addFundsUseCase(
      AddFundParams(amount: amount, paymentMethodId: cardId),
    );

    state = state.copyWith(isAddingFunds: false);

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return null;
      },
      (response) {
        if (!response.requiresAction) {
          return fetchTransactionHistory(refresh: true).then((_) => response);
        }
        return response;
      },
    );
  }

  void updateFilter(String filter) {
    if (state.selectedFilter == filter.toLowerCase()) return;
    fetchTransactionHistory(refresh: true, filter: filter.toLowerCase());
  }
}
