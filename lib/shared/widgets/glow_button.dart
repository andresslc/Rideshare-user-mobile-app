import 'package:flutter/material.dart';

import '../../core/extensions/theme_extension.dart';
import '../../core/theme/app_colors.dart';

class GlowButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double? size;
  const GlowButton({super.key, this.onTap, required this.child, this.size});

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  static const _animationDuration = Duration(milliseconds: 180);
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || widget.onTap == null) return;
    setState(() {
      _isPressed = value;
    });
  }

  List<BoxShadow> _buildPressedShadow(BuildContext context) {
    if (!_isPressed) return const [];

    return [
      BoxShadow(
        color: const Color.fromRGBO(97, 203, 8, 0.34),
        spreadRadius: context.isDark ? 1 : 0,
        blurRadius: context.isDark ? 16 : 12,
        offset: const Offset(0, 0),
      ),
      BoxShadow(
        // ignore: deprecated_member_use
        color: Colors.black.withOpacity(context.isDark ? 0.24 : 0.12),
        spreadRadius: 1,
        blurRadius: context.isDark ? 18 : 12,
        offset: const Offset(0, 8),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      borderRadius: BorderRadius.circular(8),
      splashColor: (context.isDark) ? const Color(0x6661CB08) : null,
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        // ignore: deprecated_member_use
        transform: Matrix4.identity()..scale(_isPressed ? 1.06 : 1.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: _buildPressedShadow(context),
        ),
        child: Ink(
          width: widget.size ?? 50,
          height: widget.size ?? 50,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.brand,
            border: Border.all(color: const Color(0x6661CB08)),
            borderRadius: BorderRadius.circular(8),
            gradient: (context.isDark)
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(97, 203, 8, 0.32),
                      Color.fromRGBO(97, 203, 8, 0.1),
                      Color.fromRGBO(97, 203, 8, 0.16),
                    ],
                    stops: [0, 0.5, 1],
                  )
                : null,
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(97, 203, 8, 0.12),
                  Color.fromRGBO(97, 203, 8, 0.04),
                  Color.fromRGBO(97, 203, 8, 0.07),
                ],
                stops: [0, 0.5, 1],
              ),
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
