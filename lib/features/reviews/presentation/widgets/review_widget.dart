// import 'package:ride_app/core/extensions/theme_extension.dart';
// import 'package:flutter/material.dart';

// class ReviewWidget extends StatelessWidget {
//   // final ReviewEntity review;
//   final bool showDate;
//   final bool showStars;
//   final Color? backgroundColor;
//   final bool roundedCorners;

//   const ReviewWidget({
//     // required this.review,
//     super.key,
//     this.showDate = true,
//     this.showStars = true,
//     this.backgroundColor,
//     this.roundedCorners = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.appColors;

//     final double rating = (review.rating ?? 0).toDouble();
//     final String reviewText = review.reviews ?? '';
//     final String userName = review.user?.name ?? 'Anonymous';
//     final String userImage =
//         review.user?.profilePicture ?? 'https://via.placeholder.com/150';
//     final DateTime createdAt = review.createdAt ?? DateTime.now();

//     return Container(
//       padding: const EdgeInsets.symmetric(
//         vertical: AppSizes.p12,
//         horizontal: AppSizes.p10,
//       ),
//       decoration: BoxDecoration(
//         color: backgroundColor ?? colors.white,
//         borderRadius:
//             roundedCorners ? BorderRadius.circular(AppSizes.radiusMd) : null,
//         boxShadow: backgroundColor != null
//             ? [
//                 BoxShadow(
//                   color: colors.black.withOpacity(0.08),
//                   blurRadius: AppSizes.p6,
//                   offset: const Offset(0, 2),
//                 ),
//               ]
//             : null,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           /// ⭐ Rating Row
//           Row(
//             children: [
//               if (showStars)
//                 Row(
//                   children: List.generate(
//                     5,
//                     (index) => Icon(
//                       index < rating
//                           ? Icons.star_rounded
//                           : Icons.star_border_rounded,
//                       color: colors.warning,
//                       size: AppSizes.iconSm,
//                     ),
//                   ),
//                 )
//               else
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.star_rate_rounded,
//                       color: colors.warning,
//                       size: AppSizes.iconSm,
//                     ),
//                     const Gap(AppSizes.p4),
//                     Text(
//                       rating.toString(),
//                       style: context.textTheme.bodyMedium,
//                     ),
//                   ],
//                 ),
//             ],
//           ),

//           /// 📅 Date
//           if (showDate) ...[
//             const Gap(AppSizes.p4),
//             Text(
//               DateTimeUtils.formatDate(createdAt),
//               style: context.textTheme.bodyMedium?.copyWith(
//                 color: colors.textSecondary,
//               ),
//             ),
//           ],

//           const Gap(AppSizes.p6),

//           /// 📝 Review Text
//           if (reviewText.isNotEmpty)
//             Text(
//               reviewText,
//               style: context.textTheme.bodyMedium,
//             ),

//           const Gap(AppSizes.p8),

//           /// 👤 User Info
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: AppSizes.radiusLg,
//                 backgroundColor: colors.containerLow,
//                 backgroundImage: NetworkImage(userImage),
//               ),
//               const Gap(AppSizes.p8),
//               Expanded(
//                 child: Text(
//                   userName,
//                   style: context.textTheme.titleSmall,
//                 ),
//               ),
//             ],
//           ),

//           /// 💬 Replies
//           if (review.replies.isNotEmpty) ...[
//             const Gap(AppSizes.p12),
//             ...review.replies.map(
//               (reply) => Padding(
//                 padding:
//                     const EdgeInsets.only(bottom: AppSizes.p8),
//                 child: _replySection(context, reply),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _replySection(BuildContext context, String reply) {
//     final colors = context.appColors;

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(AppSizes.p12),
//       decoration: BoxDecoration(
//         color: colors.containerLow,
//         borderRadius: BorderRadius.circular(AppSizes.radiusSm),
//         border: Border(
//           left: BorderSide(
//             color: colors.primary,
//             width: 4,
//           ),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.reply_rounded,
//                 size: AppSizes.iconSm,
//                 color: colors.primary,
//               ),
//               const Gap(AppSizes.p6),
//               Text(
//                 context.l10n.reply_from_supplier,
//                 style: context.textTheme.bodySmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: colors.primary,
//                 ),
//               ),
//             ],
//           ),
//           const Gap(AppSizes.p6),
//           Text(
//             reply,
//             style: context.textTheme.bodySmall?.copyWith(
//               color: colors.textPrimary,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
