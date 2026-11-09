import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../../shared/widgets/toast.dart';

enum ImageValidationError { invalidType, fileTooLarge }

class ImageValidationException implements Exception {
  ImageValidationException(
    this.code, {
    this.extension,
    this.maxSizeInMB,
  });

  final ImageValidationError code;
  final String? extension;
  final int? maxSizeInMB;
}

class ImageService {
  final ImagePicker _imagePicker = ImagePicker();

  /// ✅ Validation Helper (extension + size)
  Future<XFile?> _validatePickedImage(
    XFile? picked, {
    int maxSizeInMB = 50,
  }) async {
    if (picked == null) return null;

    try {
      final File imageFile = File(picked.path);
      final String extension = picked.path.split('.').last.toLowerCase();

      // Extension validation
      if (!(extension == 'png' || extension == 'jpg' || extension == 'jpeg')) {
        // errorToast(msg: 'Only JPG and PNG images are allowed.');
        // return null;
        throw ImageValidationException(
          ImageValidationError.invalidType,
          extension: extension,
        );
      }

      // File size validation
      final int fileSize = await imageFile.length();
      final int maxSizeInBytes = maxSizeInMB * 1024 * 1024;

      if (fileSize > maxSizeInBytes) {
        // errorToast(
        //   msg:
        //       'Image size exceeds $maxSizeInMB MB. Please select a smaller file.',
        // );
        // return null;
        throw ImageValidationException(
          ImageValidationError.fileTooLarge,
          maxSizeInMB: maxSizeInMB,
        );
      }

      return picked;
    } catch (e, stack) {
      log("Image validation failed: $e\n$stack");
      // errorToast(msg: 'Image validation failed. Please try again.');
      // return null;
      rethrow;
      // throw FormatException('Image validation failed: $e');
    }
  }

  /// Picks a single validated image
  Future<XFile?> pickValidatedSingleImage({
    required ImageSource source,
    int maxSizeInMB = 50,
  }) async {
    final XFile? picked = await _imagePicker.pickImage(source: source);
    return _validatePickedImage(picked, maxSizeInMB: maxSizeInMB);
  }

  /// Picks multiple images with validation
  Future<void> pickImages({
    required Function(List<XFile> images) outputList,
    required ImageSource imageSource,
    required List<XFile> selectedImages,
    int networkImagesLength = 0,
    int pickLimit = 5,
    int maxSizeInMB = 50,
  }) async {
    final int totalSelected = selectedImages.length + networkImagesLength;

    if (totalSelected >= pickLimit) {
      errorToast(msg: 'You can select a maximum of $pickLimit images.');
      return;
    }

    final int remainingSlots = pickLimit - totalSelected;
    final List<XFile> newImages = [];

    try {
      if (imageSource == ImageSource.camera) {
        final XFile? picked = await _imagePicker.pickImage(
          source: ImageSource.camera,
        );

        final validated = await _validatePickedImage(
          picked,
          maxSizeInMB: maxSizeInMB,
        );

        if (validated != null &&
            !_isImageAlreadySelected(validated, selectedImages)) {
          newImages.add(validated);
        }
      } else {
        // 🔥 CORE FIX: Always respect remainingSlots
        final List<XFile> pickedList = remainingSlots == 1
            ? [
                if (await _imagePicker.pickImage(source: ImageSource.gallery)
                    case final XFile image)
                  image,
              ]
            : await _imagePicker.pickMultiImage(
                limit: remainingSlots,
                requestFullMetadata: true,
              );

        for (final image in pickedList) {
          if (newImages.length >= remainingSlots) break;

          final validated = await _validatePickedImage(
            image,
            maxSizeInMB: maxSizeInMB,
          );

          if (validated != null &&
              !_isImageAlreadySelected(validated, selectedImages)) {
            newImages.add(validated);
          }
        }
      }

      if (newImages.isNotEmpty) {
        outputList(newImages);
      }
    } catch (e, stack) {
      log('Multi Image picking failed: $e\n$stack');
      errorToast(msg: 'Failed to pick images. Please try again.');
    }
  }

