import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/extensions/dialgue_extension.dart';
import 'package:ride_app/core/services/app_update_service.dart';
import 'package:ride_app/core/utils/app_status_dialogue.dart';
import 'package:ride_app/features/ride_room/presentation/providers/camera_providers.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/carpool_state.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';
import 'package:ride_app/features/ride_room/presentation/widgets/carpool_google_map_widget.dart';
import 'package:ride_app/features/ride_room/presentation/widgets/fixed_center_pin.dart';
import 'package:ride_app/features/ride_room/presentation/widgets/ride_google_map_widget.dart';
import 'package:ride_app/features/ride_room/screens/carpool/carpool_accepted_ride_sheet.dart';
import 'package:ride_app/features/ride_room/screens/driver_arrived_sheet.dart';
import 'package:ride_app/features/ride_room/screens/finding_ride_sheet.dart';
import 'package:ride_app/features/ride_room/screens/on_going_ride_sheet.dart';
import 'package:ride_app/shared/widgets/app_update_dialog.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';

import '../../home/presentation/screens/drawer.dart';
import '../../home/presentation/widgets/dashboard_appbar.dart';
import '../enums/ride_enum.dart';
import '../presentation/providers/map_provider.dart';
import '../presentation/states/map_state.dart';
import '../presentation/widgets/share_button.dart';
import 'select_ride_sheet.dart' hide RideType;
import 'where_to_go_sheet.dart';

class HomeRideRoomScreen extends ConsumerStatefulWidget {
  const HomeRideRoomScreen({super.key});

  @override
  ConsumerState<HomeRideRoomScreen> createState() => _RideRoomScreenState();
}

class _RideRoomScreenState extends ConsumerState<HomeRideRoomScreen> {
  final ZoomDrawerController zoomController = ZoomDrawerController();

  GoogleMapController? _mapController;
  GoogleMapController? _carpoolMapController;
  double _currentZoom = 15.0;
  final double _maxZoom = 18.0;
  Timer? _demoTimer;
  Timer? _carpoolFindingTimer;
  // final bool _isShareLoading = false;
  bool _isMapGestureInProgress = false;
  bool _isProgrammaticMapCameraMove = false;
  String? _lastShownRideErrorMessage;

  String? _lastShownMapErrorMessage;

  RideSheetsType get currentSheet => ref.watch(rideRoomProvider).currentSheet;

  // static const LatLng _demoPickup = LatLng(28.5384, -81.3789); // Orlando
  // static const LatLng _demoDropOff = LatLng(28.4179, -81.4677); // Kissimmee

  // Future<void> _runPolylineDemo() async {
  //   _demoTimer?.cancel();

  //   final mapNotifier = ref.read(mapProvider.notifier);
  //   await mapNotifier.setPickupLocation(_demoPickup, name: 'Packages Mall');
  //   await mapNotifier.setDropOffLocation(_demoDropOff, name: 'Blue Area');

  //   final latest = ref.read(mapProvider).value;
  //   if (latest == null || latest.polylines.isEmpty) return;

  //   final Polyline route = latest.polylines.first;
  //   final points = route.points;
  //   if (points.length < 2) return;

  //   int index = 0;
  //   final step = math.max(1, points.length ~/ 80);

  //   await mapNotifier.setDriverLocation(points.first, name: 'Demo Driver');
  //   if (_mapController.isCompleted) {
  //     final controller = await _mapController.future;
  //     await controller.animateCamera(
  //       CameraUpdate.newLatLngZoom(points.first, 14),
  //     );
  //   }

  //   _demoTimer = Timer.periodic(const Duration(milliseconds: 1500), (
  //     timer,
  //   ) async {
  //     if (!mounted) {
  //       timer.cancel();
  //       return;
  //     }

  //     index += step;
  //     if (index >= points.length) {
  //       timer.cancel();
  //       return;
  //     }

  //     final driverPoint = points[index];
  //     await mapNotifier.setDriverLocation(driverPoint, name: 'Demo Driver');
  //     if (_mapController.isCompleted) {
  //       final controller = await _mapController.future;
  //       await controller.animateCamera(CameraUpdate.newLatLng(driverPoint));
  //     }
  //   });
  // }

