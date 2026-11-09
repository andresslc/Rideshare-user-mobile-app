import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_colors.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';

// class SheetBacgroundWidget extends StatelessWidget {
//   const SheetBacgroundWidget({
//     super.key,
//     required this.child,
//     this.borderWidth = 1.0,
//     this.radius = 20.0,
//     this.borderGradient,
//     this.backgroundGradient,
//     this.blurSigma = 84.0,
//     this.enableBackdropBlur = true,
//     this.padding = EdgeInsets.zero,
//     this.isPlain = false,
//     this.border,
//   });

//   final Widget child;
//   final double borderWidth;
//   final double radius;
//   final LinearGradient? borderGradient;
//   final LinearGradient? backgroundGradient;
//   final double blurSigma;
//   final bool enableBackdropBlur;
//   final EdgeInsetsGeometry padding;
//   final bool isPlain;
//   final Border? border;

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     // Default gradients for Dark Mode
//     const defaultDarkBorderGradient = LinearGradient(
//       begin: Alignment.topCenter,
//       end: Alignment.bottomCenter,
//       colors: [
//         Color.fromRGBO(97, 203, 8, 0.32),
//         Color.fromRGBO(97, 203, 8, 0.10),
//         Color.fromRGBO(97, 203, 8, 0.16),
//       ],
//       stops: [0.0, 0.5, 1.0],
//     );

//     const defaultDarkBackgroundGradient = LinearGradient(
//       begin: Alignment.topCenter,
//       end: Alignment.bottomCenter,
//       colors: [
//         Color.fromRGBO(97, 203, 8, 0.12),
//         Color.fromRGBO(97, 203, 8, 0.04),
//         Color.fromRGBO(97, 203, 8, 0.07),
//       ],
//       stops: [0.0, 0.5, 1.0],
//     );

//     final effectiveBorderGradient = borderGradient ?? defaultDarkBorderGradient;
//     final effectiveBackgroundGradient =
//         backgroundGradient ?? defaultDarkBackgroundGradient;

//     final double borderRadius = (radius - borderWidth / 2)
//         .clamp(0.0, double.infinity)
//         .toDouble();
//     final double innerRadius = (radius - borderWidth)
//         .clamp(0.0, double.infinity)
//         .toDouble();
//     final borderShape = RoundedSuperellipseBorder(
//       borderRadius: BorderRadius.circular(borderRadius),
//     );
//     final innerShape = RoundedSuperellipseBorder(
//       borderRadius: BorderRadius.circular(innerRadius),
//     );

//     if (!isDark) {
//       return Container(
//         decoration: BoxDecoration(
//           color: isPlain ? Colors.white : null,
//           gradient: isPlain ? null : effectiveBackgroundGradient,
//           borderRadius: BorderRadius.circular(radius),
//           border:
//               border ??
//               (isPlain
//                   ? Border.all(color: AppColors.darkTextSecondary, width: 0.4)
//                   : null), // ✅ black border for plain light mode
//         ),
//         child: Padding(padding: padding, child: child),
//       );
//     }
//     Widget content = DecoratedBox(
//       decoration: ShapeDecoration(
//         shape: innerShape,
//         gradient: effectiveBackgroundGradient,
//       ),
//       child: Padding(padding: padding, child: child),
//     );

//     if (enableBackdropBlur) {
//       content = BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
//         child: content,
//       );
//     }
//     Widget box = CustomPaint(
//       foregroundPainter: _GradientBorderPainter(
//         shape: borderShape,
//         gradient: effectiveBorderGradient,
//         strokeWidth: borderWidth,
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(borderWidth),
//         child: ClipPath(
//           clipper: ShapeBorderClipper(shape: innerShape),
//           child: content,
//         ),
//       ),
//     );

//     if (border != null) {
//       box = Container(
//         decoration: BoxDecoration(
//           border: border,
//           borderRadius: BorderRadius.circular(radius),
//         ),
//         child: box,
//       );
//     }

//     return box;
//   }
// }

// class _GradientBorderPainter extends CustomPainter {
//   _GradientBorderPainter({
//     required this.shape,
//     required this.gradient,
//     required this.strokeWidth,
//   });

//   final ShapeBorder shape;
//   final Gradient gradient;
//   final double strokeWidth;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Rect rect = Offset.zero & size;
//     final Rect strokeRect = rect.deflate(strokeWidth / 2);
//     final Paint paint = Paint()
//       ..shader = gradient.createShader(rect)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth;
//     final Path path = shape.getOuterPath(strokeRect);
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
//     return oldDelegate.strokeWidth != strokeWidth ||
//         oldDelegate.gradient != gradient ||
//         oldDelegate.shape != shape;
//   }
// }
class PlainBackgroundWidget extends StatelessWidget {
  const PlainBackgroundWidget({
    super.key,
    required this.child,
    this.radius = 32,
    this.padding = EdgeInsets.zero,
    this.color,
    this.border,
    this.isPlain,
    this.isAllRounded = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderSide? border;
  final bool? isPlain;
  final bool isAllRounded;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDark;

    final usePlain = isPlain ?? isDarkMode;
    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        color:
            color ??
            (usePlain
                ? Theme.of(context).cardColor
                : AppColors.darkTextPrimary),
        //  condition yahan apply hogi
        //  condition yahan apply hogi
        shape: RoundedSuperellipseBorder(
          borderRadius: isAllRounded
              ? BorderRadius.circular(radius)
              : BorderRadius.only(
                  topLeft: Radius.circular(radius),
                  topRight: Radius.circular(radius),
                ),

          side:
              border ??
              BorderSide(
                color: Colors.grey.withValues(alpha: 0.3), // subtle grey border
                width: 0.5,
              ),
        ),
      ),
      child: child,
    );
  }
}
