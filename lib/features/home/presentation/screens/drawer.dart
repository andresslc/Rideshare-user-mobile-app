import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ride_app/features/auth/presentation/states/auth_state.dart';
import 'package:ride_app/features/home/presentation/widgets/drawer_header_widget.dart';
import 'package:ride_app/features/home/presentation/widgets/drawer_tile.dart';
import 'package:ride_app/features/user_profile/data/models/user_model.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/widgets/custom_dialogue.dart';
import 'package:ride_app/shared/widgets/loader.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/widgets/app_button.dart';

class AppDrawer extends ConsumerWidget {
  final ZoomDrawerController zoomController;

  const AppDrawer({super.key, required this.zoomController});

  Future<void> _openWebUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      context.showErrorToast('Unable to open link.');
    }
  }

  void showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return GradientSideDialog(
          title: AppLocalizations.of(context)!.logoutDialogTitle,
          subtitle: AppLocalizations.of(context)!.logoutDialogSubtitle,
          icon: Icons.logout_rounded,

          // imagePath: AppIcons.logout,
          buttons: [
            AppButton(
              text: AppLocalizations.of(context)!.cancel,
              backgroundColor: context.appColors.lightButton,
              fontColor: context.appColors.brand,
              onPressed: () {
                Navigator.pop(context); // close dialog
              },
            ),
            AppButton(
              text: AppLocalizations.of(context)!.logout,
              backgroundColor: context.appColors.brand,
              fontColor: context.appColors.textPrimary,
              onPressed: () {
                _logout(context, ref);
              },
            ),
          ],
        );
      },
    );
  }

  //
  void _logout(BuildContext context, WidgetRef ref) {
    // context.pushNamed(Routes.login.name);
    // context.pop(context);
    context.showLoader();

    ref.read(authProvider.notifier).logout();
  }

  Color backgroundColor(BuildContext c) =>
      c.isDark ? Colors.transparent : Theme.of(c).scaffoldBackgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final CustomLoader loader = CustomLoader();
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthLoading) {
        loader.showLoader(context);
      }

      if (next is LoggedOut) {
        loader.hideLoader();
        context.goNamed(Routes.login.name);
      }

      if (next is AuthError) {
        loader.hideLoader();
        context.showToast(next.message);
      }
    });
    final userJson = locator<StorageService>().getUser;
    final profileUser = ref.watch(userProfileProvider).profile?.user;
    final user = profileUser ?? _userFromStorage(userJson);

    return GestureDetector(
      onTap: () => ZoomDrawer.of(context)?.close(),
      child: Drawer(
        backgroundColor: backgroundColor(context),
        child: SafeArea(
          child: Column(
            children: [
              /// Drawer Header
              CustomDrawerHeader(
                name: user?.fullName.titleCase ?? "User",
                email: user?.email ?? "",
                profilePicture: user?.profilePicture,
                onViewProfile: () {
                  zoomController.close?.call();
                  // await Future.delayed(const Duration(milliseconds: 250));

                  context.pushNamed(Routes.profile.name);
                },
                // onViewProfile: () {
                //   Scaffold.of(context).closeDrawer();
                //   // Navigator.pop(context);

                //   context.pushNamed(Routes.profile.name);
                // },
              ),

              /// Menu Items
              DrawerTile(
                icon: CupertinoIcons.home,
                title: l10n.home,
                onTap: () {
                  ZoomDrawer.of(context)?.close();
                },
                // onTap: () => Drawer.pop(context),
              ),
              DrawerTile(
                icon: CupertinoIcons.clock,

                title: l10n.ride_history,
                onTap: () {
                  // Navigator.pop(context);
                  context.pushNamed(Routes.ridehistory.name);
                },
              ),
              DrawerTile(
                icon: Icons.account_balance_wallet_rounded,

                title: l10n.wallet,
                onTap: () {
                  // Navigator.pop(context);
                  context.pushNamed(Routes.wallet.name);
                },
              ),
              DrawerTile(
                icon: CupertinoIcons.settings,

                title: l10n.settings,
                onTap: () {
                  // Navigator.pop(context);
                  context.pushNamed(Routes.settings.name);
                },
              ),
              DrawerTile(
                title: l10n.terms_conditions,
                icon: CupertinoIcons.doc_text,

                onTap: () {
                  // Navigator.pop(context);
                  _openWebUrl(context, ApiEndpoints.termsUrl);
                },
              ),
              DrawerTile(
                title: l10n.privacy_policy,
                icon: CupertinoIcons.lock_shield,

                onTap: () {
                  // Navigator.pop(context);
                  _openWebUrl(context, ApiEndpoints.privacyPolicyUrl);
                },
              ),
              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: DrawerTile(
                  icon: CupertinoIcons.square_arrow_right,
                  title: l10n.logout,
                  isDestructive: true,
                  onTap: () {
                    showLogoutDialog(context, ref);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  UserModel? _userFromStorage(String? userJson) {
    if (userJson == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (e) {
      debugPrint("Error parsing user from storage: $e");
      return null;
    }
  }
}
