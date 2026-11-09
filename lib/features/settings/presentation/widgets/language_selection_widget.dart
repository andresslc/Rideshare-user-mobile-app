import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

class LanguageSelection extends StatelessWidget {
  final String title;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const LanguageSelection({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final textTheme = context.textTheme;

    return CustomTap(
      onTap: () => onChanged(value),
      child: AppGradientBox(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        cornerRadius: AppSizes.p16,
        borderWidth: 1.5,
        blurSigma: 20,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: appColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              activeColor: appColors.brand,
              // ignore: deprecated_member_use
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
