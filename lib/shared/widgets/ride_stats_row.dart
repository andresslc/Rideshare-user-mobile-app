import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ride_app/core/core.dart';

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.title,
    required this.value,
    this.isAmount = false,
    this.valueSuffix,
    this.originalValue,
  });

  final String title;
  final String value;
  final bool isAmount;
  final String? valueSuffix;
  final String? originalValue;
  //FIX010
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: Localizations.localeOf(context).languageCode == 'es'
                  ? 10
                  : 12,
            ),
          ),
        ),

        const SizedBox(height: 4),
        if (valueSuffix?.trim().isNotEmpty ?? false)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 12),
              ),
              const SizedBox(width: 2),
              Text(
                valueSuffix!.trim(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontSize: 10),
              ),
            ],
          )
        else
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 12),
          ),

        // Text(
        //   value,
        //   textAlign: TextAlign.center,
        //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
        //     fontSize: 12,
        //     // fontWeight: FontWeight.bold,
        //   ),
        // ),

        // if (valueSuffix?.trim().isNotEmpty ?? false)
        //   Text(
        //     valueSuffix!.trim(),
        //     textAlign: TextAlign.center,
        //     style: Theme.of(
        //       context,
        //     ).textTheme.titleMedium?.copyWith(fontSize: 12),
        //   ),
        const SizedBox(height: 2),

        /// Reserve space even when promo is not applied
        if (originalValue != null)
          SizedBox(
            height: 12,
            child: Text(
              originalValue!,
              textAlign: TextAlign.center,
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: context.appColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
      ],

      // Column(
      //   mainAxisSize: MainAxisSize.min,
      //   children: [
      //     /// Wrap title in FittedBox to auto-scale text if it is too long
      //     FittedBox(
      //       fit: BoxFit.scaleDown,
      //       child: Text(
      //         title,
      //         textAlign: TextAlign.center,
      //         style: Theme.of(context).textTheme.titleSmall?.copyWith(
      //           fontSize: Localizations.localeOf(context).languageCode == 'es'
      //               ? 10
      //               : 12,
      //         ),
      //       ),
      //     ),
      //     const SizedBox(height: 4),
      //     Column(
      //       mainAxisSize: MainAxisSize.min,
      //       children: [
      //         Text(
      //           value,
      //           textAlign: TextAlign.center,
      //           style: Theme.of(context).textTheme.titleMedium?.copyWith(
      //             fontSize: 12,
      //             fontWeight: FontWeight.bold,
      //           ),
      //         ),

      //         if (valueSuffix?.trim().isNotEmpty ?? false)
      //           Text(
      //             valueSuffix!.trim(),
      //             style: Theme.of(
      //               context,
      //             ).textTheme.titleMedium?.copyWith(fontSize: 12),
      //           ),

      //         if (originalValue != null) ...[
      //           const SizedBox(height: 2),
      //           Text(
      //             originalValue!,
      //             textAlign: TextAlign.center,
      //             style: TextStyle(
      //               decoration: TextDecoration.lineThrough,
      //               color: context.appColors.textSecondary,
      //               fontSize: 10,
      //             ),
      //           ),
      //         ],
      //       ],
      //     ),

      /// Wrap value in FittedBox for long amount numbers
      // FittedBox(
      //   fit: BoxFit.scaleDown,
      //   child: RichText(
      //     textAlign: TextAlign.center,
      //     text: TextSpan(
      //       style: Theme.of(context).textTheme.titleMedium?.copyWith(
      //         fontSize: Localizations.localeOf(context).languageCode == 'es'
      //             ? 12
      //             : 12,
      //       ),
      //       children: [
      //         if (originalValue != null)
      //           TextSpan(
      //             text: '$originalValue ',
      //             style: TextStyle(
      //               decoration: TextDecoration.lineThrough,
      //               color: context.appColors.textSecondary,
      //               fontSize: 10,
      //             ),
      //           ),
      //         TextSpan(text: value),
      //         if (valueSuffix?.trim().isNotEmpty ?? false)
      //           TextSpan(text: ' ${valueSuffix!.trim()}'),
      //       ],
      //     ),
      //   ),
      // ),
      //],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 48, width: 1.5, color: context.appColors.border);
  }
}

class RideStatsRow extends StatelessWidget {
  const RideStatsRow({
    super.key,
    required this.totalTime,
    required this.totalDistance,
    required this.estimateFare,
    this.originalFare,
    this.primaryTitle,
    this.secondaryTitle,
    this.secondaryEstimateFare,
    this.secondaryOriginalFare,
    this.totalAmountSuffix,
    this.secondaryAmountSuffix,

    // this.showAvgTime = false,
    // this.showTotalFare = false,
  });

  final String totalTime;
  final String totalDistance;
  final String estimateFare;
  final String? originalFare;
  final String? primaryTitle;
  final String? secondaryTitle;
  final String? secondaryEstimateFare;
  final String? secondaryOriginalFare;
  final String? totalAmountSuffix;
  final String? secondaryAmountSuffix;

  /// Optional flags
  // final bool
  // showAvgTime; // agar true ho to Total Time ki jagah Avg Time show kare
  // final bool
  // showTotalFare; // agar true ho to Total Amount ki jagah Total Fare show kare

  @override
  Widget build(BuildContext context) {
    final bool showSecondaryFare = secondaryEstimateFare != null;

    Widget buildDivider() => _VerticalDivider();

    Widget buildStat({
      required String title,
      required String value,
      String? originalValue,
      String? valueSuffix,
    }) {
      return Expanded(
        child: Center(
          child: _StatItem(
            title: title,
            value: value,
            isAmount: true,
            valueSuffix: valueSuffix,
            originalValue: originalValue,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.appColors.border, width: 1),
        ),
      ),
      child: showSecondaryFare
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: _StatItem(
                      title: context.l10n.avg_time,
                      value: totalTime,
                    ),
                  ),
                ),
                buildDivider(),
                const Gap(4),
                Expanded(
                  child: Center(
                    child: _StatItem(
                      title: context.l10n.total_distance,
                      value: totalDistance,
                    ),
                  ),
                ),
                const Gap(4),

                buildDivider(),
                buildStat(
                  title: primaryTitle ?? context.l10n.economy,
                  value: estimateFare,
                  originalValue: originalFare,
                  valueSuffix: totalAmountSuffix,
                ),
                buildDivider(),
                buildStat(
                  title: secondaryTitle ?? context.l10n.luxury,
                  value: secondaryEstimateFare!,
                  originalValue: secondaryOriginalFare,
                  valueSuffix: secondaryAmountSuffix,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StatItem(
                    title: context.l10n.avg_time,
                    value: totalTime,
                  ),
                ),
                buildDivider(),

                Expanded(
                  child: _StatItem(
                    title: context.l10n.total_distance,
                    value: totalDistance,
                  ),
                ),
                buildDivider(),
                // buildStat(
                // title: primaryTitle ?? context.l10n.estimated_fare,
                //   value: estimateFare,
                //   originalValue: originalFare,
                //   valueSuffix: totalAmountSuffix,
                // ),
                Expanded(
                  child: _StatItem(
                    title: primaryTitle ?? context.l10n.estimated_fare,
                    value: estimateFare,
                    isAmount: true,
                    valueSuffix: totalAmountSuffix,
                    originalValue: originalFare,
                  ),
                ),
              ],
            ),
    );
  }
}
