import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/location/service_region.dart';
import 'package:ride_app/core/theme/map_styles.dart';
import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
import 'package:ride_app/features/ride_room/enums/ride_enum.dart';
import 'package:ride_app/features/ride_room/presentation/providers/enter_route_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/widgets/fixed_center_pin.dart';
import 'package:ride_app/shared/models/selected_location.dart';
import 'package:ride_app/shared/providers/place_picker_provider.dart';
import 'package:ride_app/shared/shared.dart';
import 'package:ride_app/shared/states/place_picker_state.dart';

class RidePlacePickerArgs {
  const RidePlacePickerArgs({required this.purpose, this.initialAddress});

  final RideLocationType purpose;
  final Address? initialAddress;
}

class RidePlacePickerScreen extends ConsumerStatefulWidget {
  const RidePlacePickerScreen({super.key, required this.args});

  final RidePlacePickerArgs args;

  @override
  ConsumerState<RidePlacePickerScreen> createState() =>
      _RidePlacePickerScreenState();
}

class _RidePlacePickerScreenState extends ConsumerState<RidePlacePickerScreen> {
  GoogleMapController? _mapController;
  Brightness? _lastBrightness;
  LatLng? _lastSelectedTarget;
  bool _isDraggingPickerMap = false;

  RideLocationType get _purpose => widget.args.purpose;

