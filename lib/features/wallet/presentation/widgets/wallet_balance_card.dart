import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/l10n/app_localizations.dart';

class WalletBalanceCard extends StatelessWidget {
  final double balance;
  final double rewardedBalance;
  final double totalBalance;
  final VoidCallback onAddFunds;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    required this.rewardedBalance,
    required this.totalBalance,
    required this.onAddFunds,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = context.textTheme;
    final colors = context.appColors;

    final effectiveTotal = totalBalance > 0
        ? totalBalance
        : (balance + rewardedBalance);

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 0),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // ignore: deprecated_member_use
            color: colors.textPrimary.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Label: Total Balance
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: colors.brand,
                ),
                const Gap(8),
                Text(
                  l10n.total_balance,
                  style: textTheme.titleSmall?.copyWith(
                    // ignore: deprecated_member_use
                    color: colors.textPrimary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Gap(6),

            /// Total Animated Amount
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: effectiveTotal),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.fastOutSlowIn,
              builder: (context, value, child) {
                return Text(
                  "\$${value.toStringAsFixed(2)}",
                  style: textTheme.displayMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),

            const Gap(16),

            /// Balance Breakdown Cards (Cash vs Rewarded)
            Row(
              children: [
                /// Cash Balance Card
                Expanded(
                  child: _BalanceSubCard(
                    title: l10n.regular_balance,
                    amount: balance,
                    icon: Icons.payments_outlined,
                    accentColor: colors.brand,
                  ),
                ),
                const Gap(12),

                /// Rewarded Balance Card
                Expanded(
                  child: _BalanceSubCard(
                    title: l10n.rewarded_balance,
                    amount: rewardedBalance,
                    icon: Icons.stars_rounded,
                    accentColor: Colors.amber.shade700,
                  ),
                ),
              ],
            ),

            const Gap(16),

            /// Add Funds Button
            // AppButton(
            //   text: l10n.add_funds,
            //   onPressed: onAddFunds,
            //   height: 42,
            //   width: double.infinity,
            //   backgroundColor: colors.brand,
            //   fontColor: context.colorScheme.onPrimary,
            //   fontSize: 14,
            //   fontWeight: FontWeight.w600,
            //   radius: 12,
            // ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSubCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color accentColor;

  const _BalanceSubCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: accentColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // ignore: deprecated_member_use
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accentColor),
              const Gap(4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: textTheme.labelMedium?.copyWith(
                      // ignore: deprecated_member_use
                      color: colors.textPrimary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Gap(4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: amount),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Text(
                  "\$${value.toStringAsFixed(2)}",
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
