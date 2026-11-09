import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ride_app/core/observability/observability_service.dart';
import 'package:ride_app/firebase_options.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/core.dart';

Future<void> mainCommon({required AppConfig config}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setup(config);
  // ── Dependency injection (config registered first) ────────────────────
  await setupLocator();

  // ── Crash reporting (before anything that can throw) ──────────────────
  final observability = locator<ObservabilityService>();
  await observability.initialize();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(observability.recordFlutterFatalError(details));
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(observability.recordNonFatal(error, stack, fatal: true));
    return true;
  };

  // ── Remote Config ─────────────────────────────────────────────────────
  await locator<RemoteConfigService>().initialize();

  // ── Stripe (now reads key from AppConfig via ApiEndpoints) ────────────
  Stripe.publishableKey = ApiEndpoints.stripePublishableKey;
  await Stripe.instance.applySettings();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ── Notifications ─────────────────────────────────────────────────────
  await locator<NotificationServices>().init();

  // ── Connectivity ──────────────────────────────────────────────────────
  WidgetsBinding.instance.addPostFrameCallback((_) {
    locator<ConnectivityService>().initialize();
    final networkQuality = locator<NetworkQualityService>();
    networkQuality.configure(baseUrl: config.baseUrl);
    networkQuality.startMonitoring();
    unawaited(networkQuality.checkNow());
  });

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Run app ────────────────────────────────────────────────────────────
  runApp(ProviderScope(child: MyApp(themeNotifier: locator<ThemeNotifier>())));
}
