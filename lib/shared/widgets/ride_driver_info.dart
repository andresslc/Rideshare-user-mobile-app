import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/shared/widgets/chat_icon_widget.dart';
import 'package:ride_app/shared/widgets/circular_profile.dart';

class DriverInfoSection extends StatelessWidget {
  const DriverInfoSection({
    super.key,
    required this.profileImage,
    required this.userName,
    required this.rating,
    this.driverId = '',

    this.carImage = '',
    this.carMake = '',
    this.carModel = '',
    this.plateNo = '',
    this.showTopBorder = true,
    this.wantChatIcon = false,
    this.onTrailing,
    this.showCarInfo = false,
    this.showRating = true,
    this.enableProfileTap = true,
    this.avatarSize,
    this.nameTextStyle,
  });
  final double? avatarSize;
  final TextStyle? nameTextStyle;
  final String carModel;
  final String profileImage;
  final String userName;
  final String driverId;
  final double rating;
  final String? carImage;
  final String? carMake;
  final String? plateNo;
  final bool showTopBorder;
  final bool showCarInfo;
  final bool wantChatIcon;
  final bool showRating;
  final bool enableProfileTap;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopBorder)
          Container(height: 1, color: context.appColors.border),
        const SizedBox(height: 8),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            Expanded(
              flex: 5,
              child: GestureDetector(
                onTap: (enableProfileTap && driverId.isNotEmpty)
                    ? () {
                        context.pushNamed(
                          Routes.driverProfileScreen.name,
                          extra: driverId,
                        );
                      }
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,

                  //                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProfile(
                      image: profileImage,
                      size: avatarSize ?? context.screenWidth * 0.14,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                nameTextStyle ?? context.textTheme.titleMedium,
                          ),

                          // const SizedBox(height: 2),
                          if (showRating)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toString(),
                                  style: context.textTheme.bodySmall,
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: AppColors.darkField,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showCarInfo)
              Expanded(
                flex: 3,
                child: wantChatIcon
                    ? ChatIconButton(onTap: onTrailing)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Image.asset(
                            carImage ?? "",
                            height: 32,
                            width: 56,
                            fit: BoxFit.contain,
                          ),
                          Text(
                            "$carMake - $plateNo",
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                            textAlign: TextAlign.end,
                          ),

                          /// Second line: Model
                          Text(
                            carModel,
                            style: context.textTheme.bodySmall,
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ],
    );
  }
}
