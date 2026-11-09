import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:ride_app/core/core.dart';

import '../../core/constants/app_images.dart';
import '../../core/services/app_update_service.dart';
import '../../core/services/device_info_service.dart';
import '../../features/ride_room/presentation/providers/ride_room_provider.dart';
import '../widgets/app_update_dialog.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _animationCompleted = false;
  bool _logicCompleted = false;
  bool _hasNavigated = false;

  String? _routeName;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    locator<DeviceInfoService>().init();
    if (kDebugMode) {
      // locator<StorageService>().clear();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkUpdateAndState());
    });
  }

  /// -----------------------------
  /// AUTH / SOCKET LOGIC
  /// -----------------------------
  ///

  Future<void> _checkUpdateAndState() async {
    // 1. Check for updates
    final updateStatus = await AppUpdateService.checkUpdateStatus();

    if (updateStatus == UpdateStatus.forceUpdate) {
      if (mounted) {
        await AppUpdateDialog.show(context, isForceUpdate: true);
      }
      return; // Stop everything, force the user to update
    }

    if (updateStatus == UpdateStatus.optionalUpdate) {
      if (mounted) {
        // We don't await here because we want to continue to auth check
        unawaited(AppUpdateDialog.show(context, isForceUpdate: false));
      }
    }

    // 2. Continue with original state check
    await _checkUserState();
  }

  Future<void> _checkUserState() async {
    await Future.delayed(const Duration(seconds: 2)); // optional loading buffer
    final storageService = locator<StorageService>();
    final String? token = storageService.getToken;
    final rideRoomNotifier = ref.read(rideRoomProvider.notifier);

    if (token != null && token.isNotEmpty) {
      locator<ApiService>().setAuthToken(token);

      await Future.microtask(() async {
        await rideRoomNotifier.connectRideSocket();
      });

      _routeName = Routes.home.name;
    } else {
      await Future.microtask(() async {
        await rideRoomNotifier.disconnectRideSocket();
      });

      _routeName = Routes.login.name;
    }

    _logicCompleted = true;
    _tryNavigate();
  }

  /// -----------------------------
  /// ANIMATION COMPLETE
  /// -----------------------------
  Future<void> _onAnimationFinish() async {
    await Future.delayed(const Duration(seconds: 1));

    _animationCompleted = true;
    _tryNavigate();
  }

  /// -----------------------------
  /// SAFE NAVIGATION GATE
  /// -----------------------------
  void _tryNavigate() {
    if (!_animationCompleted || !_logicCompleted || _hasNavigated || !mounted) {
      return;
    }

    _hasNavigated = true;
    context.goNamed(_routeName ?? Routes.login.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? Colors.black : Colors.white,
      body: Lottie.asset(
        AppImages.splashLottie,
        controller: _controller,
        width: context.screenWidth,
        height: context.screenHeight,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
          _controller.forward().whenComplete(() {
            _onAnimationFinish();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// import 'dart:async';

// import 'package:ride_app/core/extensions/context_extension.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';

// import '../../core/constants/app_images.dart';
// import '../../core/navigation/routes.dart';
// import '../../core/di/service_locator.dart';
// import '../../core/services/api_service.dart';
// import '../../core/services/device_info_service.dart';
// import '../../core/services/storage_service.dart';
// import '../../features/ride_room/presentation/providers/ride_room_provider.dart';
// import 'package:gif_view/gif_view.dart';

// class SplashScreen extends ConsumerStatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   ConsumerState<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends ConsumerState<SplashScreen> {
//   final Completer<void> _logoAnimationCompleter = Completer<void>();
//   bool _hasNavigated = false;

//   @override
//   void initState() {
//     super.initState();
//     locator<DeviceInfoService>().init();
//     unawaited(GifView.preFetchImage(const AssetImage(AppImages.logoGif)));
//     checkUserState();
//   }

//   Future<void> checkUserState() async {
//     await Future.delayed(const Duration(seconds: 5));

//     if (!mounted) return;

//     final storageService = locator<StorageService>();
//     final String? token = storageService.getToken;
//     final rideRoomNotifier = ref.read(rideRoomProvider.notifier);

//     if (token != null && token.isNotEmpty) {
//       locator<ApiService>().setAuthToken(token);
//       await rideRoomNotifier.connectRideSocket();

//       await _navigateAfterSplash(Routes.home.name);
//     } else {
//       await rideRoomNotifier.disconnectRideSocket();

//       await _navigateAfterSplash(Routes.login.name);
//     }
//   }

//   Future<void> _navigateAfterSplash(String routeName, {Object? extra}) async {
//     await _logoAnimationCompleter.future;
//     if (!mounted || _hasNavigated) {
//       return;
//     }

//     _hasNavigated = true;
//     context.goNamed(routeName, extra: extra);
//   }

//   void _markAnimationComplete() {
//     if (_logoAnimationCompleter.isCompleted) {
//       return;
//     }
//     _logoAnimationCompleter.complete();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: GifView.asset(
//           AppImages.logoGif,
//           // width: 250,
//           height: context.screenHeight,
//           fit: BoxFit.cover,
//           loop: false,
//           onFinish: _markAnimationComplete,
//           errorBuilder: (context, error, tryAgain) {
//             _markAnimationComplete();
//             return Image.asset(
//               AppImages.logo,
//               // width: 250,
//               // height: 250,
//               fit: BoxFit.cover,
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
