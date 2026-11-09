import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_images.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ride_app/features/auth/presentation/states/auth_state.dart';
import 'package:ride_app/shared/widgets/custom_dialogue.dart';
import 'package:ride_app/shared/widgets/loader.dart';
import 'package:ride_app/shared/widgets/phone_number_field.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/shared.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.showSessionExpiredDialog = false});

  final bool showSessionExpiredDialog;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final CustomLoader loader = CustomLoader();
  bool _didShowSessionExpiredDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !widget.showSessionExpiredDialog ||
          _didShowSessionExpiredDialog) {
        return;
      }
      _didShowSessionExpiredDialog = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => GradientSideDialog(
          title: context.l10n.somethingWentWrong,
          subtitle: context.l10n.socket_error_auth,
          icon: Icons.info_rounded,
          buttons: [
            AppButton(
              text: context.l10n.ok,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    });
  }

  void onLogin() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rawNumber = _phoneController.text.trim();

    String digitsOnly = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // if (digitsOnly.startsWith('1')) {
    //   digitsOnly = digitsOnly.substring(1);
    // }

    ref
        .read(authProvider.notifier)
        .sendOtp(SendOtpParams(phone: digitsOnly, countryCode: '1'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);

    final isLoading = authState is AuthLoading;

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
          final rawNumber = _phoneController.text.trim();
          final String digitsOnly = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
          loader.hideLoader();
          context.pushNamed(Routes.verification.name, extra: rawNumber);
          break;

        default:
          loader.hideLoader();
          break;
      }
    });

    return AppScaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child:
            // AppButton(
            //   text: l10n.continue_with_phone,
            //   onPressed: isLoading ? null : onLogin,
            // ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _phoneController,
              builder: (context, value, child) {
                final digitsOnly = value.text.replaceAll(RegExp(r'[^0-9]'), '');

                return AppButton(
                  text: l10n.continue_with_phone,
                  isDisable: digitsOnly.length < 10,
                  onPressed: isLoading ? null : onLogin,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
              },
            ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.p16),
              Image.asset(AppImages.logo, height: 144, width: 144)
                  .animate()
                  .fadeIn(duration: 1500.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: AppSizes.p24),
              AuthHeader(
                    title: l10n.welcome_back,
                    subtitle: l10n.login_subtitle,
                  )
                  .animate()
                  .fadeIn(duration: 1500.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: AppSizes.p24),
              // PhoneNumberField(
              //   controller: _phoneController,
              //   hintText: l10n.add_phone_number,
              // ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
              PhoneNumberField(
                controller: _phoneController,
                hintText: context.l10n.add_phone_number,
                validator: Validators.validateUSPhoneNumber,
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

              const SizedBox(height: AppSizes.p24),
            ],
          ),
        ),
      ),
    );
  }
}

// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends ConsumerState<LoginScreen> {
//   final _phoneController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final CustomLoader loader = CustomLoader();

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     if (kDebugMode) {
//       _phoneController.text = '1234567890';
//     }
//     super.initState();
//   }

//   void onLogin() {
//     FocusScope.of(context).unfocus();

//     if (!(_formKey.currentState?.validate() ?? false)) return;

//     loader.showLoader(context);

//     final String rawNumber = _phoneController.text.trim();

//     String digitsOnly = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');

//     if (digitsOnly.startsWith('1')) {
//       digitsOnly = digitsOnly.substring(1);
//     }

//     final formattedNumber = digitsOnly;

//     ref
//         .read(authProvider.notifier)
//         .sendOtp(
//           params: SendOtpParams(phone: formattedNumber),
//           onError: (msg) {
//             loader.hideLoader();
//             context.showToast(msg);
//           },
//           onSuccess: (user) {
//             loader.hideLoader();
//             context.pushNamed(Routes.verification.name, extra: formattedNumber);
//           },
//         );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;

//     return AppScaffold(
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: AppButton(text: l10n.continue_with_phone, onPressed: onLogin),
//       ),
//       child: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: AppSizes.p16),
//               Image.asset(AppImages.logo, height: 144, width: 144),
//               const SizedBox(height: AppSizes.p24),
//               AuthHeader(
//                 title: l10n.welcome_back,
//                 subtitle: l10n.login_subtitle,
//               ),
//               const SizedBox(height: AppSizes.p24),
//               PhoneNumberField(
//                 controller: _phoneController,
//                 hintText: l10n.add_phone_number,
//               ),
//               const SizedBox(height: AppSizes.p24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
