import 'package:flutter/material.dart';
import 'package:ride_app/core/utils/app_status_dialogue.dart';

extension ToastDialogExtension on BuildContext {
  void showDialogToast({
    DialogToastType type = DialogToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    AppToastDialog.show(
      this,
      onButtonPressed: onButtonPressed,
      type: type,
      duration: duration,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
    );
  }
}
