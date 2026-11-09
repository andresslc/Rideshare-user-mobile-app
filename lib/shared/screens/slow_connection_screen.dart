import 'package:flutter/material.dart';
import 'package:ride_app/core/constants/app_sizes.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/extensions/theme_extension.dart';
import 'package:ride_app/core/services/connectivity_service.dart';
import 'package:ride_app/core/services/network_quality_service.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/shared/widgets/app_button.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';

class SlowConnectionScreen extends StatefulWidget {
  const SlowConnectionScreen({super.key});

  @override
  State<SlowConnectionScreen> createState() => _SlowConnectionScreenState();
}

class _SlowConnectionScreenState extends State<SlowConnectionScreen> {
  bool _isChecking = false;

  Future<void> _handleRetry() async {
    setState(() => _isChecking = true);
    try {
      await locator<ConnectivityService>().hasConnection;
      await locator<NetworkQualityService>().checkNow();
      await Future<void>.delayed(const Duration(seconds: 1));
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);

    return Scaffold(
      body: AppGradientBox(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  decoration: BoxDecoration(
                    color: context.appColors.brand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.signal_wifi_statusbar_connected_no_internet_4,
                    size: 80,
                    color: context.appColors.brand,
                  ),
                ),
                const SizedBox(height: AppSizes.p32),
                Text(
                  l10n?.slow_connection_title ?? 'Connection Too Slow',
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.p16),
                Text(
                  l10n?.slow_connection_subtitle ??
                      'Your internet connection is too slow to use the app right now. Please check your network and try again.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.p48),
                AppButton(
                  text: l10n?.retry ?? 'Retry',
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
