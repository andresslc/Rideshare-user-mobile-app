import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
}

class CustomTap extends StatelessWidget {
  const CustomTap._({
    super.key,
    this.onTap,
    required this.child,
    this.padding = 0.0,
    this.radius = 12.0,
    this.isNeedOverlay = true,
    this.hapticFeedbackType = HapticFeedbackType.lightImpact,
  });

  /// Default constructor
  factory CustomTap({
    Key? key,
    VoidCallback? onTap,
    required Widget child,
    double padding = 0.0,
    double radius = 12.0,
    bool isNeedOverlay = true,
    HapticFeedbackType hapticFeedbackType = HapticFeedbackType.lightImpact,
  }) {
    return CustomTap._(
      key: key,
      onTap: onTap,
      padding: padding,
      radius: radius,
      isNeedOverlay: isNeedOverlay,
      hapticFeedbackType: hapticFeedbackType,
      child: child,
    );
  }

  /// No splash, no highlight, no radius
  factory CustomTap.noEffect({
    Key? key,
    VoidCallback? onTap,
    required Widget child,
    double padding = 0.0,
  }) {
    return CustomTap._(
      key: key,
      onTap: onTap,
      padding: padding,
      radius: 0.0,
      isNeedOverlay: false,
      hapticFeedbackType: HapticFeedbackType.lightImpact,
      child: child,
    );
  }

  /// No splash but keep radius
  factory CustomTap.noSplash({
    Key? key,
    VoidCallback? onTap,
    required Widget child,
    double padding = 0.0,
    double radius = 12.0,
  }) {
    return CustomTap._(
      key: key,
      onTap: onTap,
      padding: padding,
      radius: radius,
      isNeedOverlay: false,
      child: child,
    );
  }

  /// Heavy haptic variant
  factory CustomTap.heavy({
    Key? key,
    VoidCallback? onTap,
    required Widget child,
    double padding = 0.0,
    double radius = 12.0,
  }) {
    return CustomTap._(
      key: key,
      onTap: onTap,
      padding: padding,
      radius: radius,
      hapticFeedbackType: HapticFeedbackType.heavyImpact,
      child: child,
    );
  }

  final VoidCallback? onTap;
  final Widget child;
  final double padding;
  final double radius;
  final bool isNeedOverlay;
  final HapticFeedbackType hapticFeedbackType;

  void _triggerHaptic() {
    switch (hapticFeedbackType) {
      case HapticFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = radius > 0 ? BorderRadius.circular(radius) : null;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: InkWell(
        borderRadius: borderRadius,
        splashColor: isNeedOverlay
            ? AppColors.brand.withValues(alpha: 0.1)
            : Colors.transparent,
        highlightColor: isNeedOverlay
            ? AppColors.brand.withValues(alpha: 0.1)
            : Colors.transparent,
        onTap: () {
          _triggerHaptic();
          onTap?.call();
        },
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
    );
  }
}
// enum HapticFeedbackType {
//   lightImpact,
//   mediumImpact,
//   heavyImpact,
//   selectionClick,
// }

// class CustomTap extends StatelessWidget {
//   const CustomTap({
//     super.key,
//     this.onTap,
//     required this.child,
//     this.padding = 0.0,
//     this.radius = 12.0,
//     this.isNeedOverlay = true,
//     this.hapticFeedbackType = HapticFeedbackType.lightImpact,
//   });

//   final VoidCallback? onTap;
//   final Widget child;
//   final double padding;
//   final double radius;
//   final bool isNeedOverlay;
//   final HapticFeedbackType hapticFeedbackType;

//   void _triggerHaptic() {
//     switch (hapticFeedbackType) {
//       case HapticFeedbackType.lightImpact:
//         HapticFeedback.lightImpact();
//         break;
//       case HapticFeedbackType.mediumImpact:
//         HapticFeedback.mediumImpact();
//         break;
//       case HapticFeedbackType.heavyImpact:
//         HapticFeedback.heavyImpact();
//         break;
//       case HapticFeedbackType.selectionClick:
//         HapticFeedback.selectionClick();
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(radius),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(radius),
//         splashColor: isNeedOverlay
//             ? AppColors.brand.withValues(alpha: 0.1)
//             : Colors.transparent, // Optional: disables ripple
//         highlightColor: isNeedOverlay
//             ? AppColors.brand.withValues(alpha: 0.1)
//             : Colors.transparent,
//         onTap: () {
//           _triggerHaptic();
//           if (onTap != null) {
//             onTap!();
//           }
//         },
//         child: Padding(padding: EdgeInsets.all(padding), child: child),
//       ),
//     );
//   }
// }
