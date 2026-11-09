import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ride_app/core/core.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    this.height,
    this.width,
    this.radius = 12,
    this.backgroundColor,
    this.onPressed,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.fontColor,
    this.padding,
    this.isDisable = false,
    this.isLoading = false,
    this.child,
    this.alignment = Alignment.center,
    this.needBorder = false,
  });

  final double? height;
  final double? width;
  final double radius;
  final Color? backgroundColor;
  final void Function()? onPressed;
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? fontColor;
  final EdgeInsetsGeometry? padding;
  final bool isDisable;
  final bool isLoading;
  final Widget? child;
  final AlignmentGeometry alignment;
  final bool needBorder;
  @override
  AppButtonState createState() => AppButtonState();
}

class AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? context.screenWidth,
      // agar null ho to parent ki width lega
      height: widget.height ?? 50,
      child: GestureDetector(
        onSecondaryTap: widget.isDisable
            ? null
            : () => setState(() => isPressed = true),
        onTapDown: widget.isDisable
            ? null
            : (_) => setState(() => isPressed = true), // Button pressed
        onTapUp: widget.isDisable
            ? null
            : (_) => setState(() => isPressed = false), // Button released
        onTapCancel: widget.isDisable
            ? null
            : () =>
                  setState(() => isPressed = false), // Handle tap cancellation
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.radius),
            border: widget.needBorder && !widget.isDisable
                ? Border.all(color: context.appColors.brand, width: 1)
                : null,
          ),
          curve: Curves.easeInOut,
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()
            // ignore: deprecated_member_use
            ..scale(isPressed ? 0.93 : 1.0), // Scale down when pressed
          child: ElevatedButton(
            onPressed: (widget.isDisable || widget.isLoading)
                ? null
                : () {
                    HapticFeedback.heavyImpact();
                    widget.onPressed?.call();
                  },
            style: ElevatedButton.styleFrom(
              // disabledBackgroundColor: context.appColors.textPrimary,
              backgroundColor: widget.backgroundColor,
              shadowColor: Colors.transparent,
              alignment: Alignment.center,
              padding: widget.padding ?? const EdgeInsets.all(0),
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(widget.radius),
              // ),
              fixedSize: Size(
                widget.width ?? double.maxFinite,
                widget.height ?? 50,
              ),
            ),
            // child: Align(
            //   alignment: widget.alignment, // default Alignment.center rahega
            //   child:
            //       widget.child ??
            //       Text(
            //         widget.text,
            //         textAlign: TextAlign.center, // default behavior same

            //         style: context.textTheme.bodyMedium?.copyWith(
            //           color: widget.isDisable
            //               ? context.appColors.textSecondary
            //               : widget.fontColor ?? context.appColors.button,
            //           fontSize: widget.fontSize ?? 14,

            //           fontWeight: widget.fontWeight ?? FontWeight.w600,
            //         ),
            //       ),
            // ),
            child: widget.isLoading
                ? LoadingAnimationWidget.threeRotatingDots(
                    color: widget.fontColor ?? context.appColors.button,
                    size: (widget.height ?? 50) * 0.6,
                  )
                : widget.child ??
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: widget.isDisable
                                ? context.appColors.textSecondary
                                : widget.fontColor ?? context.appColors.button,
                            fontSize: widget.fontSize ?? 14,
                            fontWeight: widget.fontWeight ?? FontWeight.w600,
                          ),
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
