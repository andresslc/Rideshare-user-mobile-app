import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart' show CustomTap;

import '../../core/constants/app_images.dart';
import '../../core/services/image_service.dart';
import 'camera_bottom_sheet_component.dart';

/// ValueNotifier for holding file path (auto-disposed with widget lifecycle)
class XFileNotifier extends ValueNotifier<String?> {
  XFileNotifier() : super(null);

  void setFile(String? path) => value = path;
  void clearFile() => value = null;
}

enum ImagePickerFieldType { profileImage }

class ImagePickerField extends StatefulWidget {
  const ImagePickerField({
    super.key,
    this.labelColor,
    this.labelText,
    this.onTap,
    this.onPicTap,
    this.type = ImagePickerFieldType.profileImage,
    this.filePath,
    this.imagePath,
    this.assetImagePath, // ✅ NEW
    this.isPickup = false,
    this.showCameraBadge = false,
    this.openFullScreenImage = true,

    this.radius,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.borderColor,
    this.isShowBorder = false,
    this.subText,
    this.isRemovePhoto = true,
    this.allowPreview = true,
    this.badgeIcon = Icons.camera_alt,
    this.badgeCustomIcon,
    this.height = 140,
    this.maxImageSizeInMB = 10,
  }) : assert(
         type != ImagePickerFieldType.profileImage ||
             !(openFullScreenImage && onTap != null),
         'For profileImage type, you cannot use both `openFullScreenImage` and `onTap`. Please choose one behavior.',
       );

  final String? labelText;
  final String? subText;
  final String? filePath;
  final String? imagePath;
  final String? assetImagePath; // ✅ NEW
  final double? radius;
  final Color? labelColor;
  final bool showCameraBadge;
  final bool openFullScreenImage;
  final void Function()? onTap;
  final ValueChanged<String?>? onPicTap;
  final ImagePickerFieldType type;
  final MainAxisAlignment mainAxisAlignment;
  final Color? borderColor;
  final IconData badgeIcon;
  final bool isShowBorder;
  final bool isPickup;
  final bool isRemovePhoto;
  final bool allowPreview;
  final Positioned? badgeCustomIcon;
  final double height;
  final int maxImageSizeInMB;

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  late final XFileNotifier _xFileNotifier;

