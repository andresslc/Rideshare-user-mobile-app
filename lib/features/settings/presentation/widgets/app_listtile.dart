import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

class AppListTile extends StatelessWidget {
  final String? leadingImage;
  final String title;
  final bool showToggle;
  final bool toggleValue;
  final void Function(bool)? onToggleChanged;
  final VoidCallback? onTap;
  final bool isDestructive;

  const AppListTile({
    super.key,
    this.leadingImage,
    required this.title,
    this.showToggle = false,
    this.toggleValue = false,
    this.onToggleChanged,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final textColor = isDestructive ? Colors.red : colors.textPrimary;

    return CustomTap(
      onTap: onTap,
      child: AppGradientBox(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p12,
        ),
        cornerRadius: 16,
        borderWidth: 1.5,
        child: Row(
          children: [
            if (leadingImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  leadingImage!,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  color: textColor,
                ),
              ),
            if (leadingImage != null) const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showToggle)
              SizedBox(
                height: 24,
                child: Center(
                  child: Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      padding: EdgeInsets.zero,
                      value: toggleValue,
                      onChanged: onToggleChanged,
                      activeThumbColor: Colors.white,
                      activeTrackColor: colors.brand,
                      // ignore: deprecated_member_use
                      inactiveThumbColor: colors.surface.withOpacity(0.6),
                      // ignore: deprecated_member_use
                      inactiveTrackColor: colors.textPrimary.withOpacity(0.3),
                    ),
                  ),
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
          ],
        ),
      ),
    );
  }
}
