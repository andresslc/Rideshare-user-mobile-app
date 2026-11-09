import 'package:flutter/material.dart';
import 'package:ride_app/core/core.dart';

class AppGradientBox extends StatelessWidget {
  const AppGradientBox({
    super.key,
    required this.child,
    this.borderWidth,
    this.cornerRadius = 20.0,
    this.borderGradient,
    this.blurSigma = 84.0,
    this.enableBackdropBlur = true,
    this.padding = EdgeInsets.zero,
    this.isPlain = false,
    this.border,
  });

  final Widget child;
  final double? borderWidth;
  final double cornerRadius;
  final LinearGradient? borderGradient;
  final double blurSigma;
  final bool enableBackdropBlur;
  final EdgeInsetsGeometry padding;
  final bool isPlain;
  final BorderSide? border;

  ShapeDecoration _shape(bool isDark) {
    final usePlainLightStyle = isPlain && !isDark;

    return ShapeDecoration(
      color: usePlainLightStyle ? Colors.white : null,
      gradient: usePlainLightStyle ? null : AppColors.cardGradient,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(cornerRadius),
        side:
            border ??
            BorderSide(
              color:
                  //  usePlainLightStyle
                  //     ? AppColors.darkTextSecondary
                  //     :
                  AppColors.genericBorder,
              width: borderWidth ?? .4,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: _shape(context.isDark),
      child: child,
    );
  }
}
