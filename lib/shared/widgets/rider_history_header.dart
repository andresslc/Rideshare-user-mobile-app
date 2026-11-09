import 'package:flutter/material.dart';
import 'package:ride_app/core/core.dart';

class RideTopInfo extends StatelessWidget {
  final String rideType;
  final String status;
  final String? statusKey;

  /// jab true ho, sirf 1 title show hoga
  final bool singleTitleMode;

  /// single title ka text (optional)
  final String? singleTitle;

  const RideTopInfo({
    super.key,
    required this.rideType,
    required this.status,
    this.statusKey,
    this.singleTitleMode = false, // default: jaisa hai waisa hi
    this.singleTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (singleTitleMode) {
      return Text(
        singleTitle ?? rideType,
        style: context.textTheme.headlineMedium?.copyWith(),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(rideType, style: context.textTheme.bodyMedium),
        Text(
          status,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: (statusKey ?? status).toLowerCase() == 'completed'
                ? Colors.green
                : Colors.red,
          ),
        ),
      ],
    );
  }
}


// jb aap ko sirf title chaye ho to no status no ridetype 
//   const RideTopInfo(
          //   rideType: 'Economy Ride',
          //   status: 'Completed',
          //   singleTitleMode: true,
          //   singleTitle:
          //       'You have reached the pickup point!', // ya jo bhi text chaho
          // ),
