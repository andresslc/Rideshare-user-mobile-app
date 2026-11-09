import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/location/service_region.dart';
import 'package:ride_app/shared/models/selected_location.dart';
import 'package:ride_app/shared/providers/place_picker_provider.dart';
import 'package:ride_app/shared/states/place_picker_state.dart';
import 'package:ride_app/shared/widgets/app_button.dart';

import '../../core/theme/map_styles.dart';
import '../location_component/location_ui/address_search_error.dart';

class PlacePickerScreen extends ConsumerStatefulWidget {
  const PlacePickerScreen({super.key, this.initialAddress});

  final Address? initialAddress;

  @override
  ConsumerState<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends ConsumerState<PlacePickerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(placePickerProvider.notifier)
          .setMapStyle(Theme.of(context).brightness);
      final latLng = await ref
          .read(placePickerProvider.notifier)
          .setInitialLocation(initialAddress: widget.initialAddress);
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _moveCamera(LatLng position) async {
    final controller = await _mapController.future;
    if (!mounted) return;
    ref.read(placePickerProvider.notifier).markProgrammaticMove(position);
    await controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _onConfirm(Address address) {
    if (address.city.trim().isEmpty ||
        address.state.trim().isEmpty ||
        address.country.trim().isEmpty) {
      context.showErrorToast(
        context.l10n.please_choose_location_with_full_address,
      );
      return;
    }
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placePickerProvider);
    final notifier = ref.read(placePickerProvider.notifier);
    // final activeRegion = locator<LocationService>().activeRegion;
    final activeRegion = ServiceRegionConfig.active;
    final CameraTargetBounds cameraTargetBounds = activeRegion.isGlobal
        ? CameraTargetBounds.unbounded
        : CameraTargetBounds(activeRegion.bounds);
    final colors = context.appColors;
    final bool hasResolvedLocation =
        !state.isFetchingAddress &&
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
                  ref
                      .read(placePickerProvider.notifier)
                      .clearRegionErrorMessage();
                },
                child: Text(context.l10n.ok),
              ),
            ],
          ),
        );
      });
    });

    return Scaffold(
      body: Stack(
        children: [
          // Map
          Listener(
            onPointerDown: (_) => notifier.onMapGestureStarted(),
            child: GoogleMap(
              style: state.mapStyle.isNotEmpty
                  ? state.mapStyle
                  : (context.isDark ? MapStyles.dark : MapStyles.light),
              initialCameraPosition: CameraPosition(
                target: state.currentPosition,
                zoom: 15,
              ),
              cameraTargetBounds: cameraTargetBounds,
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
              },
              onCameraMove: (position) {
                notifier.onCameraMove(position.target);
              },
              onCameraIdle: () {
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

          // Center Pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 50,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: state.isFetchingAddress ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !state.isFetchingAddress,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.brand,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.brand,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: notifier.searchPlaces,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 0,
                      ),
                      hintText: context.l10n.search_placeholder,
                      hintStyle: TextStyle(color: colors.textSecondary),
                      prefixIcon: IconButton(
                        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      suffixIcon: state.isFetchingSuggestions
                          ? Align(
                              alignment: Alignment.centerRight,
                              widthFactor: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 15),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.brand,
                                  ),
                                ),
                              ),
                            )
                          : ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _searchController,
                              builder: (context, value, child) {
                                return value.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: colors.textPrimary,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          notifier.searchPlaces('');
                                        },
                                      )
                                    : const SizedBox.shrink();
                              },
                            ),
                      border: InputBorder.none,
                      // contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                if (state.searchError != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: AddressSearchError(
                      failure: state.searchError!,
                      onRetry: () async {
                        final position = await notifier.retrySelection();
                        if (mounted && position != null) {
                          await _moveCamera(position);
                        }
                      },
                    ),
                  ),
                // Suggestions List
                if (state.suggestions.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: state.suggestions.length + 1,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            // ignore: deprecated_member_use
                            color: colors.border.withOpacity(0.5),
                          ),
                          itemBuilder: (context, index) {
                            if (index == state.suggestions.length) {
                              return const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Google Maps',
                                  textAlign: TextAlign.end,
                                ),
                              );
                            }
                            final suggestion = state.suggestions[index];
                            return Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                title: Text(
                                  suggestion['description'],
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () async {
                                  FocusScope.of(context).unfocus();
                                  final latLng = await notifier
                                      .selectSuggestion(suggestion);
                                  if (latLng != null) {
                                    _searchController.text =
                                        suggestion['description'];
                                    await _moveCamera(latLng);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Address Display and Button
          if (state.suggestions.isEmpty)
            Positioned(
              bottom: kToolbarHeight,
              left: 20,
              right: 20,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                reverseDuration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final Animation<Offset> slideAnimation = Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation);
                  final Animation<double> fadeAnimation = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                    reverseCurve: Curves.easeIn,
                  );

                  return SlideTransition(
                    position: slideAnimation,
                    child: FadeTransition(opacity: fadeAnimation, child: child),
                  );
                },
                child: hasResolvedLocation
                    ? Column(
                        key: const ValueKey('resolved_location_actions'),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FloatingActionButton(
                                heroTag: 'my_location',
                                onPressed: () async {
                                  _searchController.clear();
                                  notifier.searchPlaces('');
                                  final latLng = await notifier
                                      .setInitialLocation(
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
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: colors.brand,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.selected_location_label,
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        state.address,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          AppButton(
                            text: context.l10n.confirm_location,
                            onPressed: () => _onConfirm(state.selectedAddress),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('empty_location_actions'),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
