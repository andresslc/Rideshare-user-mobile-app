import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/l10n/app_localizations.dart';

void openWithdrawBottomSheet(BuildContext context, double balance) {
  final TextEditingController controller = TextEditingController();
  final l10n = AppLocalizations.of(context)!;
  final textTheme = context.textTheme;
  final colorScheme = context.colorScheme;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.p16,
          left: AppSizes.p16,
          right: AppSizes.p16,
          top: AppSizes.p20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppSizes.p12),
              ),
            ),
            const SizedBox(height: AppSizes.p20),

            /// Title
            Text(
              l10n.withdraw_funds,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.p12),

            /// Balance
            Text(
              "${l10n.available_balance}: \$${balance.toStringAsFixed(2)}",
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.p20),

            /// Amount input
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: l10n.enter_amount,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSizes.p20),

            /// Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
                  backgroundColor: colorScheme.primary,
                ),
                child: Text(
                  l10n.confirm,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.p20),
          ],
        ),
      );
    },
  );
}
