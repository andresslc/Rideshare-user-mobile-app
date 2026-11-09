import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';

class SavedLocationCard extends StatelessWidget {
  final String locationName;
  final String address;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SavedLocationCard({
    super.key,
    required this.locationName,
    required this.address,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppGradientBox(
      padding: const EdgeInsets.all(AppSizes.p16),
      cornerRadius: 16,
      borderWidth: 1.5,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  maxLines: 1,
                  locationName,
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              // Edit Button
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    AppIcons.edit,
                    width: 20,
                    height: 20,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(width: AppSizes.p4),

              // Delete Button
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    AppIcons.trash,
                    width: 20,
                    height: 20,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Location Icon
              Image.asset(
                AppIcons.location,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                color: colors.textPrimary,
              ),
              const SizedBox(width: AppSizes.p12),
              // // Location Name and Address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   locationName,
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w600,
                    //     color: colors.textPrimary,
                    //   ),
                    // ),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
