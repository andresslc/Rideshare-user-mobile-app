import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/l10n/app_localizations.dart';

class TransactionHeader extends StatelessWidget {
  const TransactionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: colors.brand,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.p12),
          topRight: Radius.circular(AppSizes.p12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //for date
          Expanded(
            flex: 2,
            child: Text(
              l10n.date,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          //for account name
          Expanded(
            flex: 4, // more space for account name
            child: Text(
              l10n.account_name,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          //for type
          Expanded(
            flex: 2, // less space for type
            child: Text(
              l10n.type,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          //for status
          Expanded(
            flex: 3, // less space for type
            child: Padding(
              padding: const EdgeInsets.only(left: 12), // value adjust kar lo
              child: Text(
                l10n.status,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          //for amount
          Expanded(
            flex: 3,
            child: Text(
              l10n.price,
              textAlign: TextAlign.right,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
