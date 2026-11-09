import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/auth/presentation/widgets/profile_header.dart';
import 'package:ride_app/features/auth/presentation/widgets/ride_history_count_widget.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:ride_app/features/user_profile/presentation/states/user_states.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/loader.dart';
import 'package:ride_app/shared/widgets/toast.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final CustomLoader loader = CustomLoader();

  @override
  void initState() {
    super.initState();

    // Fetch profile on init
    Future.microtask(() {
      ref.read(userProfileProvider.notifier).getProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(userProfileProvider);
    final user = state.profile?.user;
    ref.listen<UserProfileState>(userProfileProvider, (previous, next) {
      // Loader
      if (next.status == UserProfileStatus.loading) {
        // loader.showLoader(context);
      } else {
        // loader.hideLoader();
      }

      // Error
      if (next.status == UserProfileStatus.error && next.message != null) {
        errorToast(msg: next.message!);
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text(l10n.my_profile)),
      body: Builder(
        builder: (context) {
          // 🔄 Loading state
          if (state.status == UserProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ No user
          if (user == null) {
            return Center(child: Text(l10n.profile_not_found));
          }

          // ✅ Success UI
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ProfileHeaderWidget(
                  imageUrl: user.profilePicture ?? "",
                  name: user.fullName.titleCase,
                  rating: user.rating.toDouble(),
                  email: user.email,
                  phone: user.phone.toUSPhoneFormat(formatWithCode: true),
                ),
                const Gap(20),

                AppButton(
                  text: l10n.edit_profile,
                  onPressed: () {
                    context.pushNamed(Routes.editProfile.name);
                  },
                ),
                const Gap(24),

                Row(
                  children: [
                    Expanded(
                      child: JobStatusCard(
                        title: l10n.ride_completed,
                        count: user.completedRides.toString(),
                        color: context.appColors.brand,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: JobStatusCard(
                        title: l10n.cancel_ride,
                        count: user.cancelledRides.toString(),
                        color: context.appColors.brand,
                      ),
                    ),
                  ],
                ),
    //"cancel_rides": "Cancel Rides",
              
              ],
            ),
          );
        },
      ),
    );
  }
}
