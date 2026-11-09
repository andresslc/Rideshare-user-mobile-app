import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ride_app/features/auth/presentation/states/auth_state.dart';
import 'package:ride_app/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:ride_app/shared/widgets/loader.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/shared.dart';

class DeleteAccountOTPScreen extends ConsumerWidget {
  DeleteAccountOTPScreen({super.key});
  final CustomLoader loader = CustomLoader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(userProfileProvider);
    final user = profileState.profile?.user;
    final phone = user?.phone ?? '';
    final formattedPhone = phone.formatAsPhone;
    ref.listen<AuthState>(authProvider, (previous, next) {
      switch (next) {
        case AuthLoading():
          loader.showLoader(context);
          break;

        case AuthError(:final message):
          loader.hideLoader();
          context.showToast(message);
          break;

        case OtpSent():
          loader.hideLoader();
          context.pushReplacementNamed(
            Routes.deleteAccountVerify.name,
            extra: user?.phone ?? '',
          );
          break;

        default:
          loader.hideLoader();
          break;
      }
    });

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          l10n.delete_account,
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.p16),
          Text(
                "${l10n.delete_account_otp_prefix} $formattedPhone",
                style: context.textTheme.titleSmall,
                textAlign: TextAlign.start,
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideX(begin: -0.2, end: 0),
          const SizedBox(height: AppSizes.p8),
          Text(
                l10n.delete_account_data_warning,
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.start,
              )
              .animate()
              .fadeIn(duration: 450.ms, delay: 150.ms)
              .slideY(begin: 0.1, end: 0),
          const Spacer(),

          AppButton(
                text: l10n.send_otp,
                onPressed: () {
                  ref
                      .read(authProvider.notifier)
                      .sendOtp(
                        SendOtpParams(
                          countryCode: '',
                          phone: user?.phone ?? '',
                        ),
                      );
                },
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: AppSizes.p24),
        ],
      ),
    );
  }
}
