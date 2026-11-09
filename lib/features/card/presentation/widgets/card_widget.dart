import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/shared/entities/card_entity.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';

class CardWidget extends StatelessWidget {
  final BankCardEntity card;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const CardWidget({super.key, required this.card, this.onDelete, this.onTap});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final textTheme = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row for delete icon
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(AppIcons.trash, width: 24, height: 24),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),

        // Card details (tappable)
        GestureDetector(
          onTap: onTap,
          child: AppGradientBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            cornerRadius: 16,
            borderWidth: 1.5,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '**** **** **** ${card.last4 ?? ""}',
                    style: textTheme.titleMedium?.copyWith(
                      color: appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (card.isDefault ?? false)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.brand,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.l10n.defaultt,
                      style: textTheme.labelSmall?.copyWith(
                        color: appColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
