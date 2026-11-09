import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

class SelectableImageCard extends StatelessWidget {
  final String label;
  final String imagePath;
  // final String subTitle;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const SelectableImageCard({
    super.key,
    required this.label,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
    // required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTap(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: AppGradientBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          border: isSelected
              ? const BorderSide(color: AppColors.brand, width: 2)
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                width: context.screenWidth * 0.3,
                fit: BoxFit.contain,
                // color: !context.isDark ? : null,
              ),
              const SizedBox(height: 8),
              Text(
                label.capitalised,
                style: context.textTheme.titleSmall?.copyWith(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class _CheckBadge extends StatelessWidget {
//   const _CheckBadge();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 18,
//       height: 19,
//       decoration: const BoxDecoration(
//         color: AppColors.brand,
//         shape: BoxShape.circle,
//       ),
//       child: const Icon(Icons.check, size: 14, color: Colors.black),
//     );
//   }
// }
