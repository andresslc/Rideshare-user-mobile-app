import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
// import 'dart:io';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:image_picker/image_picker.dart';

// import '../../shared/widgets/toast.dart';

// Future<XFile> compressImage(XFile imageFile) async {
//   final List<int>? compressedImageData =
//       await FlutterImageCompress.compressWithFile(imageFile.path, quality: 80);

//   final File compressedImageFile = File('${imageFile.path}_compressed.jpg');
//   await compressedImageFile.writeAsBytes(compressedImageData!);
//   return XFile(compressedImageFile.path);
// }

// Future<void> pickMultipleImages({
//   required Function(List<XFile> images) outputList,
//   required ImageSource imageSource,
//   int networkImagesLength = 0,
//   required List<XFile> selectedImages,
//   int picklimit = 5,
// }) async {
//   final ImagePicker imagePicker = ImagePicker();

//   // Calculate the total number of images (network + selected)
//   final int totalImages = selectedImages.length + networkImagesLength;

//   if (totalImages >= picklimit) {
//     errorToast(msg: "Cannot select more than $picklimit images");
//     return;
//   }

//   final int remainingSlots = picklimit - totalImages;
//   final List<XFile> newImages = [];

//   if (imageSource == ImageSource.camera) {
//     final XFile? pickedImage = await imagePicker.pickImage(
//       source: ImageSource.camera,
//     );
//     if (pickedImage == null ||
//         isImageAlreadySelected(pickedImage, selectedImages)) {
//       return;
//     }

//     // final resizedImage = await compressImage(pickedImage);
//     // newImages.add(resizedImage);
//     newImages.add(pickedImage);
//   } else if (remainingSlots == 1) {
//     final XFile? pickedImage = await imagePicker.pickImage(source: imageSource);
//     if (pickedImage == null ||
//         isImageAlreadySelected(pickedImage, selectedImages)) {
//       return;
//     }

//     final resizedImage = await compressImage(pickedImage);
//     newImages.add(resizedImage);
//   } else {
//     // Pick multiple images (up to remaining slots)
//     final List<XFile> imageList = await imagePicker.pickMultiImage(
//       limit: remainingSlots,
//     );
//     for (var image in imageList) {
//       if (newImages.length >= remainingSlots) {
//         break; // Ensure we don't exceed the limit
//       }
//       if (!isImageAlreadySelected(image, selectedImages)) {
//         final resizedImage = await compressImage(image);
//         newImages.add(resizedImage);
//       }
//     }
//   }

//   // Create a mutable copy of selectedImages and add new images
//   final List<XFile> updatedImages = List<XFile>.from(selectedImages)
//     ..addAll(newImages);

//   // Enforce picklimit if needed
//   if (updatedImages.length > picklimit) {
//     updatedImages.removeRange(0, updatedImages.length - picklimit);
//   }

//   outputList(updatedImages);
// }

// bool isImageAlreadySelected(XFile image, List<XFile> selectedImages) {
//   return selectedImages.any(
//     (selectedImage) => selectedImage.name == image.name,
//   );
// }
void openImageFullScreen(BuildContext context, String url) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            enableRotation: true,
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
  );
}

/// Opens a full-screen image viewer for a single local file path
void openLocalImageFullScreen(BuildContext context, String path) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(),
          body: PhotoView(
            imageProvider: FileImage(File(path)),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            enableRotation: true,
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
  );
}

void openImageListScreen(
  BuildContext context,
  List<String>? imageUrls,
  int initialIndex,
) {
  final pageController = PageController(initialPage: initialIndex);
  final currentPageNotifier = ValueNotifier<int>(initialIndex);
  pageController.addListener(() {
    currentPageNotifier.value = pageController.page?.round() ?? initialIndex;
  });

  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            toolbarHeight: 80,
            title: ValueListenableBuilder<int>(
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
                    '${currentPage + 1}/${imageUrls?.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
            centerTitle: true,
          ),
          body: PageView.builder(
            controller: pageController,
            itemCount: imageUrls?.length,
            itemBuilder: (context, index) {
              return PhotoView(
                imageProvider: CachedNetworkImageProvider(imageUrls![index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered,
                basePosition: Alignment.center,
                enableRotation: true,
              );
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
  );
}

/// Opens a full-screen image viewer for local file paths
void openLocalImageListScreen(
  BuildContext context,
  List<String>? imagePaths,
  int initialIndex,
) {
  final pageController = PageController(initialPage: initialIndex);
  final currentPageNotifier = ValueNotifier<int>(initialIndex);
  pageController.addListener(() {
    currentPageNotifier.value = pageController.page?.round() ?? initialIndex;
  });

  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            toolbarHeight: 80,
            title: ValueListenableBuilder<int>(
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
                    '${currentPage + 1}/${imagePaths?.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
            centerTitle: true,
          ),
          body: PageView.builder(
            controller: pageController,
            itemCount: imagePaths?.length,
            itemBuilder: (context, index) {
              return PhotoView(
                imageProvider: FileImage(File(imagePaths![index])),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered,
                basePosition: Alignment.center,
                enableRotation: true,
              );
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
  );
}
