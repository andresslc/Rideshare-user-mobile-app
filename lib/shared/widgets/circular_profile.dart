// // ignore_for_file: unnecessary_underscores

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import '../../core/theme/app_colors.dart';

// class CircularProfile extends StatelessWidget {
//   const CircularProfile({super.key, required this.image, required this.size});

//   final String? image;
//   final double size;

//   @override
//   Widget build(BuildContext context) {
//     return _buildCircularImage(image, context);
//   }

//   Widget _buildCircularImage(String? url, BuildContext context) {
//     // if (url == null) {
//     //   return Container(
//     //     height: size,
//     //     width: size,
//     //     color: colorScheme.brand,
//     //     child: Icon(Icons.person, size: size, color: colorScheme.textPrimary),
//     //   );
//     // }
//     if (url?.startsWith('assets/') == true) {
//       return Container(
//         width: size,
//         height: size,
//         decoration: const BoxDecoration(shape: BoxShape.circle),
//         clipBehavior: Clip.antiAlias,
//         child: Image.asset(url!, fit: BoxFit.cover),
//       );
//     }

//     // ✅ Otherwise network image
//     return Container(
//       width: size,
//       height: size,
//       decoration: const BoxDecoration(
//         shape: BoxShape.circle,
//         color: AppColors.brandLight,
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: CachedNetworkImage(
//         imageUrl: url ?? '',
//         fit: BoxFit.cover,
//         progressIndicatorBuilder: (_, __, ___) => Center(
//           child: LoadingAnimationWidget.threeArchedCircle(
//             size: size * 0.3,
//             color: AppColors.brand,
//           ),
//         ),
//         errorWidget: (_, __, ___) => Center(
//           child: Icon(Icons.person, size: size * 0.4, color: AppColors.brand),
//         ),
//       ),
//     );
//   }
// }
// // import 'package:cached_network_image/cached_network_image.dart';
// // import 'package:flutter/material.dart';
// // import 'package:loading_animation_widget/loading_animation_widget.dart';
// // import '../../core/theme/app_colors.dart';

// // class CircularProfile extends StatelessWidget {
// //   const CircularProfile({
// //     super.key,
// //     required this.image,
// //     required this.size,
// //     this.subImage,
// //     this.subSize = 20,
// //     this.borderColor = Colors.white,
// //     this.borderWidth = 0,
// //     this.name = '',
// //     this.showInitials = false, // main image initials/emoji
// //     this.showSubInitials = false, // sub image initials/emoji
// //   });

// //   final String image;
// //   final double size;
// //   final String? subImage;
// //   final double subSize;
// //   final Color borderColor;
// //   final double borderWidth;
// //   final String name;
// //   final bool showInitials;
// //   final bool showSubInitials;

// //   static const List<String> _emojiList = [
// //     '😎', '🚤', '🐬', '🌊', '☀️', '🏝️', '🛥️', '🦀', '🐚', '🍹',
// //     '🐠', '🧜‍♂️', '🐳', '⚓', '🌅', '🐢', '🪸', '🛶', '🎣', '🌴',
// //     '🐋', '🦞', '🐙', '🌊', '🚢', '🌺', '🌞', '🐡', '💦', '🩴',
// //   ];

// //   @override
// //   Widget build(BuildContext context) {
// //     return SizedBox(
// //       width: size,
// //       child: Stack(
// //         clipBehavior: Clip.none,
// //         children: [
// //           _buildCircularImage(image, size, name, showInitials),
// //           if (subImage != null)
// //             Positioned(
// //               bottom: 0,
// //               right: 0,
// //               child: _buildCircularImage(
// //                 subImage!,
// //                 subSize,
// //                 name,
// //                 showSubInitials,
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildCircularImage(
// //     String url,
// //     double size,
// //     String name,
// //     bool showInitialsFlag,
// //   ) {
// //     // ✅ Emoji or initials (only when no image)
// //     if (showInitialsFlag && url.isEmpty) {
// //       final emoji = _generateEmojiFromName(name); // 👈 auto emoji
// //       return Container(
// //         width: size,
// //         height: size,
// //         decoration: BoxDecoration(
// //           shape: BoxShape.circle,
// //           border: Border.all(color: borderColor, width: borderWidth),
// //           color: generateColorFromName(name),
// //         ),
// //         alignment: Alignment.center,
// //         child: Text(
// //           emoji,
// //           style: TextStyle(
// //             fontSize: size * 0.45,
// //           ),
// //         ),
// //       );
// //     }

// //     // ✅ Local asset
// //     if (url.startsWith('assets/')) {
// //       return Container(
// //         width: diameter,
// //         height: diameter,
// //         decoration: BoxDecoration(
// //           shape: BoxShape.circle,
// //           border: Border.all(color: borderColor, width: borderWidth),
// //         ),
// //         clipBehavior: Clip.antiAlias,
// //         child: Image.asset(url, fit: BoxFit.cover),
// //       );
// //     }

// //     // ✅ Network image
// //     return Container(
// //       width: diameter,
// //       height: diameter,
// //       decoration: BoxDecoration(
// //         shape: BoxShape.circle,
// //         border: Border.all(color: borderColor, width: borderWidth),
// //         color: AppColors.disabledGrey,
// //       ),
// //       clipBehavior: Clip.antiAlias,
// //       child: CachedNetworkImage(
// //         imageUrl: url,
// //         fit: BoxFit.cover,
// //         progressIndicatorBuilder: (_, __, ___) => Center(
// //           child: LoadingAnimationWidget.threeArchedCircle(
// //             size: diameter * 0.3,
// //             color: AppColors.flameOrange,
// //           ),
// //         ),
// //         errorWidget: (_, __, ___) => Center(
// //           child: Icon(
// //             Icons.person,
// //             size: diameter * 0.4,
// //             color: AppColors.spanishGray,
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   /// 👇 Generate a deterministic emoji based on user name
// //   String _generateEmojiFromName(String name) {
// //     if (name.isEmpty) {
// //       // Random fallback if no name
// //       return _emojiList[Random().nextInt(_emojiList.length)];
// //     }
// //     final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
// //     return _emojiList[hash % _emojiList.length];
// //   }
// // }

// // Color generateColorFromName(String name) {
// //   final colors = [
// //     Colors.red,
// //     Colors.blue,
// //     Colors.green,
// //     Colors.orange,
// //     Colors.purple,
// //     Colors.teal,
// //     Colors.indigo,
// //     Colors.brown,
// //   ];

// //   if (name.isEmpty) return Colors.grey;

// //   int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
// //   return colors[hash % colors.length];
// // }

// ignore_for_file: unnecessary_underscores

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../core/theme/app_colors.dart';

class CircularProfile extends StatelessWidget {
  const CircularProfile({super.key, required this.image, required this.size});

  final String? image;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _buildCircularImage(image, context);
  }

  Widget _buildCircularImage(String? url, BuildContext context) {
    bool isValidUrl(String? value) {
      if (value == null) return false;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return false;
      return trimmed.startsWith('http');
    }

    if (!isValidUrl(url) && !(url?.startsWith('assets/') ?? false)) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandLight,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.person, size: size * 0.4, color: AppColors.brand),
      );
    }

    // CASE 2: ASSET IMAGE
    if (url!.startsWith('assets/')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(url, fit: BoxFit.cover),
      );
    }

    // CASE 3: VALID NETWORK IMAGE
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.brandLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (_, __, ___) => Center(
          child: LoadingAnimationWidget.threeArchedCircle(
            size: size * 0.3,
            color: AppColors.brand,
          ),
        ),
        errorWidget: (_, __, ___) => Center(
          child: Icon(Icons.person, size: size * 0.4, color: AppColors.brand),
        ),
      ),
    );
  }
}
