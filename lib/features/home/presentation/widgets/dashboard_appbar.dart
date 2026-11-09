import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';

import '../../../../shared/widgets/glow_button.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final bool showDrawerButton;
  final bool showNotificationIcon;
  final bool showTitle;
  final Widget? customAction;
  final ZoomDrawerController? zoomController;
  const DashboardAppBar({
    super.key,
    required this.title,
    this.onNotificationTap,
    this.showDrawerButton = true,
    this.showNotificationIcon = true,
    this.showTitle = true,
    this.customAction,
    this.zoomController,
  });

  bool get _hasContent =>
      showTitle ||
      showDrawerButton ||
      showNotificationIcon ||
      customAction != null;

  @override
  Size get preferredSize =>
      Size.fromHeight(_hasContent ? kToolbarHeight : 0);

  @override
  Widget build(BuildContext context) {
    // Empty app bar still occupies the toolbar hit target and steals taps from
    // an expanded bottom sheet (e.g. finding-ride refresh). Skip it entirely.
    if (!_hasContent) {
      return const SizedBox.shrink();
    }

    return AppBar(
      automaticallyImplyLeading: false,
      title: showTitle ? Text(title) : null,

      /// Leading Image
      // leading: showDrawerButton
      //     ? Builder(
      //         builder: (context) => IconButton(
      //           onPressed: () {
      //             Scaffold.of(context).openDrawer();
      //           },
      //           icon: Image.asset(
      //             AppIcons.drawer,
      //             width: context.screenWidth * 0.11,
      //             height: context.screenWidth * 0.11,
      //           ),
      //         ),
      //       )
      //     : null,
      leadingWidth: showDrawerButton
          ? 100
          : 0, // Adjust leading width when button is hidden
      leading: showDrawerButton
          ? Row(
              children: [
                const SizedBox.square(dimension: 10),
                Center(
                  child: SizedBox(
                    height: 46,
                    width: 46,
                    child: GlowButton(
                      onTap: () {
                        zoomController?.toggle?.call();
                      },
                      // size: 40,
                      child: Icon(
                        Icons.menu_rounded,
                        color: (context.isDark)
                            ? context.appColors.brand
                            : Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null,

      /// Action Images
      actions: [
        ?customAction,
        if (showNotificationIcon)
          SizedBox(
            height: 46,
            width: 46,
            child: GlowButton(
              onTap: onNotificationTap,
              child: Image.asset(
                AppIcons.notification,
                scale: 2,
                color: (!context.isDark) ? Colors.white : null,
              ),
            ),
          ),
        if (showNotificationIcon) const SizedBox.square(dimension: 10),
        // if (showNotificationIcon)
        // if (context.isDark)
        //   IconButton(
        //     onPressed: onNotificationTap,
        //     padding: EdgeInsets.zero,
        //     icon: Image.asset(
        //       AppIcons.notificationIcon,
        //       width: context.screenWidth * 0.19,
        //       height: context.screenWidth * 0.19,
        //       fit: BoxFit.cover,
        //     ),
        //   )
        // else
        //   IconButton(
        //     onPressed: onNotificationTap,
        //     padding: EdgeInsets.zero,
        //     icon: Image.asset(
        //       AppIcons.lightmodenoti,
        //       width: context.screenWidth * 0.11,
        //       height: context.screenWidth * 0.11,
        //     ),
        //   ),
      ],
    );
  }
}
