import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/string_extension.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/features/wallet/domain/entities/transaction_entity.dart';
import 'package:ride_app/l10n/app_localizations.dart';

// class TransactionList extends StatefulWidget {
//   final List<TransactionEntity> transactions;
//   final VoidCallback onLoadMore;
//   final bool isLoadingMore;

//   const TransactionList({
//     super.key,
//     required this.transactions,
//     required this.onLoadMore,
//     required this.isLoadingMore,
//   });

//   @override
//   State<TransactionList> createState() => _TransactionListState();
// }

// class _TransactionListState extends State<TransactionList> {
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//   }

//   @override
//   void dispose() {
//     _scrollController.removeListener(_onScroll);
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _onScroll() {
//     if (widget.isLoadingMore) return;
//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 200) {
//       widget.onLoadMore();
//     }
//   }

//   String _formatTransactionAmount(double value) {
//     final formatted = value % 1 == 0
//         ? value.toInt().toString()
//         : value.toString();

//     return '\$$formatted';
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'success':
//       case 'completed':
//         return context.appColors.brand;

//       case 'failed':
//         return context.appColors.error;

//       default:
//         return Colors.orange;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = context.textTheme;
//     final colors = context.appColors;
//     final l10n = AppLocalizations.of(context)!;

//     if (widget.transactions.isEmpty) {
//       return Center(
//         child: Text(
//           l10n.no_transactions_found,
//           style: textTheme.bodyMedium?.copyWith(
//             // ignore: deprecated_member_use
//             color: colors.textPrimary.withOpacity(0.6),
//           ),
//         ),
//       );
//     }

//     return Scrollbar(
//       controller: _scrollController,
//       thumbVisibility: true,
//       child: ListView.builder(
//         controller: _scrollController,
//         itemCount: widget.transactions.length + (widget.isLoadingMore ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == widget.transactions.length) {
//             return const Padding(
//               padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
//               child: Center(
//                 child: SizedBox(
//                   height: 24,
//                   width: 24,
//                   child: CircularProgressIndicator(strokeWidth: 2.5),
//                 ),
//               ),
//             );
//           }

//           final trx = widget.transactions[index];
//           final isRewardedSource =
//               trx.balanceSource?.toLowerCase() == 'rewarded' || trx.isRewarded;
//           final sourceLabel = isRewardedSource
//               ? l10n.rewarded
//               : (trx.balanceSource?.toLowerCase() == 'regular'
//                     ? l10n.regular
//                     : null);
//           // return ExpansionTile(
//           //   tilePadding: const EdgeInsets.symmetric(
//           //     horizontal: AppSizes.p16,
//           //     vertical: AppSizes.p4,
//           //   ),
//           //   childrenPadding: const EdgeInsets.only(
//           //     left: AppSizes.p16,
//           //     right: AppSizes.p16,
//           //     bottom: AppSizes.p12,
//           //   ),
//           //   showTrailingIcon: false,

//           //   title: Row(
//           //     children: [
//           //       buildCell(DateFormat.yMMMd().format(trx.createdAt), flex: 2),

//           //       Expanded(
//           //         flex: 4,
//           //         child: Column(
//           //           mainAxisAlignment: MainAxisAlignment.center,
//           //           crossAxisAlignment: CrossAxisAlignment.center,
//           //           children: [
//           //             Text(
//           //               trx.card?.last4 != null
//           //                   ? "•••• ${trx.card?.last4}"
//           //                   : "Wallet",
//           //               textAlign: TextAlign.center,
//           //               overflow: TextOverflow.ellipsis,
//           //               style: const TextStyle(fontWeight: FontWeight.w500),
//           //             ),

//           //             if (sourceLabel != null) ...[
//           //               const SizedBox(height: 2),
//           //               Container(
//           //                 padding: const EdgeInsets.symmetric(
//           //                   horizontal: 6,
//           //                   vertical: 1,
//           //                 ),
//           //                 decoration: BoxDecoration(
//           //                   color: isRewardedSource
//           //                       ? Colors.amber.shade700.withOpacity(0.15)
//           //                       : colors.brand.withOpacity(0.12),
//           //                   borderRadius: BorderRadius.circular(4),
//           //                 ),
//           //                 child: Text(
//           //                   sourceLabel,
//           //                   style: TextStyle(
//           //                     fontSize: 10,
//           //                     fontWeight: FontWeight.w600,
//           //                     color: isRewardedSource
//           //                         ? Colors.amber.shade800
//           //                         : colors.brand,
//           //                   ),
//           //                 ),
//           //               ),
//           //             ],
//           //           ],
//           //         ),
//           //       ),

//           //       buildCell(trx.type, flex: 2, textAlign: TextAlign.center),

//           //       buildCell(
//           //         trx.status.capitalised,
//           //         flex: 3,
//           //         textAlign: TextAlign.center,
//           //         color: _getStatusColor(trx.status),
//           //       ),

//           //       buildCell(
//           //         _formatTransactionAmount(trx.amount),
//           //         flex: 3,
//           //         textAlign: TextAlign.right,
//           //       ),
//           //     ],
//           //   ),

//           //   children: [
//           //     Align(
//           //       alignment: Alignment.centerLeft,
//           //       child: Column(
//           //         crossAxisAlignment: CrossAxisAlignment.start,
//           //         children: [
//           //           Text(
//           //             'Transaction Details',
//           //             style: textTheme.titleSmall?.copyWith(
//           //               fontWeight: FontWeight.w600,
//           //             ),
//           //           ),
//           //           const SizedBox(height: 8),

//           //           Text('Date: ${DateFormat.yMMMd().format(trx.createdAt)}'),

//           //           const SizedBox(height: 4),

//           //           Text('Type: ${trx.type}'),

//           //           const SizedBox(height: 4),

//           //           Text(
//           //             'Status: ${trx.status.capitalised}',
//           //             style: TextStyle(color: _getStatusColor(trx.status)),
//           //           ),

//           //           const SizedBox(height: 4),

//           //           Text('Amount: ${_formatTransactionAmount(trx.amount)}'),

//           //           if (trx.card?.last4 != null) ...[
//           //             const SizedBox(height: 4),
//           //             Text('Card: •••• ${trx.card!.last4}'),
//           //           ],
//           //         ],
//           //       ),
//           //     ),
//           //   ],
//           // );
//           // return Column(
//           //   children: [
//           //     Padding(
//           //       padding: const EdgeInsets.symmetric(
//           //         horizontal: AppSizes.p16,
//           //         vertical: AppSizes.p12,
//           //       ),
//           //       child: Row(
//           //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           //         children: [
//           //           buildCell(
//           //             DateFormat.yMMMd().format(trx.createdAt),
//           //             flex: 2,
//           //           ),
//           //           Expanded(
//           //             flex: 4,
//           //             child: Column(
//           //               mainAxisAlignment: MainAxisAlignment.center,
//           //               crossAxisAlignment: CrossAxisAlignment.center,
//           //               children: [
//           //                 Text(
//           //                   trx.card?.last4 != null
//           //                       ? "•••• ${trx.card?.last4}"
//           //                       : "Wallet",
//           //                   textAlign: TextAlign.center,
//           //                   overflow: TextOverflow.ellipsis,
//           //                   style: const TextStyle(fontWeight: FontWeight.w500),
//           //                 ),
//           //                 if (sourceLabel != null) ...[
//           //                   const SizedBox(height: 2),
//           //                   Container(
//           //                     padding: const EdgeInsets.symmetric(
//           //                       horizontal: 6,
//           //                       vertical: 1,
//           //                     ),
//           //                     decoration: BoxDecoration(
//           //                       color: isRewardedSource
//           //                           // ignore: deprecated_member_use
//           //                           ? Colors.amber.shade700.withOpacity(0.15)
//           //                           // ignore: deprecated_member_use
//           //                           : colors.brand.withOpacity(0.12),
//           //                       borderRadius: BorderRadius.circular(4),
//           //                     ),
//           //                     child: Text(
//           //                       sourceLabel,
//           //                       style: TextStyle(
//           //                         fontSize: 10,
//           //                         fontWeight: FontWeight.w600,
//           //                         color: isRewardedSource
//           //                             ? Colors.amber.shade800
//           //                             : colors.brand,
//           //                       ),
//           //                     ),
//           //                   ),
//           //                 ],
//           //               ],
//           //             ),
//           //           ),
//           //           buildCell(trx.type, flex: 2, textAlign: TextAlign.center),
//           //           buildCell(
//           //             trx.status.capitalised,
//           //             flex: 3,
//           //             textAlign: TextAlign.center,
//           //             color: _getStatusColor(trx.status),
//           //             padding: const EdgeInsets.only(left: 12),
//           //           ),
//           //           buildCell(
//           //             _formatTransactionAmount(trx.amount),
//           //             flex: 3,
//           //             textAlign: TextAlign.right,
//           //           ),
//           //         ],
//           //       ),
//           //     ),
//           //     const Divider(thickness: 1, height: 1),
//           //   ],
//           // );
//         },
//       ),
//     );
//   }
// }

// Widget buildCell(
//   String text, {
//   required int flex,
//   TextAlign textAlign = TextAlign.left,
//   FontWeight fontWeight = FontWeight.normal,
//   EdgeInsetsGeometry? padding,
//   Color? color,
// }) {
//   return Expanded(
//     flex: flex,
//     child: Padding(
//       padding: padding ?? EdgeInsets.zero,
//       child: Text(
//         text,
//         textAlign: textAlign,
//         overflow: TextOverflow.ellipsis,
//         style: TextStyle(fontWeight: fontWeight, color: color),
//       ),
//     ),
//   );
// }

class TransactionList extends StatefulWidget {
  final List<TransactionEntity> transactions;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.onLoadMore,
    required this.isLoadingMore,
  });

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  final ScrollController _scrollController = ScrollController();

  /// Stores the indexes of expanded transactions.
  // final Set<int> _expandedIndexes = {};
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.isLoadingMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  // void _toggleTransaction(int index) {
  //   setState(() {
  //     if (_expandedIndexes.contains(index)) {
  //       _expandedIndexes.remove(index);
  //     } else {
  //       _expandedIndexes.add(index);
  //     }
  //   });
  // }
  void _toggleTransaction(int index) {
    setState(() {
      if (_expandedIndex == index) {
        // Same item pe dobara tap kiya to close ho jaye
        _expandedIndex = null;
      } else {
        // Naya item select, purana automatically close ho jayega
        _expandedIndex = index;
      }
    });
  }

  String _formatTransactionAmount(double value) {
    final formatted = value % 1 == 0
        ? value.toInt().toString()
        : value.toString();

    return '\$$formatted';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return context.appColors.brand;

      case 'failed':
        return context.appColors.error;

      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    if (widget.transactions.isEmpty) {
      return Center(
        child: Text(
          l10n.no_transactions_found,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary.withOpacity(0.6),
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.transactions.length + (widget.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.transactions.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }

          final trx = widget.transactions[index];

          // final isExpanded = _expandedIndexes.contains(index);
          final isExpanded = _expandedIndex == index;

          final isRewardedSource =
              trx.balanceSource?.toLowerCase() == 'rewarded' || trx.isRewarded;

          final sourceLabel = isRewardedSource
              ? l10n.rewarded
              : (trx.balanceSource?.toLowerCase() == 'regular'
                    ? l10n.regular
                    : null);

          return Column(
            children: [
              /// Main transaction row
              InkWell(
                onTap: () => _toggleTransaction(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p16,
                    vertical: AppSizes.p12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Date
                      buildCell(
                        DateFormat.yMMMd().format(trx.createdAt),
                        flex: 2,
                      ),

                      /// Card / Wallet
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              trx.card?.last4 != null
                                  ? "•••• ${trx.card?.last4}"
                                  : "Wallet",
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            if (sourceLabel != null) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isRewardedSource
                                      ? Colors.amber.shade700.withOpacity(0.15)
                                      : colors.brand.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  sourceLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isRewardedSource
                                        ? Colors.amber.shade800
                                        : colors.brand,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      /// Type
                      buildCell(trx.type, flex: 2, textAlign: TextAlign.center),

                      /// Status
                      buildCell(
                        trx.status.capitalised,
                        flex: 3,
                        textAlign: TextAlign.center,
                        color: _getStatusColor(trx.status),
                      ),

                      /// Amount
                      buildCell(
                        _formatTransactionAmount(trx.amount),
                        flex: 3,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),

              /// Expanded details
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          left: AppSizes.p16,
                          right: AppSizes.p16,
                          bottom: AppSizes.p16,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.p12),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction Details',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 8),

                              _DetailRow(
                                label: 'Date',
                                value: DateFormat.yMMMd().format(trx.createdAt),
                              ),

                              _DetailRow(label: 'Type', value: trx.type),

                              _DetailRow(
                                label: 'Status',
                                value: trx.status.capitalised,
                                valueColor: _getStatusColor(trx.status),
                              ),

                              _DetailRow(
                                label: 'Amount',
                                value: _formatTransactionAmount(trx.amount),
                              ),

                              if (trx.card?.last4 != null)
                                _DetailRow(
                                  label: 'Card',
                                  value: '•••• ${trx.card!.last4}',
                                ),

                              if (sourceLabel != null)
                                _DetailRow(label: 'Source', value: sourceLabel),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const Divider(thickness: 1, height: 1),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildCell(
  String text, {
  required int flex,
  TextAlign textAlign = TextAlign.left,
  FontWeight fontWeight = FontWeight.normal,
  EdgeInsetsGeometry? padding,
  Color? color,
}) {
  return Expanded(
    flex: flex,
    child: Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text,
        textAlign: textAlign,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: fontWeight, color: color),
      ),
    ),
  );
}
