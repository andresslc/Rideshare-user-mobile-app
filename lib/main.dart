import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ride_app/firebase_options.dart';

import 'app.dart';
import 'core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Dependency injection ──────────────────────────────────────────────
  await setupLocator();

  // ── Remote Config (must complete before Stripe / first API call) ──────
  await locator<RemoteConfigService>().initialize();

  // ── Initialize Stripe ─────────────────────────────────────────────────
  Stripe.publishableKey = ApiEndpoints.stripePublishableKey;
  await Stripe.instance.applySettings();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // ── Start network monitoring ───────────────────────────────────────────
  await locator<NotificationServices>().init();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    locator<ConnectivityService>().initialize();
  });

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Run app ────────────────────────────────────────────────────────────

  runApp(ProviderScope(child: MyApp(themeNotifier: locator<ThemeNotifier>())));
}
