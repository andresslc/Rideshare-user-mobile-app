import 'package:flutter/material.dart';

import '../../core/extensions/theme_extension.dart';
import 'custom_tap.dart';

class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({
    super.key,
    this.onTap,
    this.size = 64,
    required this.label,
    this.optionalLabel,
  });

  final VoidCallback? onTap;
  final double size;
  final String label;
  final String? optionalLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        CustomTap(
          onTap: onTap,
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                // ignore: deprecated_member_use
                color: colors.brand.withOpacity(0.6),
                width: 1.4,
              ),
            ),
            child: Icon(Icons.add, color: colors.brand),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: label,
              style: context.textTheme.bodyMedium,
              children: [
                if (optionalLabel != null) ...[
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: optionalLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
