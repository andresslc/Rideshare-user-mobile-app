import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';

import '../../../../core/extensions/context_extension.dart';
import '../../../../shared/widgets/circular_profile.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double? rating;
  final String email;
  final String phone;

  const ProfileHeaderWidget({
    super.key,
    required this.imageUrl,
    required this.name,
    this.rating,
    required this.email,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      // mainAxisSize: MainAxisSize.min,
      children: [
        CircularProfile(image: imageUrl, size: context.screenWidth * 0.32),

        // CircleAvatar(
        //   radius: 50,
        //   backgroundImage: NetworkImage(imageUrl),
        // ),
        const Gap(12),

        /// Name + Rating
        SizedBox(
          width: double.infinity,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            // overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              // mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,

              children: [
                if (rating != null) ...[
                  // const Gap(8),
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  Text(rating!.toStringAsFixed(1), style: textTheme.bodyMedium),
                ],
              ],
            ),
          ],
        ),
        const Gap(8),

        /// Email
        if (email.isNotEmpty)
          Text(
            email,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),

        const Gap(4),

        /// Phone
        if (phone.isNotEmpty)
          Text(
            phone,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
