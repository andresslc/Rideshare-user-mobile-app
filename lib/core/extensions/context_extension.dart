import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/features/auth/domain/entities/auth_entity.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/custom_dialogue.dart';
import '../../shared/widgets/loader.dart';
import '../navigation/routes.dart';
import '../utils/toast_manager.dart';
import 'theme_extension.dart';

/// Quick access to [MediaQuery] dimensions.
extension ContextExtension on BuildContext {
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  // localization
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension LoaderExtension on BuildContext {
  void showLoader() {
    CustomLoader().showLoader(this);
  }

  void hideLoader() {
    CustomLoader().hideLoader();
  }
}

extension CheckUserState on BuildContext {
  void whereToGo(AuthResponseEntity response, {String? phoneNumber}) {
    log("WHERE TO GO ${response.isOnboarded}");

    if (response.isOnboarded) {
      goNamed(Routes.home.name);
    } else {
      goNamed(
        Routes.createProfile.name,
        extra: response.user?.phone ?? phoneNumber,
      );
    }
  }
}

extension ToastExtension on BuildContext {
  void showToast(
    String message, {
    Duration duration = const Duration(seconds: 3),
    ToastType type = ToastType.info,
  }) {
    ToastManager.showToast(
      this,
      message: message,
      duration: duration,
      type: type,
    );
  }

  void showSuccessToast(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showToast(message, duration: duration, type: ToastType.success);
  }

  void showWarningToast(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showToast(message, duration: duration, type: ToastType.warning);
  }

  void showErrorToast(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showToast(message, duration: duration, type: ToastType.error);
  }
}

extension PromoDialogExtension on BuildContext {
  void showPromoRemovalWarning({
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: this,
      barrierDismissible: true,
      builder: (dialogContext) {
        return GradientSideDialog(
          title: l10n.warning,
          subtitle: l10n.promo_removal_warning,
          icon: Icons.warning_amber_rounded,
          buttons: [
            AppButton(
              text: l10n.cancel,
              backgroundColor: Colors.transparent,
              fontColor: appColors.textPrimary,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            AppButton(
              text: l10n.ok,
              backgroundColor: appColors.brand,
              fontColor: appColors.textPrimary,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }
}