  bool _isImageAlreadySelected(XFile file, List<XFile> selectedImages) {
    return selectedImages.any((img) => img.path == file.path);
  }

  /// Picks a single video
  Future<XFile?> pickSingleVideo({required ImageSource source}) async {
    try {
      final XFile? picked = await _imagePicker.pickVideo(source: source);
      if (picked != null) {
        return picked;
      }
    } catch (e, stack) {
      log("Video picking failed: $e\n$stack");
      errorToast(msg: 'Failed to pick video. Please try again.');
    }
    return null;
  }
}

/// Opens a full-screen image viewer with support for both local and network images
///
/// Example usage:
/// ```dart
/// // Single image
/// ImageViewerUtils.openImageViewer(
///   context,
///   imagePaths: ['path/to/image.jpg'],
/// );
///
/// // Multiple images with initial index
/// ImageViewerUtils.openImageViewer(
///   context,
///   imagePaths: [
///     'https://example.com/image1.jpg',
///     '/local/path/image2.jpg',
///     'https://example.com/image3.jpg',
///   ],
///   initialIndex: 1,
/// );
/// ```
class ImageViewerUtils {
  /// Opens a full-screen image viewer with PageView support
  ///
  /// Parameters:
  /// - [context]: BuildContext for navigation
  /// - [imagePaths]: List of image paths (supports both local paths and network URLs)
  /// - [initialIndex]: Starting index (default: 0)
  /// - [enableRotation]: Allow image rotation (default: true)
  /// - [showCounter]: Show image counter in AppBar (default: true)
  /// - [backgroundColor]: Background color (default: Colors.black)
  static void openImageViewer(
    BuildContext context, {
    required List<String> imagePaths,
    int initialIndex = 0,
    bool enableRotation = true,
    bool showCounter = true,
    Color backgroundColor = Colors.black,
  }) {
    if (imagePaths.isEmpty) return;

    // Ensure initialIndex is within bounds
    final validIndex = initialIndex.clamp(0, imagePaths.length - 1);

    final pageController = PageController(initialPage: validIndex);
    final currentPageNotifier = ValueNotifier<int>(validIndex);

    pageController.addListener(() {
      currentPageNotifier.value = pageController.page?.round() ?? validIndex;
    });

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: backgroundColor,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.white),
              toolbarHeight: 80,
              title: showCounter
                  ? ValueListenableBuilder<int>(
                      valueListenable: currentPageNotifier,
                      builder: (context, currentPage, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${currentPage + 1}/${imagePaths.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    )
                  : null,
              centerTitle: true,
            ),
            body: PageView.builder(
              controller: pageController,
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                final path = imagePaths[index];
                return _buildPhotoView(path, enableRotation: enableRotation);
              },
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          final tween = Tween(begin: begin, end: end);
          final scaleAnimation = animation.drive(tween);
          return ScaleTransition(scale: scaleAnimation, child: child);
        },
      ),
    ).then((_) {
      // Clean up
      pageController.dispose();
      currentPageNotifier.dispose();
    });
  }

  /// Builds a PhotoView widget for the given image path
  static Widget _buildPhotoView(
    String imagePath, {
    bool enableRotation = true,
  }) {
    // Check if it's a network URL or local file
    final isNetworkImage =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    return PhotoView(
      imageProvider: isNetworkImage
          ? CachedNetworkImageProvider(imagePath) as ImageProvider
          : FileImage(File(imagePath)),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2,
      basePosition: Alignment.center,
      enableRotation: enableRotation,
      loadingBuilder: (context, event) {
        return Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens image viewer for a single image
  static void openSingleImage(
    BuildContext context,
    String imagePath, {
    bool enableRotation = true,
    bool showCounter = false,
  }) {
    openImageViewer(
      context,
      imagePaths: [imagePath],
      initialIndex: 0,
      enableRotation: enableRotation,
      showCounter: showCounter,
    );
  }
}
