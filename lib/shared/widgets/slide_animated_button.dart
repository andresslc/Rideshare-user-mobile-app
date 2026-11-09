import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/core/theme/app_colors.dart';

import '../../core/extensions/context_extension.dart';

class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.text,
    this.onSubmit,
    this.height = 56,
    this.radius = 16,
    this.backgroundColor,
    this.thumbColor,
    this.icon,
    this.isAccepted = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.acceptedText,
  });

  final String text;
  final VoidCallback? onSubmit;
  final double height;
  final double radius;
  final bool isAccepted;
  final bool isLoading;
  final bool isDisabled;

  final Color? backgroundColor;
  final Color? thumbColor;
  final IconData? icon;
  final String? acceptedText;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with TickerProviderStateMixin {
  static const double _completionThreshold = 0.85;

  late final AnimationController _slideController;
  late final AnimationController _arrowsController;

  double _value = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _arrowsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    if (widget.isAccepted) {
      _value = 1.0;
      _submitted = true;
    }
  }

  @override
  void didUpdateWidget(SlideToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset if we were waiting and it failed or was cancelled, or slider was dragged but not accepted/loading/disabled
    if (!widget.isAccepted &&
        !widget.isLoading &&
        (oldWidget.isAccepted || oldWidget.isLoading || widget.isDisabled || _value > 0)) {
      _reset();
    }

    if (widget.isAccepted && !oldWidget.isAccepted) {
      _animateTo(1.0);
      _submitted = true;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _arrowsController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final Animation<double> animation =
        Tween<double>(begin: _value, end: target).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: target == 0 ? Curves.easeOutBack : Curves.easeOutCubic,
          ),
        );

    void listener() {
      setState(() => _value = animation.value);
    }

    _slideController.addListener(listener);
    _slideController.forward(from: 0).then((_) {
      _slideController.removeListener(listener);
    });
  }

  void _reset() {
    _submitted = false;
    _animateTo(0.0);
  }

  void _handleSubmit() {
    if (_submitted || widget.isDisabled || widget.isLoading) {
      _animateTo(0.0);
      return;
    }

    HapticFeedback.heavyImpact();
    widget.onSubmit?.call();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !widget.isLoading && !widget.isAccepted) {
        _reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isActuallyDisabled =
        widget.isDisabled && !widget.isLoading && !widget.isAccepted;
    final Color trackColor = widget.backgroundColor ?? context.appColors.brand;
    // final Color thumbColor = widget.thumbColor ?? Colors.white;
    final Color thumbColor = AppColors.brand;
    final bool showCheck = widget.isAccepted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = widget.height;
        const double padding = 5.0;
        final double thumbSize = height - (padding * 2);
        final double maxDrag =
            (constraints.maxWidth - thumbSize - (padding * 2)).clamp(
              0.0,
              double.infinity,
            );
        final double safeMaxDrag = maxDrag <= 0 ? 1 : maxDrag;
        final double thumbX = padding + (maxDrag * _value);

        return Opacity(
          opacity: isActuallyDisabled ? 0.6 : 1.0,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: context.appColors.border,
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(
                color: context.isDark
                    ? AppColors.genericBorder
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // 🔹 Track Fill Gradient
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              trackColor.withValues(alpha: 0.7),
                              trackColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(widget.radius),
                        ),
                      ),
                    ),
                  ),

                  // 🔹 Background Hint Arrows
                  if (!widget.isLoading && !widget.isAccepted && _value < 0.3)
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(left: thumbSize + 22),
                        child: FadeTransition(
                          opacity: _arrowsController.drive(
                            CurveTween(
                              curve: const Interval(
                                0.0,
                                0.4,
                                curve: Curves.easeInOut,
                              ),
                            ),
                          ),
                          child: Row(
                            children: List.generate(
                              3,
                              (i) => Icon(
                                Icons.keyboard_arrow_right_rounded,
                                size: 18,
                                color: context.appColors.surface.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 🔹 Text / Status Layer
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: widget.isLoading
                          ? const SizedBox.shrink()
                          : showCheck
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.acceptedText ??
                                      context.l10n.send_request,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            )
                          : Opacity(
                              opacity: (1 - (_value * 2)).clamp(0.0, 1.0),
                              child: Text(
                                widget.text,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  // color: context.appColors.surface.withValues(
                                  //   alpha: 0.8,
                                  // ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),

                  // 🔹 Loading Spinner
                  if (widget.isLoading)
                    Center(
                      child: LoadingAnimationWidget.inkDrop(
                        color: _value > 0.5 ? Colors.white : trackColor,
                        size: height * 0.45,
                      ),
                    ),

                  // 🔹 Thumb
                  Positioned(
                    left: thumbX,
                    top: padding,
                    bottom: padding,
                    child: GestureDetector(
                      onHorizontalDragUpdate:
                          (widget.isDisabled ||
                              widget.isLoading ||
                              widget.isAccepted)
                          ? null
                          : (details) {
                              log(
                                "$_value::::::::::${((_value >= _completionThreshold))}::::",
                              );
                              final double next =
                                  (_value + (details.delta.dx / safeMaxDrag))
                                      .clamp(0.0, 1.0);
                              setState(() => _value = next);
                            },
                      onHorizontalDragEnd:
                          (widget.isDisabled ||
                              widget.isLoading ||
                              widget.isAccepted)
                          ? null
                          : (_) {
                              if (_value >= _completionThreshold) {
                                _animateTo(1.0);
                                _handleSubmit();
                              } else {
                                _animateTo(0.0);
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: thumbSize,
                        height: thumbSize,
                        transform: Matrix4.diagonal3Values(
                          _value > 0.01 && !widget.isAccepted ? 1.05 : 1.0,
                          _value > 0.01 && !widget.isAccepted ? 1.05 : 1.0,
                          1.0,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isAccepted
                              ? Colors.transparent
                              : thumbColor,
                          borderRadius: BorderRadius.circular(
                            widget.radius - 6,
                          ),
                          boxShadow: widget.isAccepted
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: widget.isAccepted
                              ? const SizedBox.shrink()
                              : Icon(
                                  widget.icon ??
                                      Icons.arrow_forward_ios_rounded,
                                  color: Colors.black,
                                  size: 18,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
