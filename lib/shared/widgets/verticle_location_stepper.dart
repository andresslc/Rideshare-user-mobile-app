import 'package:flutter/material.dart';
import 'package:ride_app/core/extensions/context_extension.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/core/theme/app_colors.dart';
import 'package:ride_app/shared/widgets/toggle_shape.dart';

class VerticleLocationStepper extends StatelessWidget {
  const VerticleLocationStepper({
    super.key,
    required this.locationList,
    this.isEditable = true,
    this.isStopOverAdd = false,
    this.startTime,
    this.backgroundColor,
    this.endTime,
    this.showTopBorder = true,
  });

  final List<String> locationList;
  final bool isEditable;
  final bool isStopOverAdd;
  final String? startTime;
  final String? endTime;
  final Color? backgroundColor;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final int toggleCount = locationList.length; // first 2 toggles only

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTopBorder) ...[
          if (locationList.isNotEmpty) // only show for non-empty list
            Container(
              // padding: const EdgeInsets.all(10),
              // padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.appColors.border, width: 1),
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],

        Text(
          context.l10n.location,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          // crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Vertical Line + Dots
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: (61.0 * toggleCount) - 38.0,
                  width: 20.0,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: DottedLineShape(
                          lineheight: (61.0 * toggleCount) - 61.0,
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: List.generate(toggleCount, (index) {
                            final isLast = index == toggleCount - 1;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: !isLast ? 40.0 : 0,
                              ),
                              child: ToggleShape(isReverse: isLast),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12.0),

            // Location List
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title above Pickup
                  ...locationList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final location = entry.value;

                    final isFirst = index == 0;
                    final isLast = index == locationList.length - 1;

                    String title;
                    if (isFirst) {
                      title = context.l10n.pickup_location;
                    } else if (isLast) {
                      title = context.l10n.dropoff_location;
                    } else {
                      title = "${context.l10n.stop} $index";
                    }

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom:
                              index !=
                                  locationList.length -
                                      1 // last stop ke liye border na dikhao
                              ? BorderSide(
                                  color: context.appColors.border,
                                  width: 1.0,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          minTileHeight: 0,
                          tileColor: backgroundColor ?? Colors.transparent,
                          // contentPadding: const EdgeInsets.only(
                          //   bottom: 12.0,
                          //   top: 12.0,
                          // ),
                          dense: true,
                          title: Text(
                            title,
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                          subtitle: Text(
                            location,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall,
                          ),
                          onTap: () {},
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DottedLineShape extends StatelessWidget {
  const DottedLineShape({super.key, required this.lineheight});
  final double lineheight;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(0.1, lineheight), // Width and height of the line
      painter: DottedLinePainter(),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors
          .brand // Line color
      ..strokeWidth = 2; // Line width
    double dashWidth = 4; // Width of each dash
    double dashSpace = 5; // Space between dashes
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
