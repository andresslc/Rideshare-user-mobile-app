import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_app/core/constants/app_icons.dart';
import 'package:ride_app/core/core.dart';
import 'package:ride_app/core/services/location_service.dart';
import 'package:ride_app/shared/shared.dart';
import 'package:ride_app/shared/widgets/app_gradient_box.dart';

class LocationAccessScreen extends StatefulWidget {
  const LocationAccessScreen({super.key});

  @override
  State<LocationAccessScreen> createState() => _LocationAccessScreenState();
}

class _LocationAccessScreenState extends State<LocationAccessScreen> {
  final LocationService _locationService = locator<LocationService>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _locationService.markLocationPromptShown();
  }

  Future<void> _handleTurnOnLocation() async {
    final l10n = context.l10n;
    setState(() => _isLoading = true);

    try {
      final result = await _locationService.requestLocationPermission();

      if (!mounted) return;

      switch (result) {
        case LocationPermissionResult.granted:
          // Permission granted, navigate to home
          _navigateToHome();
          break;

        case LocationPermissionResult.denied:
          // Show explanation dialog
          _showPermissionDeniedDialog();
          break;

        case LocationPermissionResult.permanentlyDenied:
          // Show settings dialog
          _showPermanentlyDeniedDialog();
          break;

        case LocationPermissionResult.serviceDisabled:
          // Show service disabled dialog
          _showServiceDisabledDialog();
          break;

        case LocationPermissionResult.error:
          // Show error message
          _showErrorSnackBar(l10n.error_occurred);
          break;
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(l10n.failed_to_request);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSkip() {
    _navigateToHome();
  }

  void _navigateToHome() {
    // Navigate to home screen after permission grant/skip
    context.goNamed(Routes.home.name);
  }

  void _showPermissionDeniedDialog() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.location_permission_title),
        content: Text(l10n.permission_denied_mesg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleTurnOnLocation();
            },
            child: Text(l10n.try_again),
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.location_permission_required_title),
        content: Text(l10n.permanently_denied_mesg),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
            },
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              await _locationService.openLocationSettings();
            },
            child: Text(l10n.open_settings),
          ),
        ],
      ),
    );
  }

  void _showServiceDisabledDialog() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.location_services_disabled_title),
        content: Text(l10n.location_services_disabled_mesg),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ).copyWith(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                text: l10n.turn_on,
                onPressed: _isLoading ? null : _handleTurnOnLocation,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
              AppGap.md,
              AppButton(
                text: l10n.skip,
                onPressed: _isLoading ? null : _handleSkip,
                backgroundColor: context.appColors.lightButton,
                fontColor: context.appColors.brand,
              ),
            ],
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppGradientBox(
              cornerRadius: 100,
              padding: const EdgeInsets.all(47),
              child: Image.asset(
                AppIcons.send,
                height: context.screenHeight * .07,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.location_access, style: context.textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
