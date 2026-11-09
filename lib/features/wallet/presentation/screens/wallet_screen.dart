import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:ride_app/features/wallet/presentation/states/wallet_states.dart';
import 'package:ride_app/features/wallet/presentation/widgets/add_funds_bottom_sheet.dart';
import 'package:ride_app/features/wallet/presentation/widgets/transaction_filter.dart';
import 'package:ride_app/features/wallet/presentation/widgets/transaction_header.dart';
import 'package:ride_app/features/wallet/presentation/widgets/transaction_list.dart';
import 'package:ride_app/features/wallet/presentation/widgets/wallet_balance_card.dart';
import 'package:ride_app/shared/shared.dart';
import 'package:ride_app/shared/widgets/toast.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../l10n/app_localizations.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  late final ProviderSubscription<WalletState> _walletListener;
  String? _pendingFilterChange;

  WalletNotifier get _walletNotifier => ref.read(walletProvider.notifier);

  @override
  void initState() {
    super.initState();
    _walletListener = ref.listenManual(
      walletProvider,
      _handleWalletStateChange,
    );
    _scheduleInitialFetch();
  }

  @override
  void dispose() {
    _walletListener.close();
    super.dispose();
  }

  void _scheduleInitialFetch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTransactions();
    });
  }

  void _handleWalletStateChange(WalletState? previous, WalletState next) {
    if (next.errorMessage != null &&
        next.errorMessage != previous?.errorMessage) {
      showToast(msg: next.errorMessage!);
    }

    if (mounted &&
        _pendingFilterChange != null &&
        next.status != WalletStatus.loading) {
      setState(() => _pendingFilterChange = null);
    }
  }

  Future<void> _refreshTransactions() async {
    await _walletNotifier.fetchTransactionHistory(refresh: true);
  }

  void _loadMoreTransactions() {
    _walletNotifier.fetchTransactionHistory();
  }

  void _updateFilter(String filter) {
    final normalizedFilter = filter.toLowerCase();
    if (normalizedFilter == ref.read(walletProvider).selectedFilter) return;

    setState(() => _pendingFilterChange = normalizedFilter);
    _walletNotifier.updateFilter(normalizedFilter);
  }

  void _showAddFundsBottomSheet() {
    showAddFundsBottomSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(walletProvider);

    return AppScaffold(
      padding: const EdgeInsets.all(0),
      scrollable: false,
      appBar: AppBar(
        title: Text(l10n.wallet).animate().fadeIn(duration: 500.ms),
        centerTitle: true,
      ),
      child: _WalletScreenContent(
        state: state,
        l10n: l10n,
        isFilterChanging:
            _pendingFilterChange != null &&
            state.status == WalletStatus.loading &&
            state.transactions.isNotEmpty &&
            state.selectedFilter == _pendingFilterChange,
        onAddFunds: _showAddFundsBottomSheet,
        onFilterChanged: _updateFilter,
        onRefresh: _refreshTransactions,
        onLoadMore: _loadMoreTransactions,
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0),
    );
  }
}

class _WalletScreenContent extends StatelessWidget {
  const _WalletScreenContent({
    required this.state,
    required this.l10n,
    required this.isFilterChanging,
    required this.onAddFunds,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final WalletState state;
  final AppLocalizations l10n;
  final bool isFilterChanging;
  final VoidCallback onAddFunds;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        WalletBalanceCard(
          balance: state.balance,
          rewardedBalance: state.rewardedBalance,
          totalBalance: state.totalBalance,
          onAddFunds: onAddFunds,
        ),
        const Gap(12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: AppButton(
            text: l10n.add_funds,
            onPressed: onAddFunds,
            height: 42,
            width: double.infinity,
            backgroundColor: context.appColors.brand,
            fontColor: context.colorScheme.onPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            radius: 12,
          ),
        ),
        const Gap(20),
        TransactionFilterHeader(
          selectedCategory: state.selectedFilter,
          onChanged: onFilterChanged,
        ),
        const Gap(20),

        const TransactionHeader(),
        const Gap(20),
        Expanded(
          child: _WalletTransactionSection(
            state: state,
            l10n: l10n,
            isFilterChanging: isFilterChanging,
            onRefresh: onRefresh,
            onLoadMore: onLoadMore,
          ),
        ),
      ],
    );
  }
}

class _WalletTransactionSection extends StatelessWidget {
  const _WalletTransactionSection({
    required this.state,
    required this.l10n,
    required this.isFilterChanging,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final WalletState state;
  final AppLocalizations l10n;
  final bool isFilterChanging;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasInitialError) {
      return _WalletStatusPane(
        message: state.errorMessage ?? l10n.something_went_wrong,
        actionLabel: l10n.retry,
        onAction: onRefresh,
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: TransactionList(
            key: ValueKey(state.selectedFilter),
            transactions: state.transactions,
            onLoadMore: onLoadMore,
            isLoadingMore: state.isLoadingMore,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !isFilterChanging,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isFilterChanging
                  ? const _WalletFilterLoadingOverlay()
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletFilterLoadingOverlay extends StatelessWidget {
  const _WalletFilterLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDarkMode
        ? Colors.grey.shade700
        : Colors.grey.shade100;

    return ColoredBox(
      // ignore: deprecated_member_use
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            children: List.generate(5, (_) => const _WalletFilterLoadingRow()),
          ),
        ),
      ),
    );
  }
}

class _WalletFilterLoadingRow extends StatelessWidget {
  const _WalletFilterLoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _WalletFilterLoadingCell(
                flex: 2,
                alignment: Alignment.centerLeft,
              ),
              Gap(12),
              _WalletFilterLoadingCell(flex: 4, alignment: Alignment.center),
              Gap(12),
              _WalletFilterLoadingCell(flex: 1, alignment: Alignment.center),
              Gap(12),
              _WalletFilterLoadingCell(flex: 1, alignment: Alignment.center),
              Gap(12),
              _WalletFilterLoadingCell(
                flex: 3,
                alignment: Alignment.centerRight,
              ),
            ],
          ),
        ),
        Divider(thickness: 1, height: 1),
      ],
    );
  }
}

class _WalletFilterLoadingCell extends StatelessWidget {
  const _WalletFilterLoadingCell({required this.flex, required this.alignment});

  final int flex;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Container(
          height: 12,
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 90),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _WalletStatusPane extends StatelessWidget {
  const _WalletStatusPane({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const Gap(12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

extension on WalletState {
  bool get isInitialLoading =>
      status == WalletStatus.loading && transactions.isEmpty;

  bool get hasInitialError =>
      status == WalletStatus.failure && transactions.isEmpty;

  bool get isLoadingMore => status == WalletStatus.loadingMore;
}
