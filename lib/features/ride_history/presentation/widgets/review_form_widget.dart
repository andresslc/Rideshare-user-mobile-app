// import 'package:driver_app/core/extensions/context_extension.dart';
// import 'package:driver_app/core/extensions/theme_extension.dart';
// import 'package:driver_app/core/theme/app_colors.dart';
// import 'package:driver_app/shared/widgets/app_button.dart';
// import 'package:driver_app/shared/widgets/app_gradient_box.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_rating_bar/flutter_rating_bar.dart';
// import 'package:gap/gap.dart';

// class ReviewForm extends StatefulWidget {
//   // ✅ _ hata diya
//   final String passengerId;
//   final Function(String passengerId, int rating, String description) onSubmit;

//   const ReviewForm({
//     super.key,
//     required this.passengerId,
//     required this.onSubmit,
//   });

//   @override
//   State<ReviewForm> createState() => _ReviewFormState();
// }

// class _ReviewFormState extends State<ReviewForm> {
//   int _rating = 1;
//   final TextEditingController _reviewController = TextEditingController();

//   @override
//   void dispose() {
//     _reviewController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(l10n.review, style: context.textTheme.titleSmall),
//         const Gap(10),
//         AppGradientBox(
//           isPlain: Theme.of(context).brightness == Brightness.light,
//           cornerRadius: 10,
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               RatingBar.builder(
//                 initialRating: _rating.toDouble(),
//                 minRating: 1,
//                 allowHalfRating: false,
//                 itemCount: 5,
//                 itemSize: 25,
//                 itemBuilder: (_, __) =>
//                     Icon(Icons.star_rounded, color: AppColors.star),
//                 onRatingUpdate: (value) =>
//                     setState(() => _rating = value.toInt()),
//               ),
//               const Gap(8),
//               TextField(
//                 controller: _reviewController,
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   hintText: l10n.addReviewHere,
//                   border: InputBorder.none,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const Gap(8),
//         AppButton(
//           text: "Submit Review",
//           onPressed: () => widget.onSubmit(
//             widget.passengerId,
//             _rating,
//             _reviewController.text.trim(),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:gap/gap.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';

class ReviewForm extends StatefulWidget {
  final String passengerId;
  final Function(String passengerId, int rating)
  onSubmit; // ✅ description hata diya

  const ReviewForm({
    super.key,
    required this.passengerId,
    required this.onSubmit,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  int _rating = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.review, style: context.textTheme.titleSmall),
        const Gap(10),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: context.appColors.brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.appColors.brand.withValues(alpha: 0.4),
            ),
          ),
          child: RatingBar.builder(
            initialRating: _rating.toDouble(),
            minRating: 1,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: 25,
            itemBuilder: (_, _) =>
                const Icon(Icons.star_rounded, color: AppColors.star),
            onRatingUpdate: (value) => setState(() => _rating = value.toInt()),
          ),
        ),
        const Gap(8),
        AppButton(
          text: "Submit Review",
          onPressed: () =>
              widget.onSubmit(widget.passengerId, _rating), // ✅ only rating
        ),
      ],
    );
  }
}
