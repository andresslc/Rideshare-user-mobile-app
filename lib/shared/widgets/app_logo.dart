import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_images.dart';

import '../../core/extensions/theme_extension.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.showText = false});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            // ignore: deprecated_member_use
            border: Border.all(color: colors.brand.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset(
            AppImages.logo,
            height: size * 0.55,
            width: size * 0.55,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'RIDE APP',
            style: context.textTheme.headlineMedium?.copyWith(
              color: colors.brand,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
