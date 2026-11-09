import 'package:flutter/material.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/di/service_locator.dart';
import '../../core/extensions/theme_extension.dart';
import '../../core/services/connectivity_service.dart';
import '../../l10n/app_localizations.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _isChecking = false;

  Future<void> _handleRetry() async {
    setState(() => _isChecking = true);
    // Trigger immediate check
    await locator<ConnectivityService>().hasConnection;
    await Future.delayed(const Duration(seconds: 1)); // Small delay for UX
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBox(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon or static premium icon
                Container(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: context.appColors.brand.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: context.appColors.brand,
                  ),
                ),
                const SizedBox(height: AppSizes.p32),
                Text(
                  AppLocalizations.of(context)?.no_internet_title ??
                      'No Internet Connection',
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.p16),
                Text(
                  AppLocalizations.of(context)?.no_internet_subtitle ??
                      'Please check your network settings and try again to continue using the app.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.p48),
                AppButton(
                  text:
                      AppLocalizations.of(context)?.retry ?? 'Retry',
                  isLoading: _isChecking,
                  onPressed: _handleRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
