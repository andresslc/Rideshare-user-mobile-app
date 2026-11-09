// import 'package:ride_app/core/core.dart';
// import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
// import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
// import 'package:ride_app/features/ride_room/presentation/states/map_state.dart';
// import 'package:ride_app/features/ride_room/screens/drag_handler.dart';
// import 'package:ride_app/features/settings/presentation/providers/saved_locations_provider.dart';
// import 'package:ride_app/features/settings/presentation/screens/add_to_location_sheet.dart';
// import 'package:ride_app/shared/models/selected_location.dart';
// import 'package:ride_app/shared/widgets/custom_tap.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// import '../../../core/constants/app_icons.dart';
// import '../../../shared/widgets/app_gradient_box.dart';
// import '../../../shared/widgets/app_text_field.dart';
// import '../../../shared/widgets/custom_dialogue.dart';
// import '../../../shared/widgets/plain_background_widget.dart';
// import '../domain/entities/location_entity.dart';
// import '../enums/ride_enum.dart';
// import '../presentation/providers/enter_route_provider.dart';

// class WhereToGoSheet extends ConsumerStatefulWidget {
//   const WhereToGoSheet({super.key});

//   @override
//   ConsumerState<WhereToGoSheet> createState() => _WhereToGoSheetState();
// }

// class _WhereToGoSheetState extends ConsumerState<WhereToGoSheet> {
//   static const double _initialChildSizeCap = 0.5;
//   static const double _maxSheetChildSize = 0.9;
//   static const double _fallbackInitialChildSize = 0.3;
//   static const double _floatingCurrentLocationTopOffset = 75; // 60
//   static const double _sheetSizeEpsilon = 0.001;
//   final DraggableScrollableController _sheetController =
//       DraggableScrollableController();
//   final GlobalKey _sheetContentKey = GlobalKey();

//   double _initialChildSize = _fallbackInitialChildSize;
//   double _maxChildSize = _fallbackInitialChildSize;
//   bool _contentExceedsMaxHeight = false;
//   bool _hasAppliedMeasuredSize = false;

//   @override
//   void initState() {
//     super.initState();

//     final savedLocations = ref.read(savedLocationsProvider).locations;
//     final recentLocations = ref.read(enterRouteProvider).listToRender;

//     if (recentLocations.isEmpty) {
//       Future.microtask(() {
//         ref.read(enterRouteProvider.notifier).initialize();
//       });
//     }
//     if (savedLocations.isEmpty) {
//       Future.microtask(() {
//         ref.read(savedLocationsProvider.notifier).fetchSavedLocations();
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _sheetController.dispose();
//     super.dispose();
//   }

//   Future<void> _onLocationItemTap({
//     required LatLng coordinates,
//     String? name,
//   }) async {
//     final mapState = ref.read(mapProvider).value;
//     final hasPromo = mapState?.hasAppliedPromoCode ?? false;
//     if (hasPromo) {
//       context.showPromoRemovalWarning(onConfirm: () async {
//         ref.read(mapProvider.notifier).clearPromoCode();
//         await ref
//             .read(mapProvider.notifier)
//             .setDropOffLocation(
//               coordinates,
//               name: name,
//               resolveNameIfMissing: true,
//             );
//         ref
//             .read(rideRoomProvider.notifier)
//             .updateCurrentSheet(RideSheetsType.selectRideSheet);
//       });
//     } else {
//       await ref
//           .read(mapProvider.notifier)
//           .setDropOffLocation(
//             coordinates,
//             name: name,
//             resolveNameIfMissing: true,
//           );
//       ref
//           .read(rideRoomProvider.notifier)
//           .updateCurrentSheet(RideSheetsType.selectRideSheet);
//     }
//   }

//   Future<void> _onSavedLocationTap({
//     required double lat,
//     required double lng,
//     required String address,
//   }) async {
//     await _onLocationItemTap(coordinates: LatLng(lat, lng), name: address);
//   }

//   void _scheduleSheetMeasurement(BuildContext context) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;

//       final contentContext = _sheetContentKey.currentContext;
//       if (contentContext == null) return;

//       final renderObject = contentContext.findRenderObject();
//       if (renderObject is! RenderBox || !renderObject.hasSize) return;

//       final screenHeight = MediaQuery.sizeOf(context).height;
//       if (screenHeight <= 0) return;

//       final totalSheetHeight =
//           renderObject.size.height + _floatingCurrentLocationTopOffset;
//       final measuredChildSize = (totalSheetHeight / screenHeight)
//           .clamp(_sheetSizeEpsilon, _maxSheetChildSize)
//           .toDouble();
//       final nextInitialChildSize = measuredChildSize
//           .clamp(_sheetSizeEpsilon, _initialChildSizeCap)
//           .toDouble();
//       final nextMaxChildSize = measuredChildSize;
//       final nextContentExceedsMaxHeight =
//           totalSheetHeight >
//           (screenHeight * _maxSheetChildSize) + _sheetSizeEpsilon;

