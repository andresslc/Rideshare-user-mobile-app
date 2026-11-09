import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/features/card/presentation/screens/add_card_screen.dart';
import 'package:ride_app/features/card/presentation/screens/cards_screen.dart';
import 'package:ride_app/features/chat/presentation/chat_screen_args.dart';
import 'package:ride_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:ride_app/features/notification/presentation/screens/notifications_screen.dart';
import 'package:ride_app/features/reviews/presentation/screens/driver_profile_screen.dart';
import 'package:ride_app/features/reviews/presentation/screens/feed_back_screen.dart';
import 'package:ride_app/features/ride_history/presentation/screens/ride_history_screen.dart';
import 'package:ride_app/features/ride_history/presentation/screens/rider_detail_screen.dart';
import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';
import 'package:ride_app/features/ride_room/screens/carpool/available_carpool_rides_screen.dart';
import 'package:ride_app/features/ride_room/screens/carpool/carpool_ride_complete_screen.dart';
import 'package:ride_app/features/ride_room/screens/carpool/requested_carpool_screen.dart';
import 'package:ride_app/features/ride_room/screens/home_screen.dart';
import 'package:ride_app/features/settings/presentation/screens/delete_account_otp_screen.dart';
import 'package:ride_app/features/settings/presentation/screens/delete_account_verify_otp_screen.dart';
import 'package:ride_app/features/settings/presentation/screens/language_screen.dart';
import 'package:ride_app/features/settings/presentation/screens/saved_locations_screen.dart';
import 'package:ride_app/features/settings/presentation/screens/setting_screen.dart';
import 'package:ride_app/features/settings/presentation/screens/theme_preferences_screen.dart';
import 'package:ride_app/features/user_profile/presentation/screens/profile_screen.dart';
import 'package:ride_app/features/user_profile/presentation/screens/update_profile_screen.dart';
import 'package:ride_app/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:ride_app/shared/screens/location_access_screen.dart';
import 'package:ride_app/shared/screens/splash_screen.dart';
import 'package:ride_app/shared/widgets/ride_complete_screen.dart';

