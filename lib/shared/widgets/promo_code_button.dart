import 'package:flutter/material.dart';

import '../../core/core.dart';

/// A styled button that opens Google Maps navigation.
///
/// Displays a map pin icon with localized "Navigate in Google Maps" text.
/// Used across ride sheets to let the driver open turn-by-turn directions.
class PromoCodeButton extends StatelessWidget {
  const PromoCodeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.map_outlined,
          size: 20,
          color: context.appColors.brand,
        ),
        label: Text(
          context.l10n.hint_promo,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.appColors.brand,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.appColors.brand),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
