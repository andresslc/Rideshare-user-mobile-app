import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ride_app/core/core.dart';


enum ToastType { info, success, warning, error }

class ToastManager {
  ToastManager._();

  static OverlayEntry? _overlayEntry;
  static Timer? _dismissTimer;

  static void showToast(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    ToastType type = ToastType.info,
  }) {
    if (message.trim().isEmpty) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismissCurrentToast();

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => _ToastOverlay(message: message, type: type),
    );

    overlay.insert(_overlayEntry!);
    _dismissTimer = Timer(duration, _dismissCurrentToast);
  }

  static void _dismissCurrentToast() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _ToastOverlay extends StatelessWidget {
  const _ToastOverlay({required this.message, required this.type});

  final String message;
  final ToastType type;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding =
        mediaQuery.padding.bottom + mediaQuery.viewInsets.bottom + 20;

    final style = _ToastStyle.resolve(Theme.of(context), type);

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _ToastCard(message: message, style: style),
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({required this.message, required this.style});

  final String message;
  final _ToastStyle style;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(_opacity);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.isDark
                  ? widget
                        .style
                        .backgroundColor // dark mode
                  // ignore: deprecated_member_use
                  : widget.style.backgroundColor.withOpacity(0.9),
              // color: widget.style.backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.style.borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  widget.style.icon,
                  size: 19,
                  color: context.isDark
                      ? widget
                            .style
                            .iconColor // dark mode
                      : AppColors.lightButton,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.style.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastStyle {
  const _ToastStyle({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  static _ToastStyle resolve(ThemeData theme, ToastType type) {
    final appColors = theme.extension<AppThemeColors>();
    final surfaceColor = appColors?.surface ?? theme.colorScheme.surface;
    final textColor = appColors?.textPrimary ?? theme.colorScheme.onSurface;

    switch (type) {
      case ToastType.success:
        return _ToastStyle(
          icon: Icons.check_circle_rounded,
          backgroundColor: Color.alphaBlend(
            AppColors.success.withValues(alpha: 0.16),
            surfaceColor,
          ),
          borderColor: AppColors.success.withValues(alpha: 0.45),
          iconColor: AppColors.success,
          textColor: textColor,
        );
      case ToastType.warning:
        return _ToastStyle(
          icon: Icons.warning_amber_rounded,
          backgroundColor: Color.alphaBlend(
            Colors.orange.withValues(alpha: 0.14),
            surfaceColor,
          ),
          borderColor: Colors.orange.withValues(alpha: 0.45),
          iconColor: Colors.orange.shade700,
          textColor: textColor,
        );
      case ToastType.error:
        return _ToastStyle(
          icon: Icons.error_rounded,
          backgroundColor: Color.alphaBlend(
            AppColors.error.withValues(alpha: 0.16),
            surfaceColor,
          ),
          borderColor: AppColors.error.withValues(alpha: 0.45),
          iconColor: AppColors.error,
          textColor: textColor,
        );
      case ToastType.info:
        final isDark = theme.brightness == Brightness.dark;
        return _ToastStyle(
          icon: Icons.info_rounded,
          backgroundColor: isDark
              ? AppColors.lightButton
              : AppColors.brandLight,
          //  const Color(0xFFF0F4F1),
          borderColor: isDark
              ? const Color(0xFF334039)
              : const Color(0xFFD2DCD4),
          iconColor: appColors?.brand ?? theme.colorScheme.primary,
          textColor: textColor,
        );
    }
  }
}
