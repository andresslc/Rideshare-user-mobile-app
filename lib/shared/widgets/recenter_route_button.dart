import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';

class RecenterRouteButton extends ConsumerWidget {
  final bool isCarpool;
  final VoidCallback? onPressed;

  const RecenterRouteButton({
    super.key,
    this.isCarpool = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isCentered = isCarpool
        ? ref.watch(
            carpoolMapProvider.select(
              (s) => s.value?.isRouteCentered ?? true,
            ),
          )
        : ref.watch(
            mapProvider.select((s) => s.value?.isRouteCentered ?? true),
          );

    final colors = context.appColors;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isCentered
          ? const SizedBox.shrink(key: ValueKey('recenter_hidden'))
          : Container(
              key: const ValueKey('recenter_visible'),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.background,
                boxShadow: [
                  BoxShadow(
                    color: colors.brand.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: IconButton(
                icon: const Icon(Icons.route, size: 22),
                onPressed: () {
                  if (onPressed != null) {
                    onPressed!();
                  }
                  if (isCarpool) {
                    ref.read(carpoolMapProvider.notifier).recenterRoute();
                  } else {
                    ref.read(mapProvider.notifier).recenterRoute();
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: colors.background,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(10),
                ),
                tooltip: 'Recenter route',
              ),
            ),
    );
  }
}
