// import 'package:ride_app/core/core.dart';
// import 'package:ride_app/shared/widgets/app_gradient_box.dart';
// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';

// class ReviewWidget extends StatelessWidget {
//   final String reviewText;
//   final int rating; // 1 to 6
//   const ReviewWidget({super.key, required this.reviewText, this.rating = 6});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(height: 1, color: context.appColors.border),
//         const Gap(6),

//         /// Title
//         Text('Review', style: context.textTheme.bodyMedium?.copyWith()),
//         const Gap(6),

//         /// Gradient Box
//         AppGradientBox(
//           radius: 8,
//           padding: const EdgeInsets.all(7),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               /// ⭐ Stars Row
//               Row(
//                 children: List.generate(
//                   6,
//                   (index) => Padding(
//                     padding: const EdgeInsets.only(right: 3.0),
//                     child: Icon(
//                       Icons.star,
//                       color: index < rating ? Colors.amber : Colors.grey[400],
//                       size: 20,
//                     ),
//                   ),
//                 ),
//               ),
//               const Gap(8),

//               /// Review text
//               Text(
//                 reviewText,
//                 maxLines: 4,
//                 // overflow: TextOverflow.ellipsis,
//                 style: context.textTheme.bodyMedium?.copyWith(),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/widgets/plain_background_widget.dart';

import '../../../../shared/widgets/ride_driver_info.dart';

class ReviewWidget extends StatelessWidget {
  final String reviewText;
  final int rating;
  final bool title;
  final bool showDriverInfo;
  final String? reviewerName;
  final String? reviewerImage;
  final bool showline; // 1 to 6
  final String? rideId;
  const ReviewWidget({
    super.key,
    required this.reviewText,
    this.rating = 6,
    this.showDriverInfo = false,
    this.title = true,
    this.showline = true,
    this.reviewerName,
    this.reviewerImage,
    this.rideId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showline) Container(height: 1, color: context.appColors.border),
        const Gap(6),

        /// Title
        if (title)
          Text(context.l10n.review, style: context.textTheme.bodyMedium),
        const Gap(6),

        /// Gradient Box
        // Container(
        //   padding: const EdgeInsets.all(7),
        //   decoration: BoxDecoration(
        //     color: context.appColors.brand.withValues(alpha: 0.1),
        //     borderRadius: BorderRadius.circular(12),
        //     border: Border.all(
        //       color: context.appColors.brand.withValues(alpha: 0.4),
        //     ),
        //   ),
        PlainBackgroundWidget(
          isAllRounded: true,
          radius: 12,
          isPlain: Theme.of(context).brightness == Brightness.dark,
          padding: const EdgeInsets.all(12),
          // radius: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ⭐ Stars Row
              Row(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 3.0),
                    child: Icon(
                      Icons.star,
                      color: index < rating ? Colors.amber : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Gap(8),

              /// Review text
              Text(
                reviewText,
                maxLines: 4,
                // overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(),
              ),
              if (showDriverInfo)
                DriverInfoSection(
                  profileImage: reviewerImage ?? '',
                  userName: reviewerName ?? "",
                  enableProfileTap: false,
                  rating: 1.5,
                  nameTextStyle: context.textTheme.labelSmall,
                  avatarSize: 30,
                  showTopBorder: false,
                  showRating: false,
                  carImage: '',
                  carMake: '',
                  plateNo: '',
                ),
            ],
          ),
        ),
      ],
    );
  }
}