import '../../core/params/find_ride_params.dart';
import '../../features/auth/presentation/screens/create_profile_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/verification_screen.dart';
import '../../features/ride_history/presentation/screens/ride_detail_carpool_screen.dart';
import '../../features/ride_room/domain/entities/ride_entity.dart';
import '../../features/ride_room/screens/enter_route_screen.dart';
import '../../features/ride_room/screens/ride_place_picker_screen.dart';
import '../../shared/models/selected_location.dart';
import '../../shared/screens/place_picker_screen.dart';
import '../../shared/screens/success_screen.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// App-wide router configuration.
///
/// Add new route groups by creating separate lists and spreading them
/// into the `routes` array, just like the original app did with `part` files.
class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.root.path,
    debugLogDiagnostics: kDebugMode,
    routes: [
      // ── Splash ────────────────────────────────────────────────────
      GoRoute(
        name: Routes.root.name,
        path: Routes.root.path,
        pageBuilder: (context, state) =>
            CupertinoPage(key: state.pageKey, child: const SplashScreen()),
      ),

      // ── Auth ──────────────────────────────────────────────────────
      GoRoute(
        name: Routes.login.name,
        path: Routes.login.path,
        pageBuilder: (context, state) {
          final bool showSessionExpiredDialog = state.extra == true;
          return CupertinoPage(
            key: state.pageKey,
            child: LoginScreen(
              showSessionExpiredDialog: showSessionExpiredDialog,
            ),
          );
        },
      ),
      GoRoute(
        name: Routes.createProfile.name,
        path: Routes.createProfile.path,
        pageBuilder: (context, state) {
          final phoneNumber = state.extra as String?;
          return CupertinoPage(
            key: state.pageKey,
            child: CreateProfileScreen(phoneNumber: phoneNumber),
          );
        },
      ),
      // GoRoute(
      //   name: Routes.forgotPassword.name,
      //   path: Routes.forgotPassword.path,
      //   pageBuilder: (context, state) => CupertinoPage(
      //     key: state.pageKey,
      //     child: const ForgotPasswordScreen(),
      //   ),
      // ),
      GoRoute(
        name: Routes.verification.name,
        path: Routes.verification.path,
        pageBuilder: (context, state) {
          final phoneNumber = state.extra as String;
          return CupertinoPage(
            key: state.pageKey,
            child: VerificationScreen(phoneNumber: phoneNumber),
          );
        },
      ),

      //ride
      GoRoute(
        name: Routes.ridecomplete.name,
        path: Routes.ridecomplete.path,
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const RideCompleteScreen(),
          );
        },
      ),
      //success
      GoRoute(
        name: Routes.success.name,
        path: Routes.success.path,
        pageBuilder: (context, state) {
          final args = state.extra is SuccessArgs
              ? state.extra as SuccessArgs
              : const SuccessArgs();
          return CupertinoPage(
            key: state.pageKey,
            child: SuccessScreen(args: args),
          );
        },
      ),

      // ── Home  ────────────────────────────────────────
      GoRoute(
        name: Routes.home.name,
        path: Routes.home.path,
        pageBuilder: (context, state) {
          // final currentSheet =
          //     ((state.extra as RideSheetsType?) ??
          //     RideSheetsType.whereToGoSheet);
          return CupertinoPage(
            key: state.pageKey,
            child: const HomeRideRoomScreen(),
          );
        },
      ),
      // ── Notification  ────────────────────────────────────────
      GoRoute(
        name: Routes.notificationsScreen.name,
        path: Routes.notificationsScreen.path,
        pageBuilder: (context, state) {
          // final currentSheet =
          //     ((state.extra as RideSheetsType?) ??
          //     RideSheetsType.whereToGoSheet);
          return CupertinoPage(
            key: state.pageKey,
            child: const NotificationsScreen(),
          );
        },
      ),

      // ── Drawer  ────────────────────────────────────────
      GoRoute(
        name: Routes.wallet.name,
        path: Routes.wallet.path,
        pageBuilder: (context, state) =>
            CupertinoPage(key: state.pageKey, child: const WalletScreen()),
      ),
      GoRoute(
        name: Routes.locationAccess.name,
        path: Routes.locationAccess.path,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const LocationAccessScreen(),
        ),
      ),

      // ── ride history  ────────────────────────────────────────
      GoRoute(
        name: Routes.ridehistory.name,
        path: Routes.ridehistory.path,
        pageBuilder: (context, state) {
          final initialStatus =
              (state.extra as Map<String, dynamic>?)?["status"] ?? "completed";

          return CupertinoPage(
            key: state.pageKey,
            child: RideHistoryScreen(initialStatus: initialStatus),
          );
        },
      ),
      GoRoute(
        name: Routes.ridehistorydetail.name,
        path: Routes.ridehistorydetail.path,
        pageBuilder: (context, state) {
          final extraData = state.extra as Map<String, dynamic>?;
          final q = state.uri.queryParameters;
          final rideId = (extraData?['rideId'] ?? extraData?['id'] ?? q['rideId'] ?? q['id'] ?? '').toString();
          final driverId = (extraData?['driverId'] ?? q['driverId'] ?? '').toString();
          final rideLabel = extraData?['rideLabel'] as String? ?? '';
          final rideStatus = extraData?['rideStatus'] as String?;
          final specialRequest = extraData?['specialRequest'] as String?;
          final cancellationReason =
              extraData?['cancellationReason'] as String?;
          final cancelledBy = extraData?['cancelledBy'] as String?;
          return CupertinoPage(
            key: state.pageKey,
            child: RiderDetailScreen(
              rideId: rideId,
              rideLabel: rideLabel,
              driverId: driverId,
              rideStatus: rideStatus,
              specialRequest: specialRequest,
              cancellationReason: cancellationReason,
              cancelledBy: cancelledBy,
            ),
          );
        },
      ),
      GoRoute(
        name: Routes.settings.name,
        path: Routes.settings.path,
        pageBuilder: (context, state) =>
            CupertinoPage(key: state.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        name: Routes.ridedetailcarpool.name,
        path: Routes.ridedetailcarpool.path,
        pageBuilder: (context, state) {
          final extraData = state.extra as Map<String, dynamic>?;

          final rideLabel = extraData?['rideLabel'] as String? ?? '';
          final carpoolId = extraData?['carpoolId'] as String? ?? "";
          final profilepicture = extraData?['profilepicture'] as String? ?? '';
          final carImage = extraData?['carImage'] as String? ?? '';
          final carMake = extraData?['carMake'] as String? ?? '';
          final plateNo = extraData?['plateNo'] as String? ?? '';
          final time = extraData?['time'] as String? ?? '';

          return CupertinoPage(
            key: state.pageKey,
            child: RideDetailCarpoolScreen(
              carpoolId: carpoolId,
              rideLabel: rideLabel,
              profilepicture: profilepicture,
              carImage: carImage,
              carMake: carMake,
              plateNo: plateNo,
              time: time,
            ),
          );
        },
      ),
      GoRoute(
        name: Routes.themePreferences.name,
        path: Routes.themePreferences.path,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const ThemePreferencesScreen(),
        ),
      ),
      GoRoute(
        name: Routes.language.name,
        path: Routes.language.path,
        pageBuilder: (context, state) =>
            CupertinoPage(key: state.pageKey, child: const LanguageScreen()),
      ),
      GoRoute(
        name: Routes.savedLocations.name,
        path: Routes.savedLocations.path,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const SavedLocationsScreen(),
        ),
      ),
      GoRoute(
        name: Routes.placePicker.name,
        path: Routes.placePicker.path,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: PlacePickerScreen(initialAddress: state.extra as Address?),
        ),
      ),
      GoRoute(
        name: Routes.ridePlacePicker.name,
        path: Routes.ridePlacePicker.path,
        pageBuilder: (context, state) {
          final args = state.extra is RidePlacePickerArgs
              ? state.extra as RidePlacePickerArgs
              : const RidePlacePickerArgs(purpose: RideLocationType.dropoff);
          return CupertinoPage(
            key: state.pageKey,
            child: RidePlacePickerScreen(args: args),
          );
        },
      ),
      // User Profile
      GoRoute(
        name: Routes.profile.name,
        path: Routes.profile.path,
        pageBuilder: (context, state) =>
            CupertinoPage(key: state.pageKey, child: const ProfileScreen()),
      ),

      GoRoute(
        name: Routes.editProfile.name,
        path: Routes.editProfile.path,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const UpdateProfileScreen(),
        ),
      ),
      // Cards
      GoRoute(
        name: Routes.cards.name,
        path: Routes.cards.path,
        pageBuilder: (context, state) =>
            CupertinoPage(key: state.pageKey, child: const CardListScreen()),
      ),
      GoRoute(
        name: Routes.addCard.name,
        path: Routes.addCard.path,
        pageBuilder: (context, state) =>
            CupertinoPage(key: state.pageKey, child: const AddCardScreen()),
      ),
      GoRoute(
        name: Routes.deleteAccountOTP.name,
        path: Routes.deleteAccountOTP.path,
        pageBuilder: (context, state) =>
            CupertinoPage(key: state.pageKey, child: DeleteAccountOTPScreen()),
      ),
      GoRoute(
        name: Routes.deleteAccountVerify.name,
        path: Routes.deleteAccountVerify.path,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: const DeleteAccountVerifyOTPScreen(),
        ),
      ),

      //reviews
      GoRoute(
        name: Routes.driverProfileScreen.name,
        path: Routes.driverProfileScreen.path,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: DriverProfileScreen(driverId: (state.extra ?? '') as String),
        ),
      ),
      GoRoute(
        name: Routes.feedback.name,
        path: Routes.feedback.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final rideId = extra?['rideId'] as String? ?? '';
          final carpoolId = extra?['carpoolId'] as String?;
          final driver =
              extra?['driver'] as RideUserEntity? ?? const RideUserEntity();

          return CupertinoPage(
            key: state.pageKey,
            child: FeedBackScreen(
              driver: driver,
              rideId: rideId,
              carpoolId: carpoolId,
            ),
          );
        },
      ),

      GoRoute(
        name: Routes.enterRoute.name,
        path: Routes.enterRoute.path,
        pageBuilder: (context, state) {
          final purpose =
              ((state.extra as RideLocationType?) ?? RideLocationType.dropoff);
          return CupertinoPage(
            key: state.pageKey,
            child: EnterRouteScreen(purpose: purpose),
          );
        },
      ),
      GoRoute(
        name: Routes.availableCarpoolRides.name,
        path: Routes.availableCarpoolRides.path,
        pageBuilder: (context, state) {
          final params = state.extra as FindRideParams?;
          return CupertinoPage(
            key: state.pageKey,
            child: AvailableCarpoolRidesScreen(params: params),
          );
        },
      ),
      GoRoute(
        name: Routes.requestedCarpool.name,
        path: Routes.requestedCarpool.path,
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const RequestedCarpoolScreen(),
          );
        },
      ),
      GoRoute(
        name: Routes.carpoolRideComplete.name,
        path: Routes.carpoolRideComplete.path,
        pageBuilder: (context, state) {
          return CupertinoPage(
            key: state.pageKey,
            child: const CarpoolRideCompleteScreen(),
          );
        },
      ),
      GoRoute(
        name: Routes.chat.name,
        path: Routes.chat.path,
        pageBuilder: (context, state) {
          final q = state.uri.queryParameters;
          final rideId = q['rideId'] ?? '';
          final driverId = q['driverId'] ?? '';
          final driverName = q['driverName'] ?? '';
          final driverProfileImage = q['driverProfileImage'];
          final isCarpool = q['isCarpool'] ?? 'Ride';
          final args = (rideId.isNotEmpty)
              ? ChatScreenArgs(
                  rideId: rideId,
                  isCarpool: isCarpool,
                  driverId: driverId.isNotEmpty ? driverId : 'driver',
                  driverName: driverName.isNotEmpty ? driverName : 'Driver',
                  driverProfileImage: driverProfileImage?.isNotEmpty == true
                      ? driverProfileImage
                      : null,
                )
              : null;
          return CupertinoPage(
            key: state.pageKey,
            child: ChatScreen(args: args),
          );
        },
      ),

      // Add more route groups here…
      // GoRoute(
      //   name: Routes.rideRoom.name,
      //   path: Routes.rideRoom.path,
      //   pageBuilder: (context, state) =>
      //       CupertinoPage(key: state.pageKey, child: const RideRoomScreen()),
      // ),
    ],
  );
}
