import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_app/core/core.dart';

import 'app_button.dart';

class CameraBottomSheetResult {
  final ImageSource? source;
  final bool remove;

  const CameraBottomSheetResult.pick(this.source) : remove = false;
  const CameraBottomSheetResult.remove()
    : source = null,
      remove = true;
}

class CameraBottomSheet extends StatelessWidget {
  final bool canRemove;

  const CameraBottomSheet({super.key, this.canRemove = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 50,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pop(
                          context,
                          const CameraBottomSheetResult.pick(
                            ImageSource.gallery,
                          ),
                        ),
                    child: Text(
                      context.l10n.upload_image,
                      style: context.textTheme.titleSmall,
                    ),
                  ),
                ),
                const Divider(thickness: 1.5, height: 1),
                SizedBox(
                  height: 50,
                  child: TextButton(
                    onPressed: () => Navigator.pop(
                      context,
                      const CameraBottomSheetResult.pick(ImageSource.camera),
                    ),
                    child: Text(
                      context.l10n.take_photo,
                      style: context.textTheme.titleSmall,
                    ),
                  ),
                ),
                if (canRemove) ...[
                  const Divider(thickness: 1.5, height: 1),
                  SizedBox(
                    height: 50,
                    child: TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const CameraBottomSheetResult.remove(),
                      ),
                      child: Text(
                        context.l10n.remove_photo,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Gap(15),
          SafeArea(
            top: false,
            child: AppButton(
              text: context.l10n.cancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
