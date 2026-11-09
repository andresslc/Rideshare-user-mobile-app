// import 'package:ride_app/core/constants/app_sizes.dart';
// import 'package:ride_app/core/extensions/context_extension.dart';
// import 'package:ride_app/core/extensions/theme_extension.dart';
// import 'package:ride_app/core/theme/app_colors.dart';
// import 'package:flutter/material.dart';

// class SlowConnectionBanner extends StatelessWidget {
//   const SlowConnectionBanner({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = context.isDark;
//     final Color backgroundColor = isDark
//         ? AppColors.lightButton
//         : AppColors.brand;
//     final Color borderColor = isDark
//         ? const Color(0xFF334039)
//         : const Color(0xFFD2DCD4);

//     return SafeArea(
//       bottom: false,
//       child: Material(
//         elevation: 2,
//         color: Colors.transparent,
//         child: Container(
//           decoration: BoxDecoration(
//             color: backgroundColor,
//             border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
//           ),
//           // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           child: Row(
//             children: [
//               Container(
//                 width: 26,
//                 height: 26,
//                 decoration: BoxDecoration(
//                   color: context.appColors.brand.withValues(alpha: 0.12),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.network_check_rounded,
//                   size: 16,
//                   color: context.appColors.brand,
//                 ),
//               ),

//               const SizedBox(width: 10),

//               Center(
//                 child: Text(
//                   'Unstable network',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: context.textTheme.bodyMedium?.copyWith(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: context.appColors.textPrimary,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/core/theme/app_colors.dart';

class SlowConnectionBanner extends StatefulWidget {
  const SlowConnectionBanner({super.key});

  @override
  State<SlowConnectionBanner> createState() => _SlowConnectionBannerState();
}

class _SlowConnectionBannerState extends State<SlowConnectionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Slow, deliberate pulse — mirrors the "still trying" nature of a
    // flaky connection rather than a generic loading spinner.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDark;
    //   final colors = context.appColors;
    final Color iconColor = isDark ? AppColors.brand : AppColors.lightButton;
    final Color backgroundColor = isDark
        ? AppColors.lightButton
        : AppColors.brand;
    final Color borderColor = isDark
        ? const Color(0xFF334039)
        : const Color(0xFFD2DCD4);
    final Color accent = iconColor;

    return SafeArea(
      bottom: false,
      child: Material(
        elevation: 0,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final double t = _pulseController.value;
                  return Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 22 + (t * 6),
                          height: 22 + (t * 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.14 * (1 - t)),
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            Icons.wifi_rounded,
                            size: 20,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Text(
                    //   'Unstable network',
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: context.textTheme.bodyMedium?.copyWith(
                    //     fontSize: 13,
                    //     fontWeight: FontWeight.w600,
                    //     height: 1.1,
                    //     color: colors.textPrimary,
                    //   ),
                    // ),
                    const SizedBox(height: 1),
                    Expanded(
                      child: Text(
                        context.l10n.slow_connection_banner,
                        style: context.textTheme.bodyMedium?.copyWith(
                          // color: Colors.white,
                          color: context.appColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
