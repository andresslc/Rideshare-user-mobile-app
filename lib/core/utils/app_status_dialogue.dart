import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';

import '../../shared/shared.dart';

enum DialogToastType { info, success, warning, error }

class AppToastDialog {
  AppToastDialog._();

  static OverlayEntry? _overlayEntry;
  static Timer? _dismissTimer;

  /// Global method to show a toast dialog
  static void show(
    BuildContext context, {
    DialogToastType type = DialogToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
    String? subtitle,

    /// Optional button text
    String? buttonText,

    /// Optional button callback
    VoidCallback? onButtonPressed,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    _dismissCurrent();

    final style = _resolveStyle(
      type,
      Theme.of(context),
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );

    // Default titles per type
    final defaultTitles = {
      DialogToastType.success: context.l10n.success,
      DialogToastType.error: context.l10n.error,
      DialogToastType.warning: context.l10n.warning,
      DialogToastType.info: context.l10n.info,
    };

    // Default subtitles per type
    final defaultSubtitles = {
      DialogToastType.success: "Operation completed successfully.",
      DialogToastType.error: "Something went wrong.",
      DialogToastType.warning: "Please check your input.",
      DialogToastType.info: "Here is some information.",
    };

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // This blocks touches behind the overlay
          ModalBarrier(
            dismissible: false, // user cannot tap to dismiss
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1), // optional dim background
          ),
          Center(
            child: _ToastDialogOverlay(
              title: title ?? defaultTitles[type]!,
              subtitle: subtitle ?? defaultSubtitles[type],
              style: style,
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
    _dismissTimer = Timer(duration, _dismissCurrent);
  }

  /// Global method to close the toast manually
  static void close() {
    _dismissCurrent();
  }

  static void _dismissCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static _DialogStyle _resolveStyle(
    DialogToastType type,
    ThemeData theme, {
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    final appColors = theme.extension<AppThemeColors>();
    final surfaceColor = theme.colorScheme.surface;

    switch (type) {
      case DialogToastType.success:
        return _DialogStyle(
          imagePath: AppIcons.tick,
          iconColor: AppColors.success,
          backgroundColor: Color.alphaBlend(
            AppColors.brand.withValues(),
            surfaceColor,
          ),
          buttonText: buttonText,
          onButtonPressed: onButtonPressed,
        );

      case DialogToastType.warning:
        return _DialogStyle(
          imagePath: AppIcons.tick,
          backgroundColor: Color.alphaBlend(
            Colors.orange.withValues(),
            surfaceColor,
          ),
          buttonText: buttonText,
          onButtonPressed: onButtonPressed,
        );

      case DialogToastType.error:
        return _DialogStyle(
          imagePath: AppIcons.tick,
          backgroundColor: Color.alphaBlend(
            AppColors.error.withValues(),
            surfaceColor,
          ),
          buttonText: buttonText,
          onButtonPressed: onButtonPressed,
        );

      case DialogToastType.info:
        return _DialogStyle(
          icon: Icons.info_rounded,
          iconColor: appColors?.brand ?? theme.colorScheme.primary,
          backgroundColor: surfaceColor,
          buttonText: buttonText,
          onButtonPressed: onButtonPressed,
        );
    }
  }
}

class _DialogStyle {
  const _DialogStyle({
    this.icon,
    this.imagePath,
    this.iconColor,
    required this.backgroundColor,
    this.buttonText,
    this.onButtonPressed,
    this.buttonColor,
    this.buttonTextColor,
  });

  final IconData? icon;
  final Color? iconColor;
  final Color backgroundColor;
  final String? imagePath;

  /// Button configuration
  final String? buttonText;
  final Color? buttonColor;
  final Color? buttonTextColor;
  final VoidCallback? onButtonPressed;
}

class _ToastDialogOverlay extends StatelessWidget {
  const _ToastDialogOverlay({
    required this.title,
    this.subtitle,
    required this.style,
  });

  final String title;
  final String? subtitle;
  final _DialogStyle style;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * 0.8;

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        // color: Colors.transparent,
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          minWidth: dialogWidth,
          maxHeight: size.height * 0.5,
        ),
        child: AppGradientBox(
          // isPlain: context.theme.brightness == Brightness.light,

          // isPlain: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () {
                      AppToastDialog.close();
                    },
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
                ),
                Column(
                  children: [
                    /// Icon or Image
                    if (style.imagePath != null)
                      Image.asset(style.imagePath!, height: 40, width: 40)
                    else if (style.icon != null)
                      Icon(
                        style.icon,
                        size: 40,
                        color: style.iconColor ?? AppColors.brand,
                      ),

                    const SizedBox(height: 12),

                    /// Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),

                    /// Subtitle
                    if (subtitle != null && subtitle!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.subtitledialogue,
                                fontSize: size.width * 0.038,
                              ),
                        ),
                      ),

                    /// Button (optional)
                    if (style.onButtonPressed != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: AppButton(
                          text: style.buttonText ?? "OK",
                          onPressed: () {
                            style.onButtonPressed?.call();
                            AppToastDialog.close(); // close overlay
                          },
                          backgroundColor: style.buttonColor ?? AppColors.brand,
                          fontColor: style.buttonTextColor ?? Colors.white,
                          height: 45,
                          width: size.width * 0.35,
                          radius: 12,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
