import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/theme/app_colors.dart';

/// A modern Yango/InDrive-style location pin overlay that sits fixed at the screen center.
///
/// Features:
/// - Floating rounded dark badge with tactile lift/drop spring physics.
/// - Crisp ground anchor dot indicating the exact map coordinate.
/// - Connecting vertical stem line that stretches as the badge lifts during drag.
/// - Settle-pulse ripple animation on the ground dot when map pans to a stop.
/// - Tactile haptic feedback on lift and drop.
class FixedCenterPin extends StatefulWidget {
  const FixedCenterPin({
    super.key,
    required this.isDragging,
    this.isLoading = false,
    this.badgeColor,
    this.pinColor,
    this.badgeSize,
    this.pinSize = 42,
    this.liftHeight = 16,
  });

  /// Whether the map underneath is currently being panned/dragged.
  final bool isDragging;

  /// When true, shows a spinner inside the badge while reverse-geocoding.
  final bool isLoading;

  /// Override the badge background color. Defaults to [AppColors.lightButton].
  final Color? badgeColor;

  /// Legacy alias for [badgeColor].
  final Color? pinColor;

  /// Size of the badge in logical pixels. Defaults to 42.
  final double? badgeSize;

  /// Legacy alias for [badgeSize].
  final double pinSize;

  /// How many logical pixels the badge lifts upward when [isDragging] is true.
  final double liftHeight;

  double get effectiveSize => badgeSize ?? pinSize;
  Color get effectiveColor => badgeColor ?? pinColor ?? AppColors.brand;

  @override
  State<FixedCenterPin> createState() => _FixedCenterPinState();
}

class _FixedCenterPinState extends State<FixedCenterPin>
    with TickerProviderStateMixin {
  late final AnimationController _liftController;
  late final Animation<double> _liftAnimation;
  late final Animation<double> _badgeScaleAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScaleAnimation;
  late final Animation<double> _pulseOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Lift & Drop Animation Controller
    _liftController = AnimationController(
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 220),
      vsync: this,
    );

    _liftAnimation = Tween<double>(begin: 0, end: widget.liftHeight).animate(
      CurvedAnimation(
        parent: _liftController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
      ),
    );

    _badgeScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _liftController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeOutCubic,
      ),
    );

    // Ground Dot Settle-Pulse Controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseScaleAnimation = Tween<double>(begin: 0.8, end: 2.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuart),
    );

    _pulseOpacityAnimation = Tween<double>(
      begin: 0.65,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    if (widget.isDragging) {
      _liftController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant FixedCenterPin oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isDragging && !oldWidget.isDragging) {
      HapticFeedback.lightImpact();
      _liftController.forward();
    } else if (!widget.isDragging && oldWidget.isDragging) {
      HapticFeedback.selectionClick();
      _liftController.reverse().then((_) {
        if (mounted) {
          _pulseController.forward(from: 0.0);
        }
      });
    }

    // Trigger pulse when resolving finishes
    if (oldWidget.isLoading && !widget.isLoading && !widget.isDragging) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _liftController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double badgeSize = widget.effectiveSize;
    final Color badgeColor = widget.effectiveColor;
    final double totalHeight = badgeSize + widget.liftHeight + 24;

    return AnimatedBuilder(
      animation: Listenable.merge([_liftController, _pulseController]),
      builder: (context, _) {
        final double liftOffset = _liftAnimation.value.clamp(
          0.0,
          widget.liftHeight,
        );
        final bool isLifted = liftOffset > 0.5;

        return SizedBox(
          width: badgeSize + 24,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Settle pulse ripple ring on ground
              if (_pulseController.isAnimating)
                Positioned(
                  bottom: 0,
                  child: Transform.scale(
                    scale: _pulseScaleAnimation.value,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brand.withValues(
                          alpha: _pulseOpacityAnimation.value,
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. Fixed Ground Center Dot (anchored coordinate point)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Connecting Stem Line (grows as badge lifts)
              if (isLifted)
                Positioned(
                  bottom: 6,
                  child: Opacity(
                    opacity: (liftOffset / widget.liftHeight).clamp(0.0, 1.0),
                    child: Container(
                      width: 2.2,
                      height: liftOffset,
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

              // 4. Floating Badge with icon and pointer
              Positioned(
                bottom: 6 + liftOffset,
                child: Transform.scale(
                  scale: _badgeScaleAnimation.value,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rounded Badge Body
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isLifted ? 0.32 : 0.22,
                              ),
                              blurRadius: isLifted ? 12 : 6,
                              offset: Offset(0, isLifted ? 6 : 3),
                            ),
                          ],
                        ),
                        child: widget.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Image.asset(
                                AppIcons.pickupPerson,
                                width: 22,
                                height: 22,
                                color: Colors.white,
                              ),
                      ),

                      // Downward Badge Beak / Pointer
                      CustomPaint(
                        size: const Size(10, 5),
                        painter: _BadgeBeakPainter(color: badgeColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Draws a small inverted triangle below the badge body to form a pin pointer.
class _BadgeBeakPainter extends CustomPainter {
  const _BadgeBeakPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BadgeBeakPainter oldDelegate) =>
      oldDelegate.color != color;
}
