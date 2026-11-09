import 'package:flutter/material.dart';

import '../../core/extensions/theme_extension.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.center = true,
  });

  final String title;
  final String subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textAlign = center ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: context.textTheme.headlineMedium,
            textAlign: textAlign,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          textAlign: textAlign,
        ),
      ],
    );
  }
}
