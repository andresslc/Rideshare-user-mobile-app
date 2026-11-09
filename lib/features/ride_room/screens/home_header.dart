// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'package:ride_app/core/navigation/routes.dart';
// import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
// import 'package:ride_app/features/ride_room/presentation/providers/enter_route_provider.dart';
// import 'package:ride_app/shared/models/selected_location.dart';
// import 'package:flutter/material.dart';

// import 'package:ride_app/core/extensions/context_extension.dart';
// import 'package:ride_app/core/extensions/theme_extension.dart';
// import 'package:ride_app/shared/widgets/app_text_field.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';

// import '../../../../../shared/widgets/circular_profile.dart';
// import '../../../core/theme/app_colors.dart';
// import '../../../shared/widgets/app_gradient_box.dart';

// class EnterRouteHeaderComponent extends ConsumerStatefulWidget {
//   final TextEditingController pickupController;
//   final TextEditingController dropOffController;
//   const EnterRouteHeaderComponent({
//     super.key,
//     required this.pickupController,
//     required this.dropOffController,
//   });

//   @override
//   ConsumerState<EnterRouteHeaderComponent> createState() =>
//       _EnterRouteHeaderComponentState();
// }

// class _EnterRouteHeaderComponentState
//     extends ConsumerState<EnterRouteHeaderComponent> {
//   RideLocationType _activeType = RideLocationType.dropoff;

//   Future<void> _openMapPicker({required bool forPickup}) async {
//     _activeType = forPickup
//         ? RideLocationType.pickup
//         : RideLocationType.dropoff;
//     final selected = await context.pushNamed<Address>(Routes.placePicker.name);
//     if (!mounted || selected == null) return;
//     final value = selected.formattedAddress.trim();
//     if (value.isEmpty) return;
//     setState(() {
//       if (forPickup) {
//         widget.pickupController.text = value;
//       } else {
//         widget.dropOffController.text = value;
//       }
//     });

//     await ref
//         .read(enterRouteProvider.notifier)
//         .saveFromSelection(
//           fullAddress: value,
//           latitude: selected.latitiude,
//           longitude: selected.longitude,
//           type: _activeType,
//         );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final colors = context.appColors;

//     return AnimatedContainer(
//       duration: const Duration(seconds: 5),
//       curve: Curves.easeInOut,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 14,
//         vertical: 10,
//       ).copyWith(bottom: 14, top: 10),
//       decoration: const BoxDecoration(
//         gradient: AppColors.darkBackgroundGradient,
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(12),
//           bottomRight: Radius.circular(12),
//         ),
//       ),
//       child: SafeArea(
//         bottom: false,
//         child: AppGradientBox(
//           radius: 24,
//           padding: const EdgeInsets.all(14),
//           child: Column(
//             children: [
//               AppTextField(
//                 controller: widget.pickupController,
//                 hintText: l10n.pickup_location,
//                 readOnly: true,
//                 onTap: () => _openMapPicker(forPickup: true),
//                 prefixIcon: AppIcons.search,
//                 suffixIcon: IconButton(
//                   onPressed: () => _openMapPicker(forPickup: true),
//                   icon: Icon(Icons.location_on, color: colors.brand),
//                 ),
//               ),
//               const SizedBox(height: AppSizes.p12),
//               AppTextField(
//                 controller: widget.dropOffController,
//                 hintText: l10n.dropoff_location,
//                 readOnly: true,
//                 onTap: () => _openMapPicker(forPickup: false),
//                 prefixIcon: AppIcons.search,
//                 suffixIcon: IconButton(
//                   onPressed: () => _openMapPicker(forPickup: false),
//                   icon: Icon(Icons.location_on, color: colors.brand),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//     super.debugFillProperties(properties);
//     properties.add(
//       DiagnosticsProperty<TextEditingController>(
//         '_dropOffController',
//         widget.dropOffController,
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:topx/core/extensions/text_style_extension.dart';
// // import 'package:topx/core/theme/app_colors.dart';
// // import 'package:topx/features/user/presentation/bloc/user_bloc.dart';
// // import '../../../../../shared/widgets/circular_profile.dart';

// // class EnterRouteHeaderComponent extends StatelessWidget {
// //   const HomeHeaderComponent({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return ColoredBox(
// //       color: Colors.transparent, // ✅ ensure fully transparent
// //       child: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [Colors.black54, Colors.transparent, Colors.black38],
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //           ),
// //           borderRadius: BorderRadius.only(
// //             bottomLeft: Radius.circular(12),
// //             bottomRight: Radius.circular(12),
// //           ),
// //         ),
// //         padding: const EdgeInsets.symmetric(
// //           horizontal: 14,
// //           vertical: 10,
// //         ).copyWith(bottom: 14, top: 10),
// //         child: SafeArea(
// //           bottom: false,
// //           child: Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             crossAxisAlignment: CrossAxisAlignment.center,
// //             children: [
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const SizedBox(height: 10),
// //                     BlocSelector<UserBloc, UserState, String>(
// //                       selector: (state) => state.userEntity.name,
// //                       builder: (context, name) {
// //                         return Text(
// //                           "Hello, $name",
// //                           style: context.labelLarge?.copyWith(
// //                             color: AppColors.white,
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                     const SizedBox(height: 10),
// //                     Text(
// //                       "Welcome to TopX",
// //                       style: context.titleLarge?.copyWith(
// //                         color: AppColors.white,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               BlocSelector<
// //                 UserBloc,
// //                 UserState,
// //                 ({String profilePicture, String name})
// //               >(
// //                 selector: (state) => (
// //                   profilePicture: state.userEntity.profilePicture,
// //                   name: state.userEntity.name,
// //                 ),
// //                 builder: (context, state) {
// //                   return Container(
// //                     decoration: BoxDecoration(
// //                       shape: BoxShape.circle,
// //                       color: AppColors.white.withValues(alpha: 0.37),
// //                     ),
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(3.0),
// //                       child: CircularProfile(
// //                         image: state.profilePicture,
// //                         size: 53,
// //                         name: state.name,
// //                         showInitials: true,
// //                       ),
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
