import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
import 'package:ride_app/features/ride_room/enums/ride_enum.dart';
import 'package:ride_app/features/ride_room/presentation/providers/camera_providers.dart';
import 'package:ride_app/features/ride_room/presentation/providers/carpool_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/enter_route_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/enter_route_state.dart';
import 'package:ride_app/features/ride_room/presentation/states/map_state.dart';
import 'package:ride_app/features/ride_room/screens/ride_place_picker_screen.dart';
import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';
import 'package:ride_app/features/settings/presentation/providers/saved_locations_provider.dart';
import 'package:ride_app/features/settings/presentation/screens/add_to_location_sheet.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/models/selected_location.dart';
import 'package:ride_app/shared/shared.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';
import 'package:ride_app/shared/widgets/custom_dialogue.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

import '../../../core/services/places_search_service.dart';
import '../../../shared/location_component/location_ui/address_search_error.dart';

class EnterRouteScreen extends ConsumerStatefulWidget {
  final RideLocationType purpose;
  const EnterRouteScreen({super.key, this.purpose = RideLocationType.dropoff});

  @override
  ConsumerState<EnterRouteScreen> createState() => _EnterRouteScreenState();
}

class _EnterRouteScreenState extends ConsumerState<EnterRouteScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropOffController = TextEditingController();
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _dropOffFocusNode = FocusNode();
  late final EnterRouteNotifier _routeNotifier;
  bool _selecting = false;
  int _selectionGeneration = 0;
  RouteField _activeField = RouteField.dropoff;

  @override
  void initState() {
    super.initState();
    _routeNotifier = ref.read(enterRouteProvider.notifier);
    _activeField = widget.purpose == RideLocationType.pickup
        ? RouteField.pickup
        : RouteField.dropoff;

    _pickupFocusNode.addListener(_onFocusChanged);
    _dropOffFocusNode.addListener(_onFocusChanged);

    final mapState = ref.read(mapProvider).value;
    _syncControllersWithMapState(mapState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(rideRoomProvider.notifier).clearError();
      ref.read(carpoolProvider.notifier).clearError();

      if (widget.purpose == RideLocationType.pickup) {
        _pickupFocusNode.requestFocus();
      } else {
        _dropOffFocusNode.requestFocus();
      }
    });

    Future.microtask(() {
      if (!mounted) return;
      final notifier = ref.read(enterRouteProvider.notifier);
      final initialPickup = ref.read(mapProvider).value?.pickup?.latLng;
      notifier.initialize(initialOrigin: initialPickup);
    });

    final savedLocations = ref.read(savedLocationsProvider).locations;
    if (savedLocations.isEmpty) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(savedLocationsProvider.notifier).fetchSavedLocations();
      });
    }
  }

  @override
  void dispose() {
    _selectionGeneration++;
    _routeNotifier.abandonSearch(notify: false);
    _pickupFocusNode.removeListener(_onFocusChanged);
    _dropOffFocusNode.removeListener(_onFocusChanged);
    _pickupController.dispose();
    _dropOffController.dispose();
    _pickupFocusNode.dispose();
    _dropOffFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_pickupFocusNode.hasFocus) {
      _setActiveField(RouteField.pickup);
    } else if (_dropOffFocusNode.hasFocus) {
      _setActiveField(RouteField.dropoff);
    } else {
      final generation = _selectionGeneration;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted ||
            generation != _selectionGeneration ||
            _selecting ||
            _pickupFocusNode.hasFocus ||
            _dropOffFocusNode.hasFocus) {
          return;
        }
        ref.read(enterRouteProvider.notifier).abandonSearch();
      });
    }
  }

  void _setActiveField(RouteField field) {
    if (_activeField != field) {
      _selectionGeneration++;
      ref
          .read(enterRouteProvider.notifier)
          .activateField(
            field == RouteField.pickup
                ? RideLocationType.pickup
                : RideLocationType.dropoff,
          );
      setState(() => _activeField = field);
    }
  }

  void _syncControllersWithMapState(MapState? mapState) {
    final pickupName = mapState?.pickup?.name ?? '';
    final dropOffName = mapState?.dropOff?.name ?? '';

    if (_pickupController.text != pickupName) {
      _pickupController.text = pickupName;
    }
    if (_dropOffController.text != dropOffName) {
      _dropOffController.text = dropOffName;
    }
  }

  Future<void> updatePickup({
    required LatLng coordinates,
    required String? name,
    ResolvedPlace? resolvedPlace,
    String? city,
  }) async {
    final mapState = ref.read(mapProvider).value;
    final hasPromo = mapState?.hasAppliedPromoCode ?? false;
    if (hasPromo) {
      context.showPromoRemovalWarning(
        onConfirm: () async {
          ref.read(mapProvider.notifier).clearPromoCode();
          await ref
              .read(mapProvider.notifier)
              .setPickupLocation(
                coordinates,
                name: name,
                resolveNameIfMissing: !remoteConfigModel.addressSearchV2Enabled,
                resolvedPlace: remoteConfigModel.addressSearchV2Enabled
                    ? resolvedPlace
                    : null,
                city: remoteConfigModel.addressSearchV2Enabled ? city : null,
              );
        },
      );
    } else {
      await ref
          .read(mapProvider.notifier)
          .setPickupLocation(
            coordinates,
            name: name,
            resolveNameIfMissing: !remoteConfigModel.addressSearchV2Enabled,
            resolvedPlace: remoteConfigModel.addressSearchV2Enabled
                ? resolvedPlace
                : null,
            city: remoteConfigModel.addressSearchV2Enabled ? city : null,
          );
    }
  }

  Future<void> updateDropOff({
    required LatLng coordinates,
    required String? name,
    ResolvedPlace? resolvedPlace,
    String? city,
  }) async {
    final mapState = ref.read(mapProvider).value;
    final hasPromo = mapState?.hasAppliedPromoCode ?? false;
    if (hasPromo) {
      context.showPromoRemovalWarning(
        onConfirm: () async {
          ref.read(mapProvider.notifier).clearPromoCode();
          await ref
              .read(mapProvider.notifier)
              .setDropOffLocation(
                coordinates,
                name: name,
                resolveNameIfMissing: !remoteConfigModel.addressSearchV2Enabled,
                resolvedPlace: remoteConfigModel.addressSearchV2Enabled
                    ? resolvedPlace
                    : null,
                city: remoteConfigModel.addressSearchV2Enabled ? city : null,
              );
        },
      );
    } else {
      await ref
          .read(mapProvider.notifier)
          .setDropOffLocation(
            coordinates,
            name: name,
            resolveNameIfMissing: !remoteConfigModel.addressSearchV2Enabled,
            resolvedPlace: remoteConfigModel.addressSearchV2Enabled
                ? resolvedPlace
                : null,
            city: remoteConfigModel.addressSearchV2Enabled ? city : null,
          );
    }
  }

  Future<void> _confirmSelection() async {
    if (_selecting || ref.read(enterRouteProvider).isResolvingSelection) return;
    final mapState = ref.read(mapProvider).value;
    final bool hasValidPickup =
        mapState?.pickup != null &&
        (mapState?.pickup?.name.trim().isNotEmpty ?? false) &&
        _pickupController.text.trim().isNotEmpty;
    final bool hasValidDropOff =
        mapState?.dropOff != null &&
        (mapState?.dropOff?.name.trim().isNotEmpty ?? false) &&
        _dropOffController.text.trim().isNotEmpty;

    if (!hasValidPickup || !hasValidDropOff) {
      context.showWarningToast(context.l10n.select_pickup_dropoff);
      if (!hasValidPickup) {
        _pickupFocusNode.requestFocus();
      } else {
        _dropOffFocusNode.requestFocus();
      }
      return;
    }

    ref
        .read(rideRoomProvider.notifier)
        .updateCurrentSheet(RideSheetsType.selectRideSheet);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _handleBackPressed() async {
    if (context.canPop()) {
      context.pop();
    }
  }

  Address? _selectedAddressFor(RideLocationType type) {
    final mapState = ref.read(mapProvider).value;
    if (mapState == null) return null;

    final MapNamedPoint? point = type == RideLocationType.pickup
        ? mapState.pickup
        : mapState.dropOff;
    if (point == null) return null;
    if (point.resolvedPlace != null) {
      return Address.fromResolvedPlace(point.resolvedPlace!);
    }

    final String formattedAddress = point.name.trim();
    if (formattedAddress.isEmpty) return null;

    return Address(
      latitiude: point.latLng.latitude,
      longitude: point.latLng.longitude,
      country: '',
      state: '',
      city: point.city ?? '',
      zipCode: '',
      countryCode: '',
      formattedAddress: formattedAddress,
    );
  }

  Future<void> _openMapPicker({required bool forPickup}) async {
    final purpose = forPickup
        ? RideLocationType.pickup
        : RideLocationType.dropoff;
    _selectionGeneration++;
    ref.read(enterRouteProvider.notifier).abandonSearch();
    _setActiveField(forPickup ? RouteField.pickup : RouteField.dropoff);
    final Address? initialAddress = _selectedAddressFor(purpose);

    final selected = await context.pushNamed<Address>(
      Routes.ridePlacePicker.name,
      extra: RidePlacePickerArgs(
        purpose: purpose,
        initialAddress: initialAddress,
      ),
    );

    if (!mounted || selected == null) return;
    final value = selected.formattedAddress.trim();
    if (value.isEmpty) return;

    if (forPickup) {
      _pickupController.text = value;
    } else {
      _dropOffController.text = value;
    }

    await ref
        .read(enterRouteProvider.notifier)
        .saveFromSelection(
          fullAddress: value,
          latitude: selected.latitiude,
          longitude: selected.longitude,
          type: purpose,
        );

    final latLng = LatLng(selected.latitiude, selected.longitude);
    if (forPickup) {
      await updatePickup(
        coordinates: latLng,
        name: value,
        resolvedPlace: selected.resolvedPlace,
        city: selected.city,
      );
      if (!mounted) return;
      final mapState = ref.read(mapProvider).value;
      final bool hasValidDropOff =
          mapState?.dropOff != null &&
          (mapState?.dropOff?.name.trim().isNotEmpty ?? false) &&
          _dropOffController.text.trim().isNotEmpty;
      if (hasValidDropOff) {
        ref
            .read(rideRoomProvider.notifier)
            .updateCurrentSheet(RideSheetsType.selectRideSheet);
        if (context.canPop()) {
          context.pop();
        }
      } else {
        _dropOffFocusNode.requestFocus();
      }
    } else {
      await updateDropOff(
        coordinates: latLng,
        name: value,
        resolvedPlace: selected.resolvedPlace,
        city: selected.city,
      );
      if (!mounted) return;
      final mapState = ref.read(mapProvider).value;
      final bool hasValidPickup =
          mapState?.pickup != null &&
          (mapState?.pickup?.name.trim().isNotEmpty ?? false) &&
          _pickupController.text.trim().isNotEmpty;
      if (hasValidPickup) {
        ref
            .read(rideRoomProvider.notifier)
            .updateCurrentSheet(RideSheetsType.selectRideSheet);
        if (context.canPop()) {
          context.pop();
        }
      } else {
        _pickupFocusNode.requestFocus();
      }
    }
  }

  Future<void> _onLocationItemTap(Object location, {bool retry = false}) async {
    if (_selecting) return;
    _selecting = true;
    final generation = ++_selectionGeneration;
    try {
      ref.read(rideRoomProvider.notifier).clearError();
      ref.read(carpoolProvider.notifier).clearError();
      final purpose = _activeField == RouteField.pickup
          ? RideLocationType.pickup
          : RideLocationType.dropoff;

      final notifier = ref.read(enterRouteProvider.notifier);
      final resolved = retry
          ? await notifier.retrySelection(type: purpose)
          : await notifier.resolveSelectedLocation(
              location: location,
              type: purpose,
            );
      if (resolved == null || !mounted || generation != _selectionGeneration) {
        return;
      }

      final label = resolved.resolvedPlace?.label ?? resolved.address;
      if (purpose == RideLocationType.pickup) {
        _pickupController.text = label;
      } else {
        _dropOffController.text = label;
      }

      await ref
          .read(enterRouteProvider.notifier)
          .saveFromListItem(location: resolved, type: purpose);
      if (!mounted || generation != _selectionGeneration) return;

      final latLng = LatLng(resolved.latitude, resolved.longitude);

      if (purpose == RideLocationType.pickup) {
        await updatePickup(
          coordinates: latLng,
          name: label,
          resolvedPlace: resolved.resolvedPlace,
        );
        if (!mounted || generation != _selectionGeneration) return;
        final mapState = ref.read(mapProvider).value;
        final bool hasValidDropOff =
            mapState?.dropOff != null &&
            (mapState?.dropOff?.name.trim().isNotEmpty ?? false) &&
            _dropOffController.text.trim().isNotEmpty;
        if (hasValidDropOff) {
          ref
              .read(rideRoomProvider.notifier)
              .updateCurrentSheet(RideSheetsType.selectRideSheet);
          if (context.canPop()) {
            context.pop();
          }
        } else {
          _dropOffFocusNode.requestFocus();
          ref.read(enterRouteProvider.notifier).onSearchQueryChanged('');
        }
      } else {
        await updateDropOff(
          coordinates: latLng,
          name: label,
          resolvedPlace: resolved.resolvedPlace,
        );
        if (!mounted || generation != _selectionGeneration) return;
        final mapState = ref.read(mapProvider).value;
        final bool hasValidPickup =
            mapState?.pickup != null &&
            (mapState?.pickup?.name.trim().isNotEmpty ?? false) &&
            _pickupController.text.trim().isNotEmpty;
        if (hasValidPickup) {
          ref
              .read(rideRoomProvider.notifier)
              .updateCurrentSheet(RideSheetsType.selectRideSheet);
          if (context.canPop()) {
            context.pop();
          }
        } else {
          _pickupFocusNode.requestFocus();
          ref.read(enterRouteProvider.notifier).onSearchQueryChanged('');
        }
      }
    } finally {
      _selecting = false;
    }
  }

  Future<void> _onSavedLocationTap(SavedLocationEntity location) async {
    final generation = ++_selectionGeneration;
    ref.read(enterRouteProvider.notifier).abandonSearch();
    ref.read(rideRoomProvider.notifier).clearError();
    ref.read(carpoolProvider.notifier).clearError();
    final latLng = LatLng(location.lat, location.lng);
    final name = location.formattedAddress;
    final purpose = _activeField == RouteField.pickup
        ? RideLocationType.pickup
        : RideLocationType.dropoff;

    await ref
        .read(enterRouteProvider.notifier)
        .saveFromSelection(
          fullAddress: name,
          latitude: location.lat,
          longitude: location.lng,
          type: purpose,
        );
    if (!mounted || generation != _selectionGeneration) return;

    if (purpose == RideLocationType.pickup) {
      _pickupController.text = name;
      await updatePickup(coordinates: latLng, name: name);
      if (!mounted || generation != _selectionGeneration) return;
      final mapState = ref.read(mapProvider).value;
      final bool hasValidDropOff =
          mapState?.dropOff != null &&
          (mapState?.dropOff?.name.trim().isNotEmpty ?? false) &&
          _dropOffController.text.trim().isNotEmpty;
      if (hasValidDropOff) {
        ref
            .read(rideRoomProvider.notifier)
            .updateCurrentSheet(RideSheetsType.selectRideSheet);
        if (context.canPop()) {
          context.pop();
        }
      } else {
        _dropOffFocusNode.requestFocus();
        ref.read(enterRouteProvider.notifier).onSearchQueryChanged('');
      }
    } else {
      _dropOffController.text = name;
      await updateDropOff(coordinates: latLng, name: name);
      if (!mounted || generation != _selectionGeneration) return;
      final mapState = ref.read(mapProvider).value;
      final bool hasValidPickup =
          mapState?.pickup != null &&
          (mapState?.pickup?.name.trim().isNotEmpty ?? false) &&
          _pickupController.text.trim().isNotEmpty;
      if (hasValidPickup) {
        ref
            .read(rideRoomProvider.notifier)
            .updateCurrentSheet(RideSheetsType.selectRideSheet);
        if (context.canPop()) {
          context.pop();
        }
      } else {
        _pickupFocusNode.requestFocus();
        ref.read(enterRouteProvider.notifier).onSearchQueryChanged('');
      }
    }
  }

  Future<void> _swapPickupAndDropoff() async {
    _selectionGeneration++;
    ref.read(enterRouteProvider.notifier).abandonSearch();
    final mapState = ref.read(mapProvider).value;
    final currentPickup = mapState?.pickup;
    final currentDropoff = mapState?.dropOff;

    final tempPickupText = _pickupController.text;
    final tempDropoffText = _dropOffController.text;

    setState(() {
      _pickupController.text = tempDropoffText;
      _dropOffController.text = tempPickupText;
    });

    if (currentDropoff != null) {
      await updatePickup(
        coordinates: currentDropoff.latLng,
        name: currentDropoff.name,
        resolvedPlace: currentDropoff.resolvedPlace,
        city: currentDropoff.city,
      );
    } else {
      ref.read(mapProvider.notifier).clearPickupLocation();
    }
    if (currentPickup != null) {
      await updateDropOff(
        coordinates: currentPickup.latLng,
        name: currentPickup.name,
        resolvedPlace: currentPickup.resolvedPlace,
        city: currentPickup.city,
      );
    } else {
      ref.read(mapProvider.notifier).clearDropOffLocation();
    }
  }

  Future<void> _openAddLocationSheet({Object? location}) async {
    Address? initialAddress;
    String? locationName;
    String? locationAddress;

    if (location != null) {
      final purpose = _activeField == RouteField.pickup
          ? RideLocationType.pickup
          : RideLocationType.dropoff;
      final resolved = await ref
          .read(enterRouteProvider.notifier)
          .resolveSelectedLocation(location: location, type: purpose);
      if (!mounted) return;

      if (resolved == null) return;
      final selected = resolved;
      initialAddress = _buildAddressFromLocation(selected);
      locationName = selected.name;
      locationAddress = selected.address;
    }

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLocationSheet(
        locationName: locationName,
        locationAddress: locationAddress,
        initialAddress: initialAddress,
      ),
    );

    if (!mounted) return;
    if (result == 'added') {
      await showDialog(
        context: context,
        builder: (_) => GradientSideDialog(
          title: context.l10n.location_updated,
          subtitle: context.l10n.location_subtitle,
          icon: Icons.check_circle,
        ),
      );
    }
  }

  Address _buildAddressFromLocation(LocationEntity location) {
    if (location.resolvedPlace != null) {
      return Address.fromResolvedPlace(location.resolvedPlace!);
    }
    final parts = location.address
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final country = parts.isNotEmpty ? parts.last : '';
    final state = parts.length > 1 ? parts[parts.length - 2] : '';
    final city = parts.length > 2 ? parts[parts.length - 3] : location.name;

    return Address(
      latitiude: location.latitude,
      longitude: location.longitude,
      country: country,
      state: state,
      city: city,
      zipCode: '',
      countryCode: country.length >= 2
          ? country.substring(0, 2).toUpperCase()
          : '',
      formattedAddress: location.address,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _handleBackPressed,
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
        ),
        title: Text(
          l10n.enter_route,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppButton(
            text: l10n.confirm_route,
            backgroundColor: colors.brand,
            fontColor: colors.button,
            onPressed: _confirmSelection,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Route Input Card
          _buildRouteInputsCard(context, l10n, colors),

          // "Choose on Map" action tile
          _buildChooseOnMapTile(context, l10n, colors),

          const SizedBox(height: 8),

          // Scrollable results (isolated Consumer scope for fast typing without full screen rebuilds)
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final routeState = ref.watch(enterRouteProvider);
                final savedLocations = ref
                    .watch(savedLocationsProvider)
                    .locations;

                if (routeState.isSearching) {
                  return _buildSearchResults(context, routeState, l10n, colors);
                }

                return _buildRecentsAndSaved(
                  context,
                  routeState,
                  savedLocations,
                  l10n,
                  colors,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInputsCard(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeColors colors,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.fieldFill.withValues(alpha: context.isDark ? 0.9 : 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Visual path indicators (Green dot -> line -> Brand dot)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981), // Emerald green
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 38,
                color: colors.border.withValues(alpha: 0.8),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.brand,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Fields
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pickup input
                _buildRouteTextField(
                  context: context,
                  controller: _pickupController,
                  focusNode: _pickupFocusNode,
                  hintText: l10n.where_from,
                  isActive: _activeField == RouteField.pickup,
                  onTap: () => _setActiveField(RouteField.pickup),
                  onChanged: (value) {
                    _selectionGeneration++;
                    ref
                        .read(mapProvider.notifier)
                        .clearPickupLocation(resetPromo: value.trim().isEmpty);
                    ref
                        .read(enterRouteProvider.notifier)
                        .onSearchQueryChanged(
                          value,
                          type: RideLocationType.pickup,
                        );
                  },
                  onClear: () {
                    _pickupController.clear();
                    ref.read(mapProvider.notifier).clearPickupLocation();
                    _pickupFocusNode.requestFocus();
                    ref
                        .read(enterRouteProvider.notifier)
                        .onSearchQueryChanged('');
                  },
                ),
                Divider(
                  height: 16,
                  thickness: 1,
                  color: colors.border.withValues(alpha: 0.5),
                ),
                // Dropoff input
                _buildRouteTextField(
                  context: context,
                  controller: _dropOffController,
                  focusNode: _dropOffFocusNode,
                  hintText: l10n.where_to,
                  isActive: _activeField == RouteField.dropoff,
                  onTap: () => _setActiveField(RouteField.dropoff),
                  onChanged: (value) {
                    _selectionGeneration++;
                    ref.read(mapProvider.notifier).clearDropOffLocation();
                    final pickupOrigin = ref
                        .read(mapProvider)
                        .value
                        ?.pickup
                        ?.latLng;
                    ref
                        .read(enterRouteProvider.notifier)
                        .onSearchQueryChanged(
                          value,
                          origin: pickupOrigin,
                          type: RideLocationType.dropoff,
                        );
                  },
                  onClear: () {
                    _dropOffController.clear();
                    ref.read(mapProvider.notifier).clearDropOffLocation();
                    _dropOffFocusNode.requestFocus();
                    ref
                        .read(enterRouteProvider.notifier)
                        .onSearchQueryChanged('');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Swap button
          IconButton(
            onPressed: _swapPickupAndDropoff,
            icon: Icon(Icons.swap_vert_rounded, color: colors.brand, size: 24),
            tooltip: 'Swap locations',
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTextField({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool isActive,
    required VoidCallback onTap,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onTap: onTap,
            onChanged: onChanged,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              hintText: hintText,
              hintStyle: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
        if (controller.text.isNotEmpty)
          IconButton(
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            padding: EdgeInsets.zero,
            onPressed: onClear,
            icon: Icon(Icons.cancel, size: 16, color: colors.textSecondary),
          ),
      ],
    );
  }

  Widget _buildChooseOnMapTile(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeColors colors,
  ) {
    final isPickup = _activeField == RouteField.pickup;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colors.fieldFill.withValues(alpha: context.isDark ? 0.8 : 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openMapPicker(forPickup: isPickup),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.map_rounded, color: colors.brand, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.choose_on_map,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPickup ? l10n.pickup : l10n.dropoff,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    EnterRouteState routeState,
    AppLocalizations l10n,
    AppThemeColors colors,
  ) {
    if (routeState.isLoading ||
        routeState.isFetchingSuggestions ||
        routeState.isResolvingSelection) {
      return const Center(child: CircularProgressIndicator());
    }

    if (routeState.searchError != null) {
      return Center(
        child: AddressSearchError(
          failure: routeState.searchError!,
          onRetry: () => _onLocationItemTap(Object(), retry: true),
        ),
      );
    }
    final searchResults = routeState.searchResults;
    if (searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.we_couldnot_found,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: searchResults.length + 1,
      separatorBuilder: (_, __) => const Divider(height: AppSizes.p20),
      itemBuilder: (context, index) {
        if (index == searchResults.length) {
          return const Text('Google Maps', textAlign: TextAlign.end);
        }
        final location = searchResults[index];
        return _buildLocationItem(
          context: context,
          location: location,
          colors: colors,
        );
      },
    );
  }

  Widget _buildRecentsAndSaved(
    BuildContext context,
    EnterRouteState routeState,
    List<SavedLocationEntity> savedLocations,
    AppLocalizations l10n,
    AppThemeColors colors,
  ) {
    final recents = routeState.recents;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (savedLocations.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.saved_locations,
              style: context.textTheme.titleSmall,
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: savedLocations.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => _onSavedLocationTap(type),
                      child: AppGradientBox(
                        cornerRadius: 16,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: context.screenWidth * 0.4,
                          ),
                          child: Text(
                            type.name.capitalised,
                            style: context.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: AppSizes.p20),
          ),
        ],
        if (recents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              l10n.recent_locations,
              style: context.textTheme.titleSmall,
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recents.length,
            separatorBuilder: (_, __) => const Divider(height: AppSizes.p20),
            itemBuilder: (context, index) {
              final location = recents[index];
              return _buildLocationItem(
                context: context,
                location: location,
                colors: colors,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLocationItem({
    required BuildContext context,
    required Object location,
    required AppThemeColors colors,
  }) {
    final name = location is PlaceSuggestion
        ? (location.primaryText.isEmpty ? location.label : location.primaryText)
        : (location as LocationEntity).name;
    final address = location is PlaceSuggestion
        ? location.label
        : (location as LocationEntity).address;
    return Row(
      children: [
        Image.asset(
          AppIcons.locationFill,
          width: context.screenHeight * 0.024,
          height: context.screenHeight * 0.024,
        ),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: CustomTap.noEffect(
            onTap: () => _onLocationItemTap(location),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        CustomTap(
          onTap: () => _openAddLocationSheet(location: location),
          padding: 10,
          child: Image.asset(
            AppIcons.heart,
            width: context.screenHeight * 0.020,
            height: context.screenHeight * 0.020,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
