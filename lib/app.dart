import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/location/trip_guard.dart';
import 'package:ride_app/core/services/connectivity_service.dart';
import 'package:ride_app/core/services/network_quality_service.dart';
import 'package:ride_app/features/app_config/presentation/providers/ride_app_config_provider.dart';
import 'package:ride_app/features/ride_room/presentation/providers/ride_room_provider.dart';
import 'package:ride_app/shared/screens/no_internet_screen.dart';
import 'package:ride_app/shared/screens/slow_connection_screen.dart';
import 'package:ride_app/shared/widgets/slow_connection_banner.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'l10n/app_localizations.dart';
import 'l10n/language_change_notifier.dart';

/// Root application widget.
///
/// Uses [ValueListenableBuilder] to react to theme mode changes
/// without depending on any specific state management package.
class MyApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const MyApp({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: appLanguageNotifier,
          builder: (context, locale, _) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),

              child: MaterialApp.router(
                title: lookupAppLocalizations(
                  Locale(locale.languageCode == 'es' ? 'es' : 'en'),
                ).app_name,
                debugShowCheckedModeBanner: false,
                locale: locale,
                // ── Theme ──────────────────────────────────────────────
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,

                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,

                // ── Routing ────────────────────────────────────────────
                routerConfig: AppRouter.router,
                builder: (context, child) {
                  return ConnectivityWrapper(child: child!);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class ConnectivityWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  ConsumerState<ConnectivityWrapper> createState() =>
      _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends ConsumerState<ConnectivityWrapper>
    with WidgetsBindingObserver {
  bool _isOnline = true;
  NetworkQuality _networkQuality = NetworkQuality.good;
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<NetworkQuality>? _networkQualitySub;

  NetworkQualityService get _networkQualityService =>
      locator<NetworkQualityService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The dispatch ladder, the distance unit and the search copy all live in
    // the admin panel. Pull them once here, before any ride can start.
    unawaited(ref.read(rideAppConfigProvider.notifier).load());
    _isOnline = locator<ConnectivityService>().lastStatus;
    _networkQuality = _networkQualityService.lastQuality;
    _connectivitySub = locator<ConnectivityService>().connectionStream.listen((
      bool isOnline,
    ) {
      if (!mounted) return;
      setState(() => _isOnline = isOnline);
      if (isOnline) {
        unawaited(_networkQualityService.checkNow());
      }
    });
    _networkQualitySub = _networkQualityService.qualityStream.listen((
      NetworkQuality quality,
    ) {
      if (mounted) {
        setState(() => _networkQuality = quality);
      }
    });
    _networkQualityService.setForeground(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _networkQualityService.setForeground(false);
    unawaited(_connectivitySub?.cancel());
    unawaited(_networkQualitySub?.cancel());
    _connectivitySub = null;
    _networkQualitySub = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _networkQualityService.setForeground(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _networkQualityService.setForeground(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveTrip = TripGuard.hasActiveTripFromState(
      ref.watch(rideRoomProvider),
    );
    final bool showSlowConnection =
        _isOnline && _networkQuality == NetworkQuality.degraded;
    final bool showSlowConnectionBlocker = showSlowConnection && !hasActiveTrip;
    final bool shouldBlockInteraction = !_isOnline || showSlowConnectionBlocker;

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(ignoring: shouldBlockInteraction, child: widget.child),
        if (!_isOnline) const Positioned.fill(child: NoInternetScreen()),
        if (showSlowConnectionBlocker)
          const Positioned.fill(child: SlowConnectionScreen()),
        if (showSlowConnection && hasActiveTrip)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlowConnectionBanner(),
          ),
      ],
    );
  }
}
