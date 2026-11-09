import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';

// class DrawerTile extends StatelessWidget {
//   final String title;
//   final VoidCallback onTap;
//   final bool isDestructive;

//   const DrawerTile({
//     super.key,
//     required this.title,

//     required this.onTap,
//     this.isDestructive = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = context.textTheme;
//     final colorScheme = context.appColors;

//     final color = isDestructive ? Colors.red : colorScheme.textPrimary;

//     return ListTile(
//       dense: true,
//       contentPadding: const EdgeInsets.symmetric(
//         horizontal: AppSizes.p32,
//         vertical: 0,
//         // vertical: AppSizes.p4,
//       ),
//       title: Text(title, style: textTheme.titleSmall?.copyWith(color: color)),
//       onTap: onTap,
//     );
//   }
// }

class DrawerTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const DrawerTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.appColors;

    final color = isDestructive ? Colors.red : colorScheme.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p32,
          vertical: 14,
        ),
        child: Row(
          children: [
            /// Icon
            Icon(icon, color: color, size: 20),

            const SizedBox(width: 16),

            /// Title
            Expanded(
              child: Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