//       final initialChildSizeChanged =
//           (_initialChildSize - nextInitialChildSize).abs() > _sheetSizeEpsilon;
//       final maxChildSizeChanged =
//           (_maxChildSize - nextMaxChildSize).abs() > _sheetSizeEpsilon;
//       final scrollabilityChanged =
//           _contentExceedsMaxHeight != nextContentExceedsMaxHeight;

//       if (!initialChildSizeChanged &&
//           !maxChildSizeChanged &&
//           !scrollabilityChanged) {
//         return;
//       }

//       final previousInitialChildSize = _initialChildSize;
//       _initialChildSize = nextInitialChildSize;
//       _maxChildSize = nextMaxChildSize;
//       _contentExceedsMaxHeight = nextContentExceedsMaxHeight;

//       if (mounted) {
//         setState(() {});
//       }

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted || !_sheetController.isAttached) return;

//         final currentSize = _sheetController.size;
//         final wasAtPreviousMin =
//             (currentSize - previousInitialChildSize).abs() <= _sheetSizeEpsilon;

//         double targetSize = currentSize
//             .clamp(_initialChildSize, _maxChildSize)
//             .toDouble();
//         if (!_hasAppliedMeasuredSize || wasAtPreviousMin) {
//           targetSize = _initialChildSize;
//         }

//         _hasAppliedMeasuredSize = true;

