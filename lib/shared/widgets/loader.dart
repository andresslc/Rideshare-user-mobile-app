import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../core/extensions/theme_extension.dart';

class CustomLoader {
  static final CustomLoader _instance = CustomLoader._createObject();
  factory CustomLoader() => _instance;
  CustomLoader._createObject();

  OverlayEntry? _overlayEntry;
  OverlayState? _overlayState;

  void _buildLoader(BuildContext context) {
    _overlayEntry = OverlayEntry(
      maintainState: true,
      builder: (_) => SizedBox.expand(child: buildLoader(context)),
    );
  }

  void showLoader(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayState = Overlay.of(context);
    _buildLoader(context);

    _overlayState?.insert(_overlayEntry!);
  }

  void hideLoader() {
    try {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } catch (e) {
      debugPrint("Exception in hideLoader: $e");
    }
  }

  PopScope<dynamic> buildLoader(
    BuildContext context, {
    Color? backgroundColor,
  }) {
    backgroundColor ??= const Color(0xffa8a8a8).withValues(alpha: .2);

    return PopScope(
      canPop: false, // Blocks back button
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background blocker
          ModalBarrier(dismissible: false, color: backgroundColor),

          // Center loader
          const Center(child: CustomScreenLoader()),
        ],
      ),
    );
  }
}

class CustomScreenLoader extends StatelessWidget {
  const CustomScreenLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Container(
        padding: const EdgeInsets.all(8), // Makes loader compact
        decoration: BoxDecoration(
          color: context.theme.colorScheme.onPrimary,
          shape: BoxShape.circle,
        ),
        child: LoadingAnimationWidget.inkDrop(
          size: 35,
          color: context.theme.colorScheme.secondary,
        ),
      ),
    );
  }
}
