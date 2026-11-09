import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/notification/presentation/providers/notification_provider.dart';
import 'package:ride_app/features/notification/presentation/states/notification_state.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/features/ride_room/presentation/states/ride_room_state.dart';
import 'package:ride_app/features/settings/presentation/widgets/app_listtile.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/shared.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? fcm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh profile to get latest notification settings
      ref.read(userProfileProvider.notifier).getProfile();

      final userProfile = ref.read(userProfileProvider).profile;
      if (userProfile != null) {
        ref
            .read(notificationProvider.notifier)
            .setInitialValue(userProfile.user.isNotificationEnabled);
      }
    });
  }

  static bool _isRideOngoing(RideType? type) {
    return type == RideType.requested ||
        type == RideType.accepted ||
        type == RideType.arrived ||
        type == RideType.coming ||
        type == RideType.inprogress;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notificationState = ref.watch(notificationProvider);
    final rideRoomState = ref.watch(rideRoomProvider);
    final isRideOngoing = _isRideOngoing(rideRoomState.currentRideType);

    // Listen for profile changes (e.g. refresh)
    ref.listen(userProfileProvider, (previous, next) {
      if (next.profile != null && previous?.profile != next.profile) {
        ref
            .read(notificationProvider.notifier)
            .setInitialValue(next.profile!.user.isNotificationEnabled);
      }
    });

    // Listen for errors or success
    ref.listen(notificationProvider, (previous, next) {
      if (next.getNotifStatus == NotificationStatus.error &&
          next.message != null) {
        context.showErrorToast(next.message.toString());
      }
    });

    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.settings)
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
        centerTitle: true,
      ),
      child: Column(
        children: [
          /// Notifications toggle
          AppListTile(
            leadingImage: AppIcons.notification,
            title: l10n.notifications,
            showToggle: true,
            toggleValue: notificationState.isNotificationEnabled,
            // onToggleChanged: (val) {
            //   ref.read(notificationProvider.notifier).toggleNotification(val);
            // },
            onToggleChanged: (val) async {
              final localFcm = locator<StorageService>().getFCMToken ?? '';
              fcm = localFcm.isEmpty
                  ? await locator<NotificationServices>().getDeviceToken()
                  : localFcm;
              await ref
                  .read(notificationProvider.notifier)
                  .toggleNotification(val, fcm);
            },
          ).animate().fade(duration: 300.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: AppSizes.p12),

          /// Theme Setting
          AppListTile(
            leadingImage: AppIcons.mode,
            title: l10n.themePreferences,
            onTap: () {
              context.pushNamed(Routes.themePreferences.name);
            },
          ).animate(delay: 100.ms).fade(duration: 250.ms).slideY(begin: 0.2),
          const SizedBox(height: AppSizes.p12),

          /// Payment Method
          AppListTile(
            leadingImage: AppIcons.card,
            title: l10n.payment_method,
            onTap: () {
              context.pushNamed(Routes.cards.name);
            },
          ).animate(delay: 100.ms).fade(duration: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: AppSizes.p12),

          /// Language
          AppListTile(
            leadingImage: AppIcons.globe,
            title: l10n.language,
            onTap: () {
              context.pushNamed(Routes.language.name);
            },
          ).animate(delay: 100.ms).fade(duration: 150.ms).slideY(begin: 0.2),
          const SizedBox(height: AppSizes.p12),

          /// Saved Locations
          AppListTile(
            leadingImage: AppIcons.location,
            title: l10n.saved_locations,
            onTap: () {
              context.pushNamed(Routes.savedLocations.name);
            },
          ).animate(delay: 100.ms).fade(duration: 100.ms).slideY(begin: 0.2),

          const SizedBox(height: AppSizes.p12),

          /// Delete Account (destructive)
          AppListTile(
            leadingImage: AppIcons.delete,
            title: l10n.delete_account,
            onTap: () {
              if (isRideOngoing) {
                context.showErrorToast(l10n.delete_account_ride_ongoing);
                return;
              }
              context.pushNamed(Routes.deleteAccountOTP.name);
            },
            showToggle: false,
            isDestructive: true,
          ).animate(delay: 120.ms).fade(duration: 100.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}
