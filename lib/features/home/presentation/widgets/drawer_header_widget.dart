import 'package:flutter/material.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/circular_profile.dart';

class CustomDrawerHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? profilePicture;
  final VoidCallback? onViewProfile;

  const CustomDrawerHeader({
    super.key,
    required this.name,
    required this.email,
    this.profilePicture,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p24,
      ),

      child: CustomTap(
        onTap: onViewProfile,
        isNeedOverlay: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Profile Image
            CircularProfile(
              image: profilePicture,
              size: context.screenWidth * 0.22,
            ),

            const SizedBox(width: AppSizes.p16),

            /// Name, Email & View Profile
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p4),
                  Text(
                    email,
                    maxLines: 2,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p8),

                  Text(
                    context.l10n.view_profile,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.brand,
                      decoration: TextDecoration.underline,
                      decorationColor: colorScheme.brand,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
