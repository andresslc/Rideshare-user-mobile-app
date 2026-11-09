import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/constants_data.dart';
import 'package:ride_app/core/services/app_update_service.dart';
import 'package:ride_app/core/theme/app_colors.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/custom_dialogue.dart';

class AppUpdateDialog extends StatelessWidget {
  final bool isForceUpdate;

  const AppUpdateDialog({super.key, required this.isForceUpdate});

  static Future<void> show(
    BuildContext context, {
    required bool isForceUpdate,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => PopScope(
        canPop: !isForceUpdate,
        child: AppUpdateDialog(isForceUpdate: isForceUpdate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientSideDialog(
      title: remoteConfigModel.updateTitle,
      subtitle: remoteConfigModel.updateMessage,
      icon: Icons.system_update,
      iconColor: AppColors.brand,
      buttons: [
        if (!isForceUpdate)
          AppButton(
            text: "Later",
            backgroundColor: AppColors.darkField,
            fontColor: Colors.white70,
            onPressed: () => Navigator.pop(context),
          ),
        AppButton(
          text: "Update Now",
          backgroundColor: AppColors.brand,
          fontColor: Colors.black,
          onPressed: () {
            AppUpdateService.launchStore();
          },
        ),
      ],
    );
  }
}