//         if ((targetSize - currentSize).abs() > _sheetSizeEpsilon) {
//           _sheetController.jumpTo(targetSize);
//         }
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_hasAppliedMeasuredSize) {
//       _scheduleSheetMeasurement(context);
//     }

//     ref.listen<AsyncValue<MapState>>(mapProvider, (previous, next) {
//       final previousType = previous?.asData?.value.locationDialogType;
//       final current = next.asData?.value;
//       if (current == null) return;
//       if (current.locationDialogType == LocationDialogType.none) return;
//       if (current.locationDialogType == previousType) return;

//       WidgetsBinding.instance.addPostFrameCallback((_) async {
//         if (!mounted) return;
//         await _showLocationDialog(current.locationDialogType);
//       });
//     });

//     return DraggableScrollableSheet(
//       expand: false,
//       initialChildSize: _initialChildSize,
//       minChildSize: _initialChildSize,
//       maxChildSize: _maxChildSize,
//       snap: _initialChildSize < _maxChildSize,
//       controller: _sheetController,
//       snapSizes: _initialChildSize < _maxChildSize
//           ? [_initialChildSize, _maxChildSize]
//           : null,
//       builder: (context, controller) {
//         final mapAsync = ref.watch(mapProvider);
//         final bool isLoadingCurrentLocation =
//             mapAsync.asData?.value.isLoadingLocation ?? false;
//         final colors = context.appColors;
//         final l10 = context.l10n;
//         const hp = EdgeInsets.symmetric(horizontal: 16, vertical: 16);

//         return Stack(
//           children: [
//             Positioned.fill(
//               top: _floatingCurrentLocationTopOffset,
//               child: PlainBackgroundWidget(
//                 child: ListView(
//                   controller: controller,
//                   physics:
//                       (_initialChildSize < _maxChildSize ||
//                           _contentExceedsMaxHeight)
//                       ? const ClampingScrollPhysics()
//                       : const NeverScrollableScrollPhysics(),
//                   padding: EdgeInsets.zero,
//                   children: [
//                     Column(
//                       key: _sheetContentKey,
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         DragHandlerWidget(
//                           controller: _sheetController,
//                           minChildSize: _initialChildSize,
//                           maxChildSize: _maxChildSize,
//                         ),
//                         GestureDetector(
//                               behavior: HitTestBehavior.translucent,
//                               onVerticalDragUpdate: (details) {
//                                 final height = MediaQuery.sizeOf(
//                                   context,
//                                 ).height;

//                                 final newSize =
//                                     _sheetController.size -
//                                     (details.primaryDelta! / height);

//                                 _sheetController.jumpTo(
//                                   newSize
//                                       .clamp(_initialChildSize, _maxChildSize)
//                                       .toDouble(),
//                                 );
//                               },
//                               child: Padding(
//                                 padding: hp,
//                                 child: AppTextField(
//                                   hintText: l10.where_to,
//                                   readOnly: true,
//                                   onTap: whereToGoTap,
//                                   prefixIcon: AppIcons.search,
//                                   validator: Validators.requiredFieldValidator,
//                                 ),
//                               ),
//                             )
//                             .animate()
//                             .fadeIn(duration: 400.ms)
//                             .slideY(begin: 0.2, end: 0),
//                         _sheetContent(),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 16,
//               right: 12,
//               child: _buildMyLocationButton(
//                 context,
//                 isLoadingCurrentLocation,
//                 colors,
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildMyLocationButton(
//     BuildContext context,
//     bool isLoading,
//     AppThemeColors colors,
//   ) {
//     return Container(
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: colors.brand.withValues(alpha: 0.3),
//                 blurRadius: 12,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: IconButton(
//             onPressed: isLoading
//                 ? null
//                 : () async {
//                     await ref
//                         .read(mapProvider.notifier)
//                         .refreshCurrentLocation(moveCamera: true);
//                     // await ref
//                     //     .read(rideRoomProvider.notifier)
//                     //     .sendCurrentLocation();
//                   },
//             icon: isLoading
//                 ? SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: colors.brand,
//                     ),
//                   )
//                 : Image.asset(
//                     AppIcons.myLocation,
//                     width: 24,
//                     height: 24,
//                     color: Colors.white,
//                   ),
//             style: IconButton.styleFrom(
//               backgroundColor: colors.brand,
//               side: BorderSide(color: colors.border.withOpacity(0.5)),
//               shape: const CircleBorder(),
//               padding: const EdgeInsets.all(12),
//             ),
//           ),
//         )
//         .animate(target: isLoading ? 0 : 1)
//         .scale(
//           begin: const Offset(0.8, 0.8),
//           end: const Offset(1, 1),
//           curve: Curves.elasticOut,
//           duration: 600.ms,
//         );
//   }

//   // ---------------- UI PARTS ----------------

//   Future<void> whereToGoTap() async {
//     context.pushNamed(Routes.enterRoute.name);

//     // await Navigator.of(
//     //   context,
//     // ).push(MaterialPageRoute(builder: (_) => const EnterRouteScreen()));
//   }

//   Widget _sheetContent() {
//     // final recentLocations = ref.watch(enterRouteProvider).listToRender;
//     // final hasRecent = ref.watch(enterRouteProvider).hasRecents;

//     final l10 = context.l10n;
//     const hp = EdgeInsets.symmetric(horizontal: 16);
//     final colors = context.appColors;
//     // final listTitle = hasRecent ? 'Recent Locations' : 'Popular Nearby';
//     return SafeArea(
//       top: false,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Consumer(
//             builder: (context, ref, child) {
//               final locations = ref.watch(savedLocationsProvider).locations;
//               if (locations.isEmpty) return const SizedBox.shrink();
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: hp,
//                     child: Text(
//                       l10.saved_locations,
//                       style: context.textTheme.titleSmall,
//                       textAlign: TextAlign.start,
//                     ),
//                   ),
//                   const SizedBox(height: AppSizes.p12),
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                       child: Row(
//                         // spacing: 10,

//                         // runSpacing: 10,
//                         children: locations.map((type) {
//                           return Padding(
//                                 padding: const EdgeInsets.only(right: 8.0),
//                                 child: GestureDetector(
//                                   onTap: () => _onSavedLocationTap(
//                                     lat: type.lat,
//                                     lng: type.lng,
//                                     address: type.formattedAddress,
//                                   ),
//                                   child: AppGradientBox(
//                                     cornerRadius: 16,
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 14,
//                                       vertical: 8,
//                                     ),
//                                     child: Container(
//                                       constraints: BoxConstraints(
//                                         maxWidth: context.screenWidth * 0.4,
//                                       ),
//                                       child: Text(
//                                         type.name.capitalised,
//                                         style: context.textTheme.bodyMedium,
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               )
//                               .animate()
//                               .fadeIn(delay: 100.ms)
//                               .slideX(begin: 0.1, end: 0);
//                         }).toList(),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: AppSizes.p8),
//                   const Divider(height: AppSizes.p20),
//                 ],
//               );
//             },
//           ),

//           Consumer(
//             builder: (context, ref, child) {
//               final routeState = ref.watch(enterRouteProvider);
//               final recentLocations = routeState.listToRender;
//               if (routeState.isLoading) {
//                 return const Padding(
//                   padding: EdgeInsets.symmetric(vertical: 24),
//                   child: Center(child: CircularProgressIndicator()),
//                 );
//               }
//               if (recentLocations.isEmpty) {
//                 return const SizedBox.shrink();
//               }
//               return ListView.separated(
//                 shrinkWrap: true,

//                 padding: const EdgeInsets.all(
//                   0,
//                 ).copyWith(bottom: 30, left: 16, right: 16),
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: recentLocations.length,
//                 separatorBuilder: (_, index) =>
//                     const Divider(height: AppSizes.p20),
//                 itemBuilder: (context, index) {
//                   final location = recentLocations[index];
//                   return Row(
//                         children: [
//                           Image.asset(
//                             AppIcons.locationFill,
//                             width: context.screenHeight * 0.024,
//                             height: context.screenHeight * 0.024,
//                           ),
//                           const SizedBox(width: AppSizes.p12),
//                           Expanded(
//                             child: CustomTap.noEffect(
//                               onTap: () => _onLocationItemTap(
//                                 coordinates: LatLng(
//                                   location.latitude,
//                                   location.longitude,
//                                 ),
//                                 name: location.name,
//                               ),

//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     location.name,
//                                     style: context.textTheme.titleSmall,
//                                   ),
//                                   const SizedBox(height: 2),
//                                   Text(
//                                     location.address,
//                                     style: context.textTheme.bodySmall
//                                         ?.copyWith(color: colors.textSecondary),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           CustomTap(
//                             onTap: () =>
//                                 _openAddLocationSheet(location: location),
//                             padding: 10,
//                             child: Image.asset(
//                               AppIcons.heart,
//                               width: context.screenHeight * 0.020,
//                               height: context.screenHeight * 0.020,
//                               color: context.appColors.textPrimary,
//                             ),
//                           ),
//                         ],
//                       )
//                       .animate()
//                       .fadeIn(delay: (50 * index).ms)
//                       .slideX(begin: 0.05, end: 0);
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _openAddLocationSheet({LocationEntity? location}) async {
//     Address? initialAddress;
//     String? locationName;
//     String? locationAddress;

//     if (location != null) {
//       final resolved = await ref
//           .read(enterRouteProvider.notifier)
//           .resolveSelectedLocation(
//             location: location,
//             type: RideLocationType.dropoff,
//           );
//       if (!mounted) return;

//       final selected = resolved ?? location;
//       final parsedAddress = _buildAddressFromLocation(selected);
//       initialAddress = parsedAddress;
//       locationName = selected.name;
//       locationAddress = selected.address;
//     }

//     final result = await showModalBottomSheet<String>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => AddLocationSheet(
//         locationName: locationName,
//         locationAddress: locationAddress,
//         initialAddress: initialAddress,
//       ),
//     );

//     if (!mounted) return;
//     if (result == 'added') {
//       showDialog(
//         context: context,
//         builder: (_) => GradientSideDialog(
//           title: context.l10n.location_updated,
//           subtitle: context.l10n.location_subtitle,
//           icon: Icons.check_circle,
//         ),
//       );
//     }
//   }

//   Future<void> _showLocationDialog(LocationDialogType type) async {
//     final l10n = context.l10n;

//     switch (type) {
//       case LocationDialogType.permissionDenied:
//         await showDialog<void>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text(l10n.location_permission_title),
//             content: Text(l10n.permission_denied_mesg),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   ref.read(mapProvider.notifier).clearLocationDialog();
//                 },
//                 child: Text(l10n.cancel),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   Navigator.of(context).pop();
//                   ref.read(mapProvider.notifier).clearLocationDialog();
//                   await ref
//                       .read(mapProvider.notifier)
//                       .refreshCurrentLocation(moveCamera: true);
//                 },
//                 child: Text(l10n.try_again),
//               ),
//             ],
//           ),
//         );
//         break;
//       case LocationDialogType.permissionPermanentlyDenied:
//         await showDialog<void>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text(l10n.location_permission_required_title),
//             content: Text(l10n.permanently_denied_mesg),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   ref.read(mapProvider.notifier).clearLocationDialog();
//                 },
//                 child: Text(l10n.cancel),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   Navigator.of(context).pop();
//                   ref.read(mapProvider.notifier).clearLocationDialog();
//                   await ref.read(mapProvider.notifier).openLocationSettings();
//                 },
//                 child: Text(l10n.open_settings),
//               ),
//             ],
//           ),
//         );
//         break;
//       case LocationDialogType.serviceDisabled:
//         await showDialog<void>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text(l10n.location_services_disabled_title),
//             content: Text(l10n.location_services_disabled_mesg),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   ref.read(mapProvider.notifier).clearLocationDialog();
//                 },
//                 child: Text(l10n.ok),
//               ),
//             ],
//           ),
//         );
//         break;
//       case LocationDialogType.outsideServiceRegion:
//         final regionName = ref
//             .read(mapProvider.notifier)
//             .activeRegion
//             .displayName;
//         await showDialog<void>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text(l10n.outside_service_region),
//             content: Text(l10n.outside_service_region_message(regionName)),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   ref.read(mapProvider.notifier).clearLocationDialog();
//                 },
//                 child: Text(l10n.ok),
//               ),
//             ],
//           ),
//         );
//         break;
//       case LocationDialogType.error:
//         context.showErrorToast(l10n.error_occurred);
//         ref.read(mapProvider.notifier).clearLocationDialog();
//         break;
//       case LocationDialogType.none:
//         break;
//     }
//   }

//   Address _buildAddressFromLocation(LocationEntity location) {
//     final parts = location.address
//         .split(',')
//         .map((item) => item.trim())
//         .where((item) => item.isNotEmpty)
//         .toList();

//     final country = parts.isNotEmpty ? parts.last : '';
//     final state = parts.length > 1 ? parts[parts.length - 2] : '';
//     final city = parts.length > 2 ? parts[parts.length - 3] : location.name;

//     return Address(
//       latitiude: location.latitude,
//       longitude: location.longitude,
//       country: country,
//       state: state,
//       city: city,
//       zipCode: '',
//       countryCode: country.length >= 2
//           ? country.substring(0, 2).toUpperCase()
//           : '',
//       formattedAddress: location.address,
//     );
//   }
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/ride_room/presentation/providers/map_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/map_state.dart';
import 'package:ride_app/features/ride_room/screens/drag_handler.dart';
import 'package:ride_app/features/settings/presentation/providers/saved_locations_provider.dart';
import 'package:ride_app/features/settings/presentation/screens/add_to_location_sheet.dart';
import 'package:ride_app/shared/models/selected_location.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';

import '../../../core/constants/app_icons.dart';
import '../../../shared/widgets/app_gradient_box.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/custom_dialogue.dart';
import '../../../shared/widgets/plain_background_widget.dart';
import '../domain/entities/location_entity.dart';
import '../enums/ride_enum.dart';
import '../presentation/providers/enter_route_provider.dart';

class WhereToGoSheet extends ConsumerStatefulWidget {
  const WhereToGoSheet({super.key});

  @override
  ConsumerState<WhereToGoSheet> createState() => _WhereToGoSheetState();
}

class _WhereToGoSheetState extends ConsumerState<WhereToGoSheet> {
  static const double _initialChildSizeCap = 0.5;
  static const double _maxSheetChildSize = 0.9;
  static const double _fallbackInitialChildSize = 0.3;
  static const double _floatingCurrentLocationTopOffset = 75; // 60
  static const double _sheetSizeEpsilon = 0.001;

  // NEW: guarantees the sheet always has *some* drag range, even when
  // measured content is short. Without this, initial == max collapses
  // the sheet into a non-draggable state.
  static const double _minDragRange = 0.12;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final GlobalKey _sheetContentKey = GlobalKey();

  double _initialChildSize = _fallbackInitialChildSize;
  double _maxChildSize = _fallbackInitialChildSize;
  bool _contentExceedsMaxHeight = false;
  bool _hasAppliedMeasuredSize = false;

  @override
  void initState() {
    super.initState();

    final savedLocations = ref.read(savedLocationsProvider).locations;

    Future.microtask(() {
      ref.read(enterRouteProvider.notifier).initialize();
    });

    if (savedLocations.isEmpty) {
      Future.microtask(() {
        ref.read(savedLocationsProvider.notifier).fetchSavedLocations();
      });
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _onLocationItemTap({
    required LatLng coordinates,
    String? name,
  }) async {
    final mapState = ref.read(mapProvider).value;
    final hasPromo = mapState?.hasAppliedPromoCode ?? false;

    Future<void> performSetDropOff() async {
      await ref
          .read(mapProvider.notifier)
          .setDropOffLocation(
            coordinates,
            name: name,
            resolveNameIfMissing: true,
          );

      final dropOffName = ref.read(mapProvider).value?.dropOff?.name ?? name;
      if (dropOffName != null && dropOffName.trim().isNotEmpty) {
        await ref
            .read(enterRouteProvider.notifier)
            .saveFromSelection(
              fullAddress: dropOffName,
              latitude: coordinates.latitude,
              longitude: coordinates.longitude,
              type: RideLocationType.dropoff,
            );
      }

      ref
          .read(rideRoomProvider.notifier)
          .updateCurrentSheet(RideSheetsType.selectRideSheet);
    }

    if (hasPromo) {
      context.showPromoRemovalWarning(
        onConfirm: () async {
          ref.read(mapProvider.notifier).clearPromoCode();
          await performSetDropOff();
        },
      );
    } else {
      await performSetDropOff();
    }
  }

  Future<void> _onSavedLocationTap({
    required double lat,
    required double lng,
    required String address,
  }) async {
    await _onLocationItemTap(coordinates: LatLng(lat, lng), name: address);
  }

  void _scheduleSheetMeasurement(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final contentContext = _sheetContentKey.currentContext;
      if (contentContext == null) return;

      final renderObject = contentContext.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;

      final mediaQuery = MediaQuery.of(context);

      // Exclude the native system navigation/gesture area
      // from the available sheet height.
      final screenHeight = mediaQuery.size.height - mediaQuery.padding.bottom;

      if (screenHeight <= 0) return;

      final totalSheetHeight =
          renderObject.size.height +
          _floatingCurrentLocationTopOffset +
          mediaQuery.padding.bottom;

      final measuredChildSize = (totalSheetHeight / screenHeight)
          .clamp(_sheetSizeEpsilon, _maxSheetChildSize)
          .toDouble();

      var nextInitialChildSize = measuredChildSize
          .clamp(_sheetSizeEpsilon, _initialChildSizeCap)
          .toDouble();

      var nextMaxChildSize = measuredChildSize;

      // Keep a small drag range even when content is short.
      if (nextMaxChildSize - nextInitialChildSize < _minDragRange) {
        nextMaxChildSize = (nextInitialChildSize + _minDragRange)
            .clamp(_sheetSizeEpsilon, _maxSheetChildSize)
            .toDouble();

        if (nextMaxChildSize - nextInitialChildSize < _minDragRange) {
          nextInitialChildSize = (nextMaxChildSize - _minDragRange)
              .clamp(_sheetSizeEpsilon, _initialChildSizeCap)
              .toDouble();
        }
      }

      final nextContentExceedsMaxHeight =
          totalSheetHeight >
          (screenHeight * _maxSheetChildSize) + _sheetSizeEpsilon;

      final initialChildSizeChanged =
          (_initialChildSize - nextInitialChildSize).abs() > _sheetSizeEpsilon;

      final maxChildSizeChanged =
          (_maxChildSize - nextMaxChildSize).abs() > _sheetSizeEpsilon;

      final scrollabilityChanged =
          _contentExceedsMaxHeight != nextContentExceedsMaxHeight;

      if (!initialChildSizeChanged &&
          !maxChildSizeChanged &&
          !scrollabilityChanged) {
        return;
      }

      final previousInitialChildSize = _initialChildSize;

      _initialChildSize = nextInitialChildSize;
      _maxChildSize = nextMaxChildSize;
      _contentExceedsMaxHeight = nextContentExceedsMaxHeight;

      if (mounted) {
        setState(() {});
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_sheetController.isAttached) return;

        final currentSize = _sheetController.size;

        final wasAtPreviousMin =
            (currentSize - previousInitialChildSize).abs() <= _sheetSizeEpsilon;

        double targetSize = currentSize
            .clamp(_initialChildSize, _maxChildSize)
            .toDouble();

        if (!_hasAppliedMeasuredSize || wasAtPreviousMin) {
          targetSize = _initialChildSize;
        }

        _hasAppliedMeasuredSize = true;

        if ((targetSize - currentSize).abs() > _sheetSizeEpsilon) {
          _sheetController.jumpTo(targetSize);
        }
      });
    });
  }
  // void _scheduleSheetMeasurement(BuildContext context) {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!mounted) return;

  //     final contentContext = _sheetContentKey.currentContext;
  //     if (contentContext == null) return;
  //     final renderObject = contentContext.findRenderObject();
  //     if (renderObject is! RenderBox || !renderObject.hasSize) return;

  //     final screenHeight = MediaQuery.sizeOf(context).height;
  //     if (screenHeight <= 0) return;

  //     final totalSheetHeight =
  //         renderObject.size.height + _floatingCurrentLocationTopOffset;
  //     final measuredChildSize = (totalSheetHeight / screenHeight)
  //         .clamp(_sheetSizeEpsilon, _maxSheetChildSize)
  //         .toDouble();

  //     var nextInitialChildSize = measuredChildSize
  //         .clamp(_sheetSizeEpsilon, _initialChildSizeCap)
  //         .toDouble();
  //     var nextMaxChildSize = measuredChildSize;

  //     // FIX (#1): never let max collapse onto initial. Force a minimum
  //     // drag range so DraggableScrollableSheet always has room to move.
  //     if (nextMaxChildSize - nextInitialChildSize < _minDragRange) {
  //       nextMaxChildSize = (nextInitialChildSize + _minDragRange)
  //           .clamp(_sheetSizeEpsilon, _maxSheetChildSize)
  //           .toDouble();

  //       // If clamping max against the ceiling ate into the range instead,
  //       // pull initial down so the range is preserved.
  //       if (nextMaxChildSize - nextInitialChildSize < _minDragRange) {
  //         nextInitialChildSize = (nextMaxChildSize - _minDragRange)
  //             .clamp(_sheetSizeEpsilon, _initialChildSizeCap)
  //             .toDouble();
  //       }
  //     }

  //     final nextContentExceedsMaxHeight =
  //         totalSheetHeight >
  //         (screenHeight * _maxSheetChildSize) + _sheetSizeEpsilon;

  //     final initialChildSizeChanged =
  //         (_initialChildSize - nextInitialChildSize).abs() > _sheetSizeEpsilon;
  //     final maxChildSizeChanged =
  //         (_maxChildSize - nextMaxChildSize).abs() > _sheetSizeEpsilon;
  //     final scrollabilityChanged =
  //         _contentExceedsMaxHeight != nextContentExceedsMaxHeight;

  //     if (!initialChildSizeChanged &&
  //         !maxChildSizeChanged &&
  //         !scrollabilityChanged) {
  //       return;
  //     }

  //     final previousInitialChildSize = _initialChildSize;
  //     _initialChildSize = nextInitialChildSize;
  //     _maxChildSize = nextMaxChildSize;
  //     _contentExceedsMaxHeight = nextContentExceedsMaxHeight;

  //     if (mounted) {
  //       setState(() {});
  //     }

  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (!mounted || !_sheetController.isAttached) return;

  //       final currentSize = _sheetController.size;
  //       final wasAtPreviousMin =
  //           (currentSize - previousInitialChildSize).abs() <= _sheetSizeEpsilon;

  //       double targetSize = currentSize
  //           .clamp(_initialChildSize, _maxChildSize)
  //           .toDouble();
  //       if (!_hasAppliedMeasuredSize || wasAtPreviousMin) {
  //         targetSize = _initialChildSize;
  //       }

  //       _hasAppliedMeasuredSize = true;

  //       if ((targetSize - currentSize).abs() > _sheetSizeEpsilon) {
  //         _sheetController.jumpTo(targetSize);
  //       }
  //     });
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    if (!_hasAppliedMeasuredSize) {
      _scheduleSheetMeasurement(context);
    }

    ref.listen<AsyncValue<MapState>>(mapProvider, (previous, next) {
      final previousType = previous?.asData?.value.locationDialogType;
      final current = next.asData?.value;
      if (current == null) return;
      if (current.locationDialogType == LocationDialogType.none) return;
      if (current.locationDialogType == previousType) return;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showLocationDialog(current.locationDialogType);
      });
    });

    // With the _minDragRange guarantee above, this is effectively always
    // true now, but keep the check for safety/clarity.
    final bool sheetIsDraggable =
        _maxChildSize - _initialChildSize > _sheetSizeEpsilon;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _initialChildSize,
      minChildSize: _initialChildSize,
      maxChildSize: _maxChildSize,
      snap: sheetIsDraggable,
      controller: _sheetController,
      snapSizes: sheetIsDraggable ? [_initialChildSize, _maxChildSize] : null,
      builder: (context, controller) {
        final mapAsync = ref.watch(mapProvider);
        final bool isLoadingCurrentLocation =
            mapAsync.asData?.value.isLoadingLocation ?? false;
        final colors = context.appColors;
        final l10 = context.l10n;
        const hp = EdgeInsets.symmetric(horizontal: 16, vertical: 16);

        return Stack(
          children: [
            Positioned.fill(
              top: _floatingCurrentLocationTopOffset,
              child: PlainBackgroundWidget(
                child: ListView(
                  controller: controller,

                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    Column(
                      key: _sheetContentKey,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DragHandlerWidget(
                          controller: _sheetController,
                          minChildSize: _initialChildSize,
                          maxChildSize: _maxChildSize,
                        ),
                        // FIX (#2): removed the manual GestureDetector that
                        // was wrapping the search field and independently
                        // calling _sheetController.jumpTo(). It was
                        // competing with the DragHandlerWidget and the
                        // native ListView-driven resize for the same
                        // vertical drag gesture, which is why dragging
                        // felt inconsistent. The ListView above (via
                        // `controller`) and DragHandlerWidget already
                        // cover resize; the search field itself should
                        // just be tappable, not draggable.
                        Padding(
                              padding: hp,
                              child: AppTextField(
                                hintText: l10.where_to,
                                readOnly: true,
                                onTap: whereToGoTap,
                                prefixIcon: AppIcons.search,
                                validator: Validators.requiredFieldValidator,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                        _sheetContent(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 12,
              child: _buildMyLocationButton(
                context,
                isLoadingCurrentLocation,
                colors,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyLocationButton(
    BuildContext context,
    bool isLoading,
    AppThemeColors colors,
  ) {
    return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.brand.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: isLoading
                ? null
                : () async {
                    await ref
                        .read(mapProvider.notifier)
                        .refreshCurrentLocation(moveCamera: true);
                    // await ref
                    //     .read(rideRoomProvider.notifier)
                    //     .sendCurrentLocation();
                  },
            icon: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.brand,
                    ),
                  )
                : Image.asset(
                    AppIcons.myLocation,
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
            style: IconButton.styleFrom(
              backgroundColor: colors.brand,
              side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
          ),
        )
        .animate(target: isLoading ? 0 : 1)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: 600.ms,
        );
  }

  // ---------------- UI PARTS ----------------

  Future<void> whereToGoTap() async {
    await context.pushNamed(
      Routes.enterRoute.name,
      extra: RideLocationType.dropoff,
    );
  }

  Widget _sheetContent() {
    final l10 = context.l10n;
    const hp = EdgeInsets.symmetric(horizontal: 16);
    final colors = context.appColors;
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, child) {
              final locations = ref.watch(savedLocationsProvider).locations;
              if (locations.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: hp,
                    child: Text(
                      l10.saved_locations,
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
                        children: locations.map((type) {
                          return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () => _onSavedLocationTap(
                                    lat: type.lat,
                                    lng: type.lng,
                                    address: type.formattedAddress,
                                  ),
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
                              )
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideX(begin: 0.1, end: 0);
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  const Divider(height: AppSizes.p20),
                ],
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final routeState = ref.watch(enterRouteProvider);
              final recentLocations = routeState.hasRecent
                  ? routeState.recents
                  : routeState.popularLocations;
              if (routeState.isLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (recentLocations.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: hp,
                    child: Text(
                      routeState.hasRecent
                          ? l10.recent_locations
                          : l10.popular_nearby,
                      style: context.textTheme.titleSmall,
                      textAlign: TextAlign.start,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(
                      0,
                    ).copyWith(bottom: 30, left: 16, right: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentLocations.length,
                    separatorBuilder: (_, index) =>
                        const Divider(height: AppSizes.p20),
                    itemBuilder: (context, index) {
                      final location = recentLocations[index];
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
                                  onTap: () => _onLocationItemTap(
                                    coordinates: LatLng(
                                      location.latitude,
                                      location.longitude,
                                    ),
                                    name: location.address.isNotEmpty
                                        ? location.address
                                        : location.name,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        location.name,
                                        style: context.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        location.address,
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
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
                                onTap: () =>
                                    _openAddLocationSheet(location: location),
                                padding: 10,
                                child: Image.asset(
                                  AppIcons.heart,
                                  width: context.screenHeight * 0.020,
                                  height: context.screenHeight * 0.020,
                                  color: context.appColors.textPrimary,
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: (50 * index).ms)
                          .slideX(begin: 0.05, end: 0);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openAddLocationSheet({LocationEntity? location}) async {
    Address? initialAddress;
    String? locationName;
    String? locationAddress;

    if (location != null) {
      final resolved = await ref
          .read(enterRouteProvider.notifier)
          .resolveSelectedLocation(
            location: location,
            type: RideLocationType.dropoff,
          );
      if (!mounted) return;

      if (resolved == null) return;
      final selected = resolved;
      final parsedAddress = _buildAddressFromLocation(selected);
      initialAddress = parsedAddress;
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
      await showDialog<void>(
        context: context,
        builder: (_) => GradientSideDialog(
          title: context.l10n.location_updated,
          subtitle: context.l10n.location_subtitle,
          icon: Icons.check_circle,
        ),
      );
    }
  }

  Future<void> _showLocationDialog(LocationDialogType type) async {
    final l10n = context.l10n;

    switch (type) {
      case LocationDialogType.permissionDenied:
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.location_permission_title),
            content: Text(l10n.permission_denied_mesg),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(mapProvider.notifier).clearLocationDialog();
                },
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  ref.read(mapProvider.notifier).clearLocationDialog();
                  await ref
                      .read(mapProvider.notifier)
                      .refreshCurrentLocation(moveCamera: true);
                },
                child: Text(l10n.try_again),
              ),
            ],
          ),
        );
        break;
      case LocationDialogType.permissionPermanentlyDenied:
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.location_permission_required_title),
            content: Text(l10n.permanently_denied_mesg),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(mapProvider.notifier).clearLocationDialog();
                },
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  ref.read(mapProvider.notifier).clearLocationDialog();
                  await ref.read(mapProvider.notifier).openLocationSettings();
                },
                child: Text(l10n.open_settings),
              ),
            ],
          ),
        );
        break;
      case LocationDialogType.serviceDisabled:
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.location_services_disabled_title),
            content: Text(l10n.location_services_disabled_mesg),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(mapProvider.notifier).clearLocationDialog();
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
        break;
      case LocationDialogType.outsideServiceRegion:
        final regionName = ref
            .read(mapProvider.notifier)
            .activeRegion
            .displayName;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.outside_service_region),
            content: Text(l10n.outside_service_region_message(regionName)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(mapProvider.notifier).clearLocationDialog();
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
        break;
      case LocationDialogType.error:
        context.showErrorToast(l10n.error_occurred);
        ref.read(mapProvider.notifier).clearLocationDialog();
        break;
      case LocationDialogType.none:
        break;
    }
  }

  Address _buildAddressFromLocation(LocationEntity location) {
    if (location.resolvedPlace != null)
      return Address.fromResolvedPlace(location.resolvedPlace!);
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
}