  @override
  void initState() {
    super.initState();
    _lastSelectedTarget = widget.args.initialAddress == null
        ? null
        : LatLng(
            widget.args.initialAddress!.latitiude,
            widget.args.initialAddress!.longitude,
          );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(placePickerProvider.notifier)
          .setMapStyle(Theme.of(context).brightness);
      final latLng = await ref
          .read(placePickerProvider.notifier)
          .setInitialLocation(initialAddress: widget.args.initialAddress);
      if (latLng != null) {
        await _moveCamera(latLng);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      ref.read(placePickerProvider.notifier).setMapStyle(brightness);
    }
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  Future<void> _moveCamera(LatLng position) async {
    if (!mounted) return;
    _lastSelectedTarget = position;
    final controller = _mapController;
    if (controller == null) return;
    try {
      await controller.animateCamera(CameraUpdate.newLatLng(position));
    } catch (_) {}
  }

  void _clearRegionErrorMessage() {
    ref.read(placePickerProvider.notifier).clearRegionErrorMessage();
  }

  Future<void> _confirmMapSelection(PlacePickerState state) async {
    final activeRegion = ServiceRegionConfig.active;
    final bool isInsideActiveRegion = activeRegion.contains(
      state.currentPosition,
    );
    if (!isInsideActiveRegion) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.outside_service_region),
          content: Text(
            context.l10n.outside_service_region_message(
              activeRegion.displayName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _clearRegionErrorMessage();
              },
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    final trimmedAddress = state.address.trim();
    if (trimmedAddress.isEmpty) return;

    final resolvedAddress =
        state.selectedAddress.formattedAddress.trim().isNotEmpty
        ? state.selectedAddress
        : Address(
            latitiude: state.currentPosition.latitude,
            longitude: state.currentPosition.longitude,
            country: '',
            state: '',
            city: '',
            zipCode: '',
            countryCode: '',
            formattedAddress: trimmedAddress,
          );

    final latLng = LatLng(resolvedAddress.latitiude, resolvedAddress.longitude);
    final value = resolvedAddress.formattedAddress.trim();

    if (_purpose == RideLocationType.pickup) {
      await ref
          .read(mapProvider.notifier)
          .setPickupLocation(
            latLng,
            name: value,
            resolvedPlace: remoteConfigModel.addressSearchV2Enabled
                ? resolvedAddress.resolvedPlace
                : null,
            city: remoteConfigModel.addressSearchV2Enabled
                ? resolvedAddress.city
                : null,
            resolveNameIfMissing: !remoteConfigModel.addressSearchV2Enabled,
          );
      await ref
          .read(enterRouteProvider.notifier)
          .saveFromSelection(
            fullAddress: value,
            latitude: latLng.latitude,
            longitude: latLng.longitude,
            type: RideLocationType.pickup,
          );
      if (!mounted) return;
      final mapState = ref.read(mapProvider).value;
      if (mapState?.dropOff != null &&
          mapState!.dropOff!.name.trim().isNotEmpty) {
        ref
            .read(rideRoomProvider.notifier)
            .updateCurrentSheet(RideSheetsType.selectRideSheet);
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop(resolvedAddress);
      }
    } else {
      await ref
          .read(mapProvider.notifier)
          .setDropOffLocation(
            latLng,
            name: value,
            resolvedPlace: remoteConfigModel.addressSearchV2Enabled
                ? resolvedAddress.resolvedPlace
                : null,
            city: remoteConfigModel.addressSearchV2Enabled
                ? resolvedAddress.city
                : null,
            resolveNameIfMissing: !remoteConfigModel.addressSearchV2Enabled,
          );
      await ref
          .read(enterRouteProvider.notifier)
          .saveFromSelection(
            fullAddress: value,
            latitude: latLng.latitude,
            longitude: latLng.longitude,
            type: RideLocationType.dropoff,
          );
      if (!mounted) return;
      final mapState = ref.read(mapProvider).value;
      if (mapState?.pickup != null &&
          mapState!.pickup!.name.trim().isNotEmpty) {
        ref
            .read(rideRoomProvider.notifier)
            .updateCurrentSheet(RideSheetsType.selectRideSheet);
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop(resolvedAddress);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placePickerProvider);
    final notifier = ref.read(placePickerProvider.notifier);
    final colors = context.appColors;
    final l10n = context.l10n;
    final activeRegion = ServiceRegionConfig.active;
    final CameraTargetBounds cameraTargetBounds = activeRegion.isGlobal
        ? CameraTargetBounds.unbounded
        : CameraTargetBounds(activeRegion.bounds);

    final bool hasResolvedLocation =
        state.selectedAddress.formattedAddress.trim().isNotEmpty &&
        (state.selectedAddress.latitiude != 0 ||
            state.selectedAddress.longitude != 0);

    ref.listen<PlacePickerState>(placePickerProvider, (previous, next) {
      final String? previousMessage = previous?.regionErrorMessage?.trim();
      final String? currentMessage = next.regionErrorMessage?.trim();
      if (currentMessage == null || currentMessage.isEmpty) return;
      if (currentMessage == previousMessage) return;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.outside_service_region),
            content: Text(currentMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _clearRegionErrorMessage();
                },
                child: Text(context.l10n.ok),
              ),
            ],
          ),
        );
      });
    });

    final String screenTitle = _purpose == RideLocationType.pickup
        ? l10n.pickup_location
        : l10n.dropoff_location;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          // Full-screen map extending to edges
          Positioned.fill(
            child: RepaintBoundary(
              child: Listener(
                onPointerDown: (_) => notifier.onMapGestureStarted(),
                child: GoogleMap(
                  style: state.mapStyle.isNotEmpty
                      ? state.mapStyle
                      : (context.isDark ? MapStyles.dark : MapStyles.light),
                  initialCameraPosition: CameraPosition(
                    target: _lastSelectedTarget ?? state.currentPosition,
                    zoom: 16,
                  ),
                  cameraTargetBounds: cameraTargetBounds,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    final target = _lastSelectedTarget;
                    if (target != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        if (!mounted) return;
                        final currentController = _mapController;
                        if (currentController == null) return;
                        try {
                          await currentController.animateCamera(
                            CameraUpdate.newLatLng(target),
                          );
                        } catch (_) {}
                      });
                    }
                  },
                  onCameraMove: (position) {
                    notifier.onCameraMove(position.target);
                  },
                  onCameraMoveStarted: () {
                    if (mounted) {
                      setState(() => _isDraggingPickerMap = true);
                    }
                  },
                  onCameraIdle: () {
                    if (mounted) {
                      setState(() => _isDraggingPickerMap = false);
                    }
                    notifier.onCameraIdle();
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  buildingsEnabled: false,
                  mapToolbarEnabled: false,
                  indoorViewEnabled: false,
                ),
              ),
            ),
          ),

          // Center Fixed Pin with lift/drop tactile animation
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FixedCenterPin(
                isDragging: _isDraggingPickerMap,
                pinColor: colors.brand,
                pinSize: 42,
              ),
            ),
          ),

          // Floating Top Header (Back button + centered pill title)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Floating Circular Back Button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: context.isDark ? 0.4 : 0.12,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                // Floating Title Pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(
                        alpha: context.isDark ? 0.92 : 0.96,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDark ? 0.35 : 0.1,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, size: 16, color: colors.brand),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            screenTitle,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 48,
                ), // Balances back button for true visual center
              ],
            ),
          ),

          // Bottom Action Panel
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating My Location Button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FloatingActionButton.small(
                        heroTag: 'ride_place_picker_my_location_btn',
                        onPressed: () async {
                          final latLng = await notifier.setInitialLocation(
                            openSettingsIfNeeded: true,
                          );
                          if (latLng != null) {
                            await _moveCamera(latLng);
                          }
                        },
                        backgroundColor: colors.surface,
                        child: Icon(
                          Icons.my_location,
                          color: colors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                // Resolved address card + Confirm button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.fieldFill.withValues(
                      alpha: context.isDark ? 0.95 : 0.98,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: context.isDark ? 0.4 : 0.1,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.brand.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: colors.brand,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.selected_location_label,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                state.isFetchingAddress
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: colors.brand,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.locating,
                                            style: context.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        state.address.isNotEmpty
                                            ? state.address
                                            : l10n.locating,
                                        style: context.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colors.textPrimary,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: _purpose == RideLocationType.pickup
                            ? l10n.confirm_pickup
                            : l10n.confirm_dropoff,
                        backgroundColor: colors.brand,
                        fontColor: colors.button,
                        onPressed:
                            (!state.isFetchingAddress &&
                                (hasResolvedLocation ||
                                    state.address.trim().isNotEmpty))
                            ? () => _confirmMapSelection(state)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