  @override
  void initState() {
    super.initState();
    _xFileNotifier = XFileNotifier();

    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPicTap?.call(widget.imagePath);
      });
    }
  }

  @override
  void dispose() {
    _xFileNotifier.dispose();
    super.dispose();
  }

  /// Builds image for ProfileImage type
  Widget _buildProfileImage(String? file) {
    if (widget.isPickup &&
        file == null &&
        widget.filePath == null &&
        widget.assetImagePath == null &&
        (widget.imagePath == null || widget.imagePath!.isEmpty)) {
      return DottedBorder(
        options: CircularDottedBorderOptions(
          strokeCap: StrokeCap.butt,
          strokeWidth: 1.5,
          dashPattern: const [6, 6],
          color: context.appColors.brand,
        ),
        child: CircleAvatar(
          radius: widget.radius ?? 48,
          // ignore: deprecated_member_use
          backgroundColor: context.appColors.fieldFill.withOpacity(0.18),
          child: Icon(Icons.add, size: 28, color: context.appColors.brand),
        ),
      );
    }

    // ✅ Picked file
    if (file != null || widget.filePath != null) {
      return CircleAvatar(
        radius: widget.radius ?? 48,
        backgroundColor: widget.isShowBorder
            ? widget.borderColor ?? Colors.white
            : Colors.transparent,
        child: CircleAvatar(
          radius: widget.isShowBorder
              ? (widget.radius ?? 48) - 2
              : widget.radius ?? 48,
          backgroundImage: FileImage(File(file ?? widget.filePath!)),
        ),
      );
    }

    // ✅ Asset image
    if (widget.assetImagePath != null) {
      return CircleAvatar(
        radius: widget.radius ?? 48,
        backgroundColor: widget.isShowBorder
            ? widget.borderColor ?? Colors.white
            : Colors.transparent,
        backgroundImage: AssetImage(widget.assetImagePath!),
      );
    }

    // ✅ Network image
    if (widget.imagePath != null) {
      return CircleAvatar(
        radius: widget.radius ?? 48,
        backgroundColor: widget.isShowBorder
            ? widget.borderColor ?? Colors.white
            : Colors.transparent,
        child: CircleAvatar(
          radius: (widget.isShowBorder)
              ? (widget.radius ?? 48) - 2
              : widget.radius ?? 48,
          backgroundColor: Colors.grey[200],
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: widget.imagePath!,
              fit: BoxFit.cover,
              width: (widget.radius ?? 48) * 2,
              height: (widget.radius ?? 48) * 2,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
      );
    }

    // ✅ Fallback
    return CircleAvatar(
      radius: widget.radius ?? 48,
      backgroundColor: widget.isShowBorder
          ? widget.borderColor ?? Colors.white
          : Colors.transparent,
      backgroundImage: const AssetImage(AppImages.noImage),
    );
  }

  void _handleImage(BuildContext context) {
    HapticFeedback.lightImpact();
    // if (widget.openFullScreenImage && widget.imagePath != null) {
    //   openImageFullScreen(context, widget.imagePath!);
    // } else if (widget.isPickup) {
    handleImage(context);
    // }
  }

  void handleImage(BuildContext context, {isPickup = false}) async {
    final bool hasImage =
        _xFileNotifier.value != null ||
        (widget.filePath?.isNotEmpty ?? false) ||
        (widget.assetImagePath?.isNotEmpty ?? false) ||
        (widget.imagePath?.isNotEmpty ?? false);

    final CameraBottomSheetResult? result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CameraBottomSheet(canRemove: widget.isRemovePhoto && hasImage),
    );

    if (result == null) return;

    if (result.remove) {
      _xFileNotifier.clearFile();
      widget.onPicTap?.call(null);
      return;
    }

    final ImageSource? image = result.source;
    if (image == null) return;

    XFile? file;
    try {
      file = await locator<ImageService>().pickValidatedSingleImage(
        source: image,
        maxSizeInMB: widget.maxImageSizeInMB,
      );

      if (file != null) {
        if (!isPickup) _xFileNotifier.setFile(file.path);
        widget.onPicTap?.call(file.path);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      context.showErrorToast(
        e is ImageValidationException
            // ignore: use_build_context_synchronously
            ? _mapImageValidationError(context, e)
            : e is FormatException
            ? e.message
            : 'Image selection failed. Please try again.',
      );
    }
  }

  String _mapImageValidationError(
    BuildContext context,
    ImageValidationException exception,
  ) {
    final l10n = context.l10n;
    switch (exception.code) {
      case ImageValidationError.invalidType:
        return l10n.image_invalid_type(exception.extension ?? '');
      case ImageValidationError.fileTooLarge:
        return l10n.image_file_too_large(exception.maxSizeInMB ?? 0);
    }
  }

  /// ---- Old Methdod -----

  // void handleImage(BuildContext context, {isPickup = false}) async {
  //     final ImageSource? image = await showModalBottomSheet(
  //       context: context,
  //       backgroundColor: Colors.transparent,
  //       builder: (context) => const CameraBottomSheet(),
  //     );
  //     XFile? file;
  //     if (image != null) {
  //       file = await locator<ImageService>().pickValidatedSingleImage(
  //         source: image,
  //       );
  //     }
  //     if (file != null) {
  //       if (!isPickup) _xFileNotifier.setFile(file.path);
  //       widget.onPicTap?.call(file.path);
  //     }
  //   }
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _xFileNotifier,
      builder: (context, file, _) {
        Widget child;
        switch (widget.type) {
          case ImagePickerFieldType.profileImage:
            child = _buildProfileImage(file);
            break;
          // case ImagePickerFieldType.coverPhoto:
          //   return _buildCoverImage(file);
        }

        return CustomTap(
          onTap: widget.onTap ?? () => _handleImage(context),
          child: Row(
            mainAxisAlignment: widget.mainAxisAlignment,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  child,
                  if (widget.showCameraBadge)
                    if (widget.badgeCustomIcon != null)
                      widget.badgeCustomIcon!
                    else
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 17.5,
                          backgroundColor: Colors.transparent,
                          child: CircleAvatar(
                            backgroundColor: context.colorScheme.primary,
                            radius: 15,
                            child: Icon(
                              widget.badgeIcon,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
              if (widget.labelText != null) ...[
                const Gap(16),
                Text(
                  widget.labelText!,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: widget.labelColor ?? context.appColors.textPrimary,
                    decoration: TextDecoration.underline,
                    decorationColor:
                        widget.labelColor ?? context.appColors.textPrimary,
                    decorationThickness: 1.2,
                  ),
                ),
              ],
              if (widget.subText != null) ...[
                const Gap(6),
                Text(
                  widget.subText!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.appColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
