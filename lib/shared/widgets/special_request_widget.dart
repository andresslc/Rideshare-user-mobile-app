import 'package:flutter/material.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/shared/widgets/expandable_text.dart';

import '../../core/constants/app_icons.dart';

class SpecialRequest extends StatelessWidget {
  final String? title;
  final String description;
  final String icon;
  final bool showTopBorder;

  const SpecialRequest({
    super.key,
    this.title,

    this.showTopBorder = true,
    this.description =
        "Please make sure to pick me up from the back gate. The gate code is 1234. Also, the dog will be in the car, please drive carefully. I will have luggage and some fragile items, so please handle with care.",
    this.icon = AppIcons.info,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 Top Border Line
        if (showTopBorder)
          Container(
            height: 1,
            width: double.infinity,
            color: context.appColors.border,
          ),

        const SizedBox(height: 12),

        /// 🔹 Icon + Title
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              icon,
              width: context.screenHeight * 0.018,
              height: context.screenHeight * 0.018,
            ),
            const SizedBox(width: 8),
            Text(
              title ?? "",
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1),
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        /// 🔹 Description using ExpandableText
        Padding(
          padding: const EdgeInsets.only(left: 25),
          child: ExpandableText(
            text: description,
            trimLines: 2, // initially 2 lines, can expand
          ),
        ),
      ],
    );
  }
}
