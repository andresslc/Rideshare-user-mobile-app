import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/params/auth_params.dart';
import 'package:ride_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:ride_app/features/auth/presentation/states/auth_state.dart';
import 'package:ride_app/shared/widgets/custom_tap.dart';
import 'package:ride_app/shared/widgets/loader.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/screens/success_screen.dart';
import '../../../../shared/shared.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _otpController = TextEditingController();
  final CustomLoader loader = CustomLoader();
  Timer? _timer;
  int _seconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _otpController.text = "123456";
    }
    _startTimer();
  }

  void _startTimer() {
    _seconds = 60;
    _canResend = false;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  /// Verify OTP via AuthController
  void _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length < 6) {
      context.showErrorToast(context.l10n.otp_required);
      return;
    }
    final rawNumber = widget.phoneNumber;

    final String digitsOnly = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // if (digitsOnly.startsWith('1')) {
    //   digitsOnly = digitsOnly.substring(1);
    // }
    String? fcm;
    final localFcm = locator<StorageService>().getFCMToken ?? '';
    fcm = localFcm.isEmpty
        ? await locator<NotificationServices>().getDeviceToken()
        : localFcm;

    await ref
        .read(authProvider.notifier)
        .verifyOtp(
          VerifyOtpParams(
            countryCode: '1',
            otp: otp,
            phone: digitsOnly,
            fcmToken: fcm,
          ),
        );
  }

  void _resendOtp() {
    if (!_canResend) return;

    _startTimer();
    final rawNumber = widget.phoneNumber;

    String digitsOnly = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.startsWith('1')) {
      digitsOnly = digitsOnly.substring(1);
    }
    ref
        .read(authProvider.notifier)
        .resendOtp(SendOtpParams(countryCode: '1', phone: digitsOnly));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;

    //  Listen to authProvider for side effects
    ref.listen<AuthState>(authProvider, (previous, next) {
      switch (next) {
        case AuthLoading():
          loader.showLoader(context);
          break;

        case AuthError(:final message):
          loader.hideLoader();
          log(message);
          final displayMessage = message.toLowerCase().contains('invalid otp')
              ? l10n.invalid_otp
              : message;
          context.showErrorToast(displayMessage);
          break;

        case OtpVerified(:final response):
          loader.hideLoader();
          context.pushNamed(
            Routes.success.name,
            extra: SuccessArgs(
              type: SuccessType.numberVerified,
              redirectRouteName: response.isOnboarded
                  ? Routes.home.name
                  : Routes.createProfile.name,
              redirectArgs: response.isOnboarded
                  ? null
                  : (response.user?.phone ?? widget.phoneNumber),
            ),
          );
          break;

        case OtpResent(:final message):
          loader.hideLoader();
          context.showToast(message);
          break;
        default:
          loader.hideLoader();
          break;
      }
    });

    return AppScaffold(
      appBar: AppBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
                title: l10n.verification,
                subtitle: l10n.otp_subtitle(
                  widget.phoneNumber.formatAsMaskedPhone(),
                ),
              )
              .animate()
              .fadeIn(delay: 150.ms, duration: 350.ms)
              .slideY(begin: 0.15),

          const SizedBox(height: 24),
          OtpInput(controller: _otpController, length: 6)
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 450.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.did_not_receive_code,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              _canResend
                  ? CustomTap(
                      onTap: _resendOtp,
                      child: Text(
                        l10n.resend_now,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.link,
                        ),
                      ),
                    )
                  : Text(
                      "00:${_seconds.toString().padLeft(2, '0')}",
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.link,
                      ),
                    ),
            ],
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          const SizedBox(height: 32),
          AppButton(
            text: l10n.verify,
            onPressed: _verifyOtp,
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}

// class _VerificationScreenState extends ConsumerState<VerificationScreen> {
//   final _otpController = TextEditingController();
//   final CustomLoader loader = CustomLoader();
//   Timer? _timer;
//   int _seconds = 60;
//   bool _canResend = false;

//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//   }

//   void _startTimer() {
//     _seconds = 60;
//     _canResend = false;
//     _timer?.cancel();

//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_seconds > 0) {
//         setState(() => _seconds--);
//       } else {
//         timer.cancel();
//         setState(() => _canResend = true);
//       }
//     });
//   }

//   /// Verify OTP via AuthController
//   void _verifyOtp() {
//     final otp = _otpController.text.trim();

//     if (otp.length != 6) {
//       context.showErrorToast("Please enter 6 digit OTP");
//       return;
//     }

//     loader.showLoader(context);

//     ref
//         .read(authProvider.notifier)
//         .verifyOtp(
//           params: VerifyOtpParams(phone: widget.phoneNumber, otp: otp),
//           onError: (msg) {
//             loader.hideLoader();
//             context.showToast(msg);
//           },
//           onSuccess: (user) {
//             loader.hideLoader();
//             context.pushNamed(
//               Routes.success.name,
//               extra: SuccessArgs(
//                 type: SuccessType.numberVerified,
//                 redirectRouteName: Routes.createProfile.name,
//                 redirectArgs: widget.phoneNumber,
//               ),
//             );
//           },
//         );
//   }

//   void _resendOtp() {
//     if (!_canResend) return;

//     _startTimer();
//     context.showLoader();
//     ref
//         .read(authProvider.notifier)
//         .sendOtp(
//           params: SendOtpParams(phone: widget.phoneNumber),
//           onError: (msg) {
//             context.hideLoader();
//             context.showToast(msg);
//           },
//           onSuccess: (mesg) {
//             context.hideLoader();
//             context.showToast(mesg);
//           },
//         );
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _otpController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final colors = context.appColors;

//     return AppScaffold(
//       appBar: AppBar(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           AuthHeader(
//             title: l10n.verification,
//             subtitle: l10n.otp_subtitle(widget.phoneNumber),
//           ),

//           const SizedBox(height: 24),

//           OtpInput(
//             length: 6,
//             onCompleted: (otp) {
//               _otpController.text = otp;
//             },
//           ),

//           const SizedBox(height: 16),

//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 l10n.did_not_receive_code,
//                 style: context.textTheme.bodySmall?.copyWith(
//                   color: colors.textSecondary,
//                 ),
//               ),

//               const SizedBox(width: 6),

//               _canResend
//                   ? CustomTap(
//                       onTap: _resendOtp,
//                       child: Text(
//                         l10n.resend_now,
//                         style: context.textTheme.labelSmall?.copyWith(
//                           color: colors.link,
//                         ),
//                       ),
//                     )
//                   : Text(
//                       "00:${_seconds.toString().padLeft(2, '0')}",
//                       style: context.textTheme.labelSmall?.copyWith(
//                         color: colors.link,
//                       ),
//                     ),
//             ],
//           ),

//           const SizedBox(height: 32),

//           AppButton(text: l10n.verify, onPressed: _verifyOtp),
//         ],
//       ),
//     );
//   }
// }
