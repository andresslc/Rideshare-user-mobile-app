import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/theme_extension.dart';

class ReviewShimmer extends StatelessWidget {
  const ReviewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode
        ? context.appColors.button
        : context.appColors.lightButton;
    final highlightColor = isDarkMode
        ? Colors.grey.shade500
        : Colors.grey.shade100;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p4,
        vertical: AppSizes.p8,
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Reviewer name bar
            Container(width: 100, height: 12, color: Colors.grey),
            const SizedBox(height: 8),

            /// Star row
            Row(
              children: List.generate(
                5,
                (_) => const Padding(
                  padding: EdgeInsets.only(right: 4.0),
                  child: Icon(
                    Icons.star,
                    color: Colors.grey,
                    size: AppSizes.p12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            /// Review text
            Container(width: double.infinity, height: 12, color: Colors.grey),
            const SizedBox(height: 4),
            Container(width: double.infinity, height: 12, color: Colors.grey),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
