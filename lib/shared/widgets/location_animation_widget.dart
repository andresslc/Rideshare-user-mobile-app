import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LocationLoadingAnimation extends StatelessWidget {
  const LocationLoadingAnimation({
    super.key,
    this.width = 140,
    this.height = 140,
    this.repeat = true,
  });

  final double width;
  final double height;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/location_new.json',
      width: width,
      height: height,
      repeat: repeat,
    );
  }
}