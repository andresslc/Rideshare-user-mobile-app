import 'dart:ui';
import 'package:flutter/material.dart';

class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        // ignore: deprecated_member_use
        ? Colors.black.withOpacity(0.55)
        // ignore: deprecated_member_use
        : Colors.white.withOpacity(0.85);
    final iconColor = isDark ? Colors.white : Colors.black87;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.add_rounded, color: iconColor),
                onPressed: onZoomIn,
              ),
              Container(
                height: 1,
                width: 28,
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              IconButton(
                icon: Icon(Icons.remove_rounded, color: iconColor),
                onPressed: onZoomOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