  // void _resetDemo() {
  //   _demoTimer?.cancel();
  //   ref.read(mapProvider.notifier).clearRideMapData();
  // }

  @override
  void initState() {
    super.initState();
    // Eagerly create the provider so its socket listeners are attached
    // before any resume event arrives after app launch.
    ref.read(carpoolProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await locator<NotificationServices>().processPendingNotification();
      // Check for optional update
      final updateStatus = await AppUpdateService.checkUpdateStatus();
      if (updateStatus == UpdateStatus.optionalUpdate && mounted) {
        unawaited(AppUpdateDialog.show(context, isForceUpdate: false));
      }
    });
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _carpoolFindingTimer?.cancel();
    _mapController?.dispose();
    _carpoolMapController?.dispose();
    super.dispose();
  }

  LatLng? _latLngFromDriverCoordinates(List<double> coordinates) {
    if (coordinates.length < 2) return null;
    return LatLng(coordinates[1], coordinates[0]);
  }

  Future<void> _syncCarpoolRouteOnMap(CarpoolState state) async {
    final ride = state.requestedRide;
    if (ride == null || (!state.isAccepted && !state.isInProgress)) {
      return;
    }

    await ref
        .read(carpoolMapProvider.notifier)
        .syncRideRoute(
          ride: ride,
          driverLatLng: _latLngFromDriverCoordinates(
            state.latestDriverLocation?.coordinates ?? const <double>[],
          ),
          driverName: ride.driver?.fullName,
        );
  }

  Future<void> _syncCarpoolDriverOnMap(CarpoolState state) async {
    if (!state.isAccepted && !state.isInProgress) return;
    final LatLng? driverLatLng = _latLngFromDriverCoordinates(
      state.latestDriverLocation?.coordinates ?? const <double>[],
    );
    if (driverLatLng == null) return;
    await ref
        .read(carpoolMapProvider.notifier)
        .setDriverLocation(
          driverLatLng,
          name: state.requestedRide?.driver?.fullName,
        );
  }

  Future<void> _resetCarpoolMap() async {
    final notifier = ref.read(carpoolMapProvider.notifier);
    notifier.clearRideMapData();
    await notifier.refreshCurrentLocation(moveCamera: true);
  }

  void _redirectToRequestedCarpoolIfNeeded(CarpoolState state) {
    if (!state.hasRequestedRide) return;

    final BuildContext? targetContext = rootNavigatorKey.currentContext;
    if (targetContext == null) return;
    final String currentPath =
        AppRouter.router.routeInformationProvider.value.uri.path;
    if (currentPath == Routes.requestedCarpool.path) return;

    targetContext.pushNamed(Routes.requestedCarpool.name);
  }

  void _handleMapCameraMoveStarted() {
    if (_isProgrammaticMapCameraMove || _isMapGestureInProgress || !mounted) {
      return;
    }

    setState(() {
      _isMapGestureInProgress = true;
    });
  }

  // Future<void> _handleMapCameraIdle(FutureOr<void> Function() onIdle) async {
  //   await onIdle();
  //   if (!_isMapGestureInProgress || !mounted) return;

  //   setState(() {
  //     _isMapGestureInProgress = false;
  //   });
  // }

  Future<void> _handleMapCameraIdle(FutureOr<void> Function() onIdle) async {
    await onIdle();

    if (_currentZoom > _maxZoom) {
      _currentZoom = _maxZoom;

      final controller = ref.read(carpoolProvider).hasRequestedRide
          ? _carpoolMapController
          : _mapController;

      await controller?.animateCamera(CameraUpdate.zoomTo(_maxZoom));
    }

    if (!_isMapGestureInProgress || !mounted) return;

    setState(() {
      _isMapGestureInProgress = false;
    });
  }

  Future<void> _animateMainMapCamera(CameraUpdate cameraUpdate) async {
    final GoogleMapController? controller = _mapController;
    if (controller == null) return;

    _isProgrammaticMapCameraMove = true;
    try {
      await controller.animateCamera(cameraUpdate);
    } finally {
      _isProgrammaticMapCameraMove = false;
      if (_isMapGestureInProgress && mounted) {
        setState(() {
          _isMapGestureInProgress = false;
        });
      }
    }
  }

  // Future<void> _zoomIn() async {
  //   final controller = ref.read(carpoolProvider).hasRequestedRide
  //       ? _carpoolMapController
  //       : _mapController;
  //   if (controller == null) return;

  //   _currentZoom++;
  //   await controller.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  //   if (mounted) setState(() {});
  // }

  // Future<void> _zoomIn() async {
  //   debugPrint('_currentZoom: $_currentZoom');
  //   debugPrint('_maxZoom: $_maxZoom');

  //   final controller = ref.read(carpoolProvider).hasRequestedRide
  //       ? _carpoolMapController
  //       : _mapController;

  //   if (controller == null) return;

  //   if (_currentZoom >= _maxZoom) {
  //     debugPrint('Max zoom reached');
  //     return;
  //   }

  //   _currentZoom += 1;

  //   await controller.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  // }

  // Future<void> _zoomOut() async {
  //   final controller = ref.read(carpoolProvider).hasRequestedRide
  //       ? _carpoolMapController
  //       : _mapController;
  //   if (controller == null) return;

  //   _currentZoom--;
  //   await controller.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  //   if (mounted) setState(() {});
  // }

  Widget getSheet() {
    final CarpoolState carpoolState = ref.watch(carpoolProvider);
    if (carpoolState.isAccepted || carpoolState.isInProgress) {
      final String carpoolSheetKey = () {
        final String booking = carpoolState.bookingId.trim();
        if (booking.isNotEmpty) return booking;
        final String carpoolId = carpoolState.currentCarpoolId.trim();
        if (carpoolId.isNotEmpty) return carpoolId;
        return 'pending';
      }();
      return KeyedSubtree(
        key: ValueKey<String>('carpoolAcceptedRideSheet:$carpoolSheetKey'),
        child: const CarpoolAcceptedRideSheet(),
      );
    }

    final RideRoomState rideRoomState = ref.watch(rideRoomProvider);
    final rideType = rideRoomState.currentRideType;
    final String normalRideSheetKey = () {
      final String fromRide = (rideRoomState.activeRide?.id ?? '').trim();
      if (fromRide.isNotEmpty) return fromRide;
      final String fromStatus = (rideRoomState.latestRideStatus?.rideId ?? '')
          .trim();
      if (fromStatus.isNotEmpty) return fromStatus;
      final String req = (rideRoomState.rideRequestId ?? '').trim();
      if (req.isNotEmpty) return req;
      return 'none';
    }();
    final Widget sheet;
    switch (currentSheet) {
      case RideSheetsType.whereToGoSheet:
        sheet = const KeyedSubtree(
          key: ValueKey<String>('whereToGoSheet'),
          child: WhereToGoSheet(),
        );
        break;
      case RideSheetsType.selectRideSheet:
        sheet = const KeyedSubtree(
          key: ValueKey<String>('selectRideSheet'),
          child: SelectRideSheet(),
        );
        break;
      case RideSheetsType.findingDriverSheet:
        sheet = const KeyedSubtree(
          key: ValueKey<String>('findingDriverSheet'),
          child: FindingRideSheet(),
        );
        break;
      case RideSheetsType.driverArrivedSheet:
        sheet = KeyedSubtree(
          key: ValueKey<String>('driverArrivedSheet:$normalRideSheetKey'),
          child: const DriverArrivedSheet(),
        );
        break;
      case RideSheetsType.onGoingRideStatusSheet:
        final OnGoingRideStatus status =
            rideType?.toOnGoingRideStatus() ?? OnGoingRideStatus.onTheWay;
        sheet = KeyedSubtree(
          key: ValueKey<String>('onGoingRideStatusSheet:$normalRideSheetKey'),
          child: OnGoingRideStatusSheet(status: status),
        );
        break;
    }
    return sheet;
  }

  Color backgroundColor(BuildContext c) =>
      c.isDark ? Colors.transparent : Theme.of(c).scaffoldBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideRoomProvider);
    final CarpoolState carpoolState = ref.watch(carpoolProvider);
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final RideSheetsType sheetType = rideState.currentSheet;
    final bool hasActiveCarpoolSheet =
        carpoolState.isAccepted || carpoolState.isInProgress;
    final bool hideTopBarActions =
        hasActiveCarpoolSheet ||
        sheetType == RideSheetsType.findingDriverSheet ||
        sheetType == RideSheetsType.onGoingRideStatusSheet ||
        sheetType == RideSheetsType.driverArrivedSheet;
    final bool showShareRideButton =
        hasActiveCarpoolSheet ||
        sheetType == RideSheetsType.driverArrivedSheet ||
        sheetType == RideSheetsType.onGoingRideStatusSheet;
    // The search sheet stays up after the ladder is exhausted to show the "no
    // drivers" panel, so the ripple follows the search itself, not the sheet.
    // Nothing is being searched while the rider answers an upgrade offer.
    final bool showFindingRideRipple =
        rideState.currentSheet == RideSheetsType.findingDriverSheet &&
        rideState.searchExhausted == null &&
        rideState.upgradeOffer == null;

    final String? currentErrorMessage = rideState.errorMessage?.trim();
    final bool shouldShowExistingError =
        rideState.status == RideRoomStatus.error &&
        (currentErrorMessage?.isNotEmpty ?? false) &&
        currentErrorMessage != _lastShownRideErrorMessage;

    if (shouldShowExistingError) {
      _lastShownRideErrorMessage = currentErrorMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // context.showErrorToast(currentErrorMessage ?? l10n.somethingWentWrong);
      });
    }

    ref.listen<RideRoomState>(rideRoomProvider, (previous, next) {
      final BuildContext? targetContext = rootNavigatorKey.currentContext;
      if (targetContext == null) return;
      // final String currentPath =
      //     AppRouter.router.routeInformationProvider.value.uri.path;

      // final isCarpoolFinding =
      //     next.rideRequestId?.toLowerCase().startsWith('carpool-finding') ==
      //     true;
      // final wasCarpoolFinding =
      //     previous?.rideRequestId?.toLowerCase().startsWith(
      //       'carpool-finding',
      //     ) ==
      //     true;

      // if (isCarpoolFinding &&
      //     next.pendingCarpoolParams != null &&
      //     !wasCarpoolFinding) {
      //   _carpoolFindingTimer?.cancel();
      //   final paramsToPush = next.pendingCarpoolParams;
      //   _carpoolFindingTimer = Timer(const Duration(seconds: 3), () async {
      //     if (paramsToPush == null) return;

      //     await ref.read(carpoolProvider.notifier).searchBySocket(paramsToPush);
      //     if (!mounted) return;

      //     final CarpoolState carpoolState = ref.read(carpoolProvider);
      //     if (carpoolState.status == CarpoolSearchStatus.error) {
      //       if ((carpoolState.errorMessage?.trim().isNotEmpty ?? false)) {
      //         context.showErrorToast(carpoolState.errorMessage!);
      //       }
      //       return;
      //     }

      //     ref.read(rideRoomProvider.notifier).clearPendingCarpoolParams();
      //     final ctx = rootNavigatorKey.currentContext;
      //     if (ctx != null) {
      //       WidgetsBinding.instance.addPostFrameCallback((_) {
      //         final c = rootNavigatorKey.currentContext;
      //         if (c != null) {
      //           c.pushNamed(
      //             Routes.availableCarpoolRides.name,
      //             extra: paramsToPush,
      //           );
      //         }
      //       });
      //     }
      //   });
      // } else if (!isCarpoolFinding && wasCarpoolFinding) {
      //   _carpoolFindingTimer?.cancel();
      //   _carpoolFindingTimer = null;
      // }

      final hasNewError =
          previous?.errorMessage != next.errorMessage &&
          next.status == RideRoomStatus.error &&
          (next.errorMessage?.isNotEmpty ?? false);

      if (hasNewError) {
        _lastShownRideErrorMessage = next.errorMessage;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.showErrorToast(next.errorMessage ?? l10n.somethingWentWrong);
          final hasNoCard = next.errorMessage?.toLowerCase().contains(
            'no active card',
          );
          if (hasNoCard ?? false) {
            context.showDialogToast(
              onButtonPressed: () {
                AppToastDialog.close();
                context.pushNamed(Routes.addCard.name);
              },
              buttonText: l10n.addCard,
              subtitle: l10n.please_add_card_to_continue,
              type: DialogToastType.warning,
              duration: const Duration(minutes: 3),
            );
          }
          ref.read(rideRoomProvider.notifier).setStatusToInitial();
        });
        return;
      }

      final bool becameCancelled =
          previous?.currentRideType != RideType.cancelled &&
          next.currentRideType == RideType.cancelled;
      final bool hasNewCancelMessage =
          previous?.errorMessage != next.errorMessage &&
          next.currentRideType == RideType.cancelled &&
          (next.errorMessage?.trim().isNotEmpty ?? false);
      final bool shouldPopAfterCancel =
          next.currentSheet != RideSheetsType.selectRideSheet;

      if (becameCancelled || hasNewCancelMessage) {
        final String cancelMessage =
            next.latestRideStatus?.message?.trim().isNotEmpty == true
            ? next.latestRideStatus!.message!.trim()
            : next.errorMessage ?? l10n.somethingWentWrong;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.showToast(cancelMessage);
          if (shouldPopAfterCancel && GoRouter.of(context).canPop()) {
            context.pop();
          }
        });
      }

      final bool becameAccepted =
          previous?.currentRideType != RideType.accepted &&
          next.currentRideType == RideType.accepted;
      if (becameAccepted &&
          (next.latestRideStatus?.message?.trim().isNotEmpty == true)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.showSuccessToast(next.latestRideStatus!.message!);
        });
      }

      final bool becameCompleted =
          previous?.currentRideType != RideType.completed &&
          next.currentRideType == RideType.completed;

      if (becameCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.pushNamed(Routes.ridecomplete.name);
        });
      }
    });

    ref.listen<CarpoolState>(carpoolProvider, (previous, next) {
      final BuildContext? targetContext = rootNavigatorKey.currentContext;
      if (targetContext == null) return;

      final String currentPath =
          AppRouter.router.routeInformationProvider.value.uri.path;
      final bool routeChanged =
          previous?.requestedRide != next.requestedRide ||
          previous?.requestStatus != next.requestStatus;
      final bool driverLocationChanged =
          previous?.latestDriverLocation?.timestamp !=
              next.latestDriverLocation?.timestamp ||
          previous?.latestDriverLocation?.coordinates !=
              next.latestDriverLocation?.coordinates;
      final bool isActiveRide = next.isAccepted || next.isInProgress;

      if (isActiveRide && routeChanged) {
        unawaited(_syncCarpoolRouteOnMap(next));
      } else if (isActiveRide && driverLocationChanged) {
        unawaited(_syncCarpoolDriverOnMap(next));
      }

      final bool hasNewSearchError =
          previous?.errorMessage != next.errorMessage &&
          next.status == CarpoolSearchStatus.error &&
          (next.errorMessage?.trim().isNotEmpty ?? false);
      if (hasNewSearchError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final hasNoCard = next.errorMessage?.toLowerCase().contains(
            'no active card',
          );
          if (hasNoCard ?? false) {
            context.showDialogToast(
              onButtonPressed: () {
                AppToastDialog.close();
                context.pushNamed(Routes.addCard.name);
              },
              buttonText: l10n.addCard,
              subtitle: l10n.please_add_card_to_continue,
              type: DialogToastType.warning,
              duration: const Duration(minutes: 3),
            );
          }
        });
      }

      final bool becameCompleted =
          previous?.isCompleted != true && next.isCompleted;
      if (becameCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_resetCarpoolMap());
          if (currentPath == Routes.requestedCarpool.path) return;
          if (currentPath != Routes.carpoolRideComplete.path) {
            targetContext.goNamed(Routes.carpoolRideComplete.name);
          }
        });
        return;
      }

      final bool becameActiveRide =
          (previous?.isAccepted == true || previous?.isInProgress == true) !=
              true &&
          (next.isAccepted || next.isInProgress);
      if (becameActiveRide) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (currentPath != Routes.home.path) {
            targetContext.goNamed(Routes.home.name);
          }
        });
        return;
      }

      final bool becameRejected =
          previous?.hasRequestedRide == true &&
          !next.hasRequestedRide &&
          previous?.isAccepted != true &&
          previous?.isCompleted != true;
      if (becameRejected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(rideRoomProvider.notifier)
              .updateCurrentSheet(RideSheetsType.whereToGoSheet);
          ref.read(mapProvider.notifier).clearRideMapData();
          unawaited(_resetCarpoolMap());
          if (currentPath != Routes.home.path) {
            targetContext.goNamed(Routes.home.name);
          }
          if ((next.actionMessage?.trim().isNotEmpty ?? false)) {
            context.showErrorToast(next.actionMessage!);
          }
        });
        return;
      }

      final bool restoredRequestedCarpool =
          previous?.hasRequestedRide != true &&
          next.hasRequestedRide &&
          !next.isAccepted &&
          !next.isInProgress;
      if (!restoredRequestedCarpool) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _redirectToRequestedCarpoolIfNeeded(next);
      });
    });

    ref.listen<AsyncValue<MapState>>(mapProvider, (previous, next) {
      final prevState = previous?.asData?.value;
      final nextState = next.asData?.value;
      if (nextState == null) return;

      final String? nextMapError = nextState.errorMessage?.trim();
      final bool shouldSuppressMapToast =
          nextState.locationDialogType != LocationDialogType.none;
      if (!shouldSuppressMapToast &&
          (nextMapError?.isNotEmpty ?? false) &&
          nextMapError != _lastShownMapErrorMessage) {
        _lastShownMapErrorMessage = nextMapError;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.showErrorToast(nextMapError!);
        });
      }

      if (prevState == null) return;
      if (_mapController == null) return;

      final bool pickupChanged =
          prevState.pickup?.latLng != nextState.pickup?.latLng;
      final bool dropOffChanged =
          prevState.dropOff?.latLng != nextState.dropOff?.latLng;
      final bool currentLocationChanged =
          prevState.currentLocation.latLng != nextState.currentLocation.latLng;
      if (!pickupChanged && !dropOffChanged && !currentLocationChanged) {
        return;
      }

      final bool cameraChanged =
          prevState.cameraPosition.target != nextState.cameraPosition.target ||
          (prevState.cameraPosition.zoom - nextState.cameraPosition.zoom)
                  .abs() >
              0.001 ||
          (prevState.cameraPosition.tilt - nextState.cameraPosition.tilt)
                  .abs() >
              0.001 ||
          (prevState.cameraPosition.bearing - nextState.cameraPosition.bearing)
                  .abs() >
              0.001;
      if (!cameraChanged) return;

      unawaited(
        _animateMainMapCamera(
          CameraUpdate.newCameraPosition(nextState.cameraPosition),
        ),
      );
    });
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        image: context.isDark
            ? const DecorationImage(
                image: AssetImage(AppImages.bgTwo),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: ZoomDrawer(
        controller: zoomController,
        disableDragGesture: true,
        mainScreenTapClose: true,
        menuBackgroundColor: backgroundColor(context),
        angle: 0.0,
        // mainScreenAbsorbPointer: false,
        androidCloseOnBackTap: true,
        slideWidth: MediaQuery.of(context).size.width * 0.75,
        borderRadius: 24.0,
        showShadow: true,
        menuScreenWidth: double.infinity,
        drawerShadowsBackgroundColor: AppColors.brandLight,
        menuScreen: !hideTopBarActions
            ? AppDrawer(zoomController: zoomController)
            : const SizedBox.shrink(),
        mainScreen: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: DashboardAppBar(
            zoomController: zoomController,
            onNotificationTap: () =>
                context.pushNamed(Routes.notificationsScreen.name),
            title: l10n.dashboard,

            showTitle: !hideTopBarActions,
            showDrawerButton: !hideTopBarActions,
            showNotificationIcon: !hideTopBarActions,
            customAction: showShareRideButton ? const ShareButton() : null,
            // onNotificationTap: () => context.pushNamed(Routes.chat.name),
          ),
          body: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              hasActiveCarpoolSheet
                  ? CarpoolGoogleMapWidget(
                      brightness: brightness,
                      scrollGesturesEnabled: !showFindingRideRipple,
                      onCameraMoveStarted: _handleMapCameraMoveStarted,
                      onCameraIdle: () => _handleMapCameraIdle(() async {}),
                      onCameraMove: (position) {
                        _currentZoom = position.zoom;
                      },
                      onMapCreated: (GoogleMapController controller) {
                        _carpoolMapController?.dispose();
                        _carpoolMapController = controller;
                      },
                    )
                  : RideGoogleMapWidget(
                      scrollGesturesEnabled: !showFindingRideRipple,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController?.dispose();
                        _mapController = controller;
                      },
                      onCameraMoveStarted: () {
                        _handleMapCameraMoveStarted();
                        // Signal the fixed pin to lift.
                        if (sheetType == RideSheetsType.whereToGoSheet) {
                          ref.read(isDraggingMapProvider.notifier).state = true;
                          ref
                                  .read(
                                    isResolvingPickupAddressProvider.notifier,
                                  )
                                  .state =
                              true;
                        }
                      },
                      onCameraMove: (position) {
                        _currentZoom = position.zoom;
                        // Feed the narrow provider so the pin/address chip
                        // can track the center without rebuilding the whole screen.
                        if (sheetType == RideSheetsType.whereToGoSheet) {
                          ref.read(cameraCenterProvider.notifier).state =
                              position.target;
                        }
                      },
                      onCameraIdle: () => _handleMapCameraIdle(() {
                        // Signal the fixed pin to drop.
                        ref.read(isDraggingMapProvider.notifier).state = false;
                        // Resolve the pickup address at the map center.
                        if (sheetType == RideSheetsType.whereToGoSheet) {
                          final center = ref.read(cameraCenterProvider);
                          if (center.latitude != 0 || center.longitude != 0) {
                            ref
                                .read(mapProvider.notifier)
                                .resolvePickupFromMapCenter(center)
                                .then((_) {
                                  ref
                                          .read(
                                            isResolvingPickupAddressProvider
                                                .notifier,
                                          )
                                          .state =
                                      false;
                                });
                          } else {
                            ref
                                    .read(
                                      isResolvingPickupAddressProvider.notifier,
                                    )
                                    .state =
                                false;
                          }
                        }
                      }),
                    ),

              /* // Positioned(
            //   right: 12,
            //   top: MediaQuery.of(context).padding.top + 70,
            //   child: Column(
            //     children: [
            //       SizedBox(
            //         width: 130,
            //         child: ElevatedButton(
            //           onPressed: _runPolylineDemo,
            //           child: const Text('Run Demo'),
            //         ),
            //       ),
            //       const SizedBox(height: 8),
            //       SizedBox(
            //         width: 130,
            //         child: ElevatedButton(
            //           onPressed: _resetDemo,
            //           child: const Text('Reset Demo'),
            //         ),
            //       ),
            //     ],
            //   ),
            // ), */
              // ── Fixed-pin overlay for drag-to-select pickup ──
              // Visible only during the initial 'whereToGoSheet' phase.
              // Once a ride is being searched/in-progress, native markers take over.
              if (sheetType == RideSheetsType.whereToGoSheet &&
                  !hasActiveCarpoolSheet)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. The fixed pin (anchored independently at map center)
                        Positioned(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: Consumer(
                              builder: (context, ref, _) {
                                final isDragging = ref.watch(
                                  isDraggingMapProvider,
                                );
                                return FixedCenterPin(isDragging: isDragging);
                              },
                            ),
                          ),
                        ),

                        // 2. Address chip positioned independently above the pin
                        Positioned(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 220),
                            child: Consumer(
                              builder: (context, ref, _) {
                                final isDragging = ref.watch(
                                  isDraggingMapProvider,
                                );
                                final isResolvingNarrow = ref.watch(
                                  isResolvingPickupAddressProvider,
                                );
                                final mapData = ref
                                    .watch(mapProvider)
                                    .asData
                                    ?.value;
                                final pickupName = mapData?.pickup?.name ?? '';
                                final isResolving =
                                    isResolvingNarrow ||
                                    (mapData?.isResolvingLocationName ?? false);
                                final bool shouldShow =
                                    !isDragging &&
                                    (pickupName.isNotEmpty || isResolving);

                                return AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  opacity: shouldShow ? 1.0 : 0.0,
                                  child: AnimatedSlide(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    offset: isDragging
                                        ? const Offset(0, 0.15)
                                        : Offset.zero,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.sizeOf(context).width *
                                            0.75,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.appColors.fieldFill
                                            .withValues(
                                              alpha: context.isDark
                                                  ? 0.95
                                                  : 0.98,
                                            ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: context.appColors.border
                                              .withValues(alpha: 0.8),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: context.isDark
                                                  ? 0.35
                                                  : 0.08,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.where_from,
                                            style: context.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: context
                                                      .appColors
                                                      .textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                  letterSpacing: 0.2,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                          ),
                                          const SizedBox(height: 3),
                                          isResolving
                                              ? Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                AppColors.brand,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      l10n.locating,
                                                      style: context
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: context
                                                                .appColors
                                                                .textSecondary,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                      textAlign:
                                                          TextAlign.start,
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  pickupName,
                                                  style: context
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: context
                                                            .appColors
                                                            .textPrimary,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (showFindingRideRipple)
                // Centred on the strip of map the sheet leaves visible, not on
                // the screen: the search sheet opens tall enough that a
                // screen-centred animation would sit behind it.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom:
                      ContextExtension(context).screenHeight *
                      FindingRideSheet.collapsedSize,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RippleAnimation(
                          color: AppColors.brand,
                          delay: const Duration(milliseconds: 500),
                          repeat: true,
                          minRadius: 30,
                          maxRadius: 60,
                          ripplesCount: 3,
                          duration: const Duration(milliseconds: 1500),
                          child: CircleAvatar(
                            minRadius: 35,
                            maxRadius: 35,
                            child: Image.asset(
                              AppIcons.locationMarker,
                              width:
                                  ContextExtension(context).screenWidth * 0.09,
                              height:
                                  ContextExtension(context).screenHeight * 0.09,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Visibility(
              //   visible: showMapZoomControls,
              //   child: Positioned(
              //     right: 16,
              //     bottom: MediaQuery.sizeOf(context).height * 0.45,
              //     child: MapZoomControls(
              //       onZoomIn: _zoomIn,
              //       onZoomOut: _zoomOut,
              //     ),
              //   ),
              // ),
              Positioned.fill(
                child:
                    IgnorePointer(
                          ignoring: _isMapGestureInProgress,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 520),
                            curve: Curves.easeOutCubic,
                            offset: _isMapGestureInProgress
                                ? const Offset(0, 1)
                                : Offset.zero,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 520),
                              curve: Curves.easeOutCubic,
                              opacity: _isMapGestureInProgress ? 0 : 1,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 520),
                                reverseDuration: const Duration(
                                  milliseconds: 520,
                                ),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                layoutBuilder:
                                    (currentChild, previousChildren) {
                                      return Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          ...previousChildren,
                                          ?currentChild,
                                        ],
                                      );
                                    },
                                transitionBuilder: (child, animation) {
                                  final Animation<Offset> slideAnimation =
                                      Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero,
                                      ).animate(animation);

                                  final Animation<double> fadeAnimation =
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                        reverseCurve: Curves.easeIn,
                                      );

                                  return SlideTransition(
                                    position: slideAnimation,
                                    child: FadeTransition(
                                      opacity: fadeAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: AnimatedPadding(
                                  duration: const Duration(milliseconds: 50),
                                  padding: EdgeInsets.only(bottom: bottomInset),
                                  child: getSheet(),
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          curve: Curves.easeOutBack,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
