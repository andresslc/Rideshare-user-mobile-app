import 'package:flutter/material.dart';
import 'package:ride_app/core/theme/app_colors.dart';

class ToggleShape extends StatelessWidget {
  const ToggleShape({super.key, this.isReverse = false});
  final bool isReverse;
  // bool isToggled = false;
  // void toggle() {
  //   setState(() {
  //     isToggled = !isToggled;
  //   });
  // }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 21,
      padding: EdgeInsets.symmetric(
        vertical: isReverse ? 1 : 2,
        horizontal: isReverse ? 1 : 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7.5),
        color: isReverse ? Colors.transparent : AppColors.brand,
        border: isReverse
            ? Border.all(
                color: AppColors.brand, // Border color
                width: 1, // Border width
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isReverse
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircleAvatar(
              backgroundColor: isReverse
                  ? AppColors.brand
                  : AppColors.lightBackground,
            ),
          ),
        ],
      ),
    );
  }
}
