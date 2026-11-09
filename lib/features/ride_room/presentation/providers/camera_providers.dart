import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Identifies the active field in route selection (pickup or dropoff).
enum RouteField { pickup, dropoff }

/// Narrow providers for the fixed-pin drag-to-select and route selection flow.
///
/// These are intentionally separate from the monolithic [mapProvider] so that
/// camera-move events (which fire on every frame during a pan gesture) only
/// rebuild the small set of widgets that actually need the live coordinate
/// (the address chip and the pin), rather than the entire screen.

/// The active route field currently focused in route selection.
final activeRouteFieldProvider = StateProvider<RouteField>((ref) => RouteField.dropoff);

/// The latest camera-center coordinate, updated on every [onCameraMove] frame.
///
/// Only the address-chip and any widget that needs the live coordinate should
/// watch this. Avoid watching from the top-level screen build.
final cameraCenterProvider = StateProvider<LatLng>((ref) => const LatLng(0, 0));

/// Whether the user is currently dragging/panning the map.
///
/// Set to `true` on [onCameraMoveStarted] and `false` on [onCameraIdle].
/// Drives the lift/drop animation of [FixedCenterPin].
final isDraggingMapProvider = StateProvider<bool>((ref) => false);

/// Field-agnostic resolved address text provider family.
final routeAddressProvider = StateProvider.family<String, RouteField>((ref, field) => '');

/// Field-agnostic reverse-geocode in progress provider family.
final isResolvingRouteAddressProvider = StateProvider.family<bool, RouteField>((ref, field) => false);

/// The resolved address text for the current map-center coordinate (pickup legacy).
final pickupAddressProvider = StateProvider<String>((ref) => '');

/// Whether a reverse-geocode is currently in progress for the pickup address (legacy).
final isResolvingPickupAddressProvider = StateProvider<bool>((ref) => false);

