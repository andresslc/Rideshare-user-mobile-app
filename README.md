# Ride App — Flutter rider app

A ride-hailing **rider app** built with Flutter: request rides on a live map, share rides (carpool), track the driver in real time, chat with the driver, pay with saved cards or a wallet, and review past trips. English and Spanish are supported.

> **About this repository**
> This code comes from a discontinued project and is published for learning purposes. All branding, credentials, signing keys and backend endpoints were removed or replaced with placeholders. The backend API is not included, so the app does not connect to a live server out of the box. To run it end to end you need your own Firebase project, Google Maps key, Stripe key and a compatible API.

## Features

- Phone-number sign-in with OTP and profile onboarding
- Address search with Google Places, saved locations and a map place picker
- Fare estimate, ride types (economy, luxury, carpool), promo codes
- Live ride room: driver tracking over Socket.IO, route polylines, ride status updates
- In-ride chat, push notifications (Firebase Cloud Messaging)
- Stripe card management and an in-app wallet
- Ride history, receipts, driver reviews and reports
- Light/dark theme, English/Spanish localization
- Three flavors: `dev`, `staging`, `production`

## Tech stack

| Area | Packages |
| --- | --- |
| State management | `flutter_riverpod` |
| Dependency injection | `get_it` |
| Routing | `go_router` |
| Networking | `dio`, `socket_io_client` |
| Functional errors | `fpdart` (`Either`) |
| Maps & location | `google_maps_flutter`, `geolocator`, `flutter_polyline_points` |
| Firebase | `firebase_core`, `firebase_auth`, `firebase_messaging`, `firebase_remote_config`, `firebase_crashlytics` |
| Payments | `flutter_stripe` |
| UI | `flutter_screenutil`, `lottie`, `flutter_animate`, `shimmer` |
| Code push | Shorebird |

## Project structure

The app follows a feature-first Clean Architecture layout:

```
lib/
├── core/            # config, DI modules, networking, navigation, theme, services, utils
├── features/        # one folder per feature
│   └── <feature>/
│       ├── data/          # datasources, models, repository implementations
│       ├── domain/        # entities, repository contracts, use cases
│       └── presentation/  # providers, states, screens, widgets
├── shared/          # reusable widgets and screens (splash, dialogs, buttons…)
├── l10n/            # ARB files and generated localizations
├── main_dev.dart    # entry point per flavor
├── main_staging.dart
└── main_prod.dart
```

Features: `address`, `app_config`, `auth`, `card`, `chat`, `home`, `notification`, `reviews`, `ride_history`, `ride_room`, `settings`, `user_profile`, `wallet`.

`tool/generate_feature.dart` and `tool/generate_api.dart` scaffold new features following the same layout.

## Getting started

Requirements: Flutter (Dart SDK `>=3.9.0`), Android Studio and/or Xcode.

```bash
flutter pub get
```

### 1. Firebase

The Firebase config files in the repo are **placeholders**. Generate real ones for your own project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This overwrites `lib/firebase_options.dart`, `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`. Enable Phone Authentication, Cloud Messaging and Remote Config in the Firebase console.

### 2. Google Maps / Places API key

- **Android:** copy `android/local.properties.example` to `android/local.properties` and set `MAPS_API_KEY`.
- **iOS:** set the key in `ios/Runner/AppDelegate.swift` (`GMSServices.provideAPIKey`).
- **Dart (Places search):** set `mapApiKey` in `RemoteConfigModel.defaults()` (`lib/core/config/remote_config_model.dart`) or provide it through Firebase Remote Config.

### 3. Backend and Stripe

The API base URLs, Stripe publishable key, terms/privacy links and store URLs default to placeholders in `RemoteConfigModel.defaults()` (`lib/core/config/remote_config_model.dart`). Point them at your own backend and Stripe account, or override them with Firebase Remote Config.

### 4. Run

Every command needs both `--flavor` and `-t`:

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor production -t lib/main_prod.dart   # Android
flutter run --flavor prod -t lib/main_prod.dart         # iOS
```

See [`lib/flavour.md`](lib/flavour.md) for build commands and troubleshooting.

### Tests

```bash
flutter test
```

## Release builds

- **Android signing:** copy `android/key.properties.example` to `android/key.properties` (git-ignored) and point it to your own keystore. Without it, release builds fall back to the debug key.
- **Shorebird:** replace `YOUR_SHOREBIRD_APP_ID` in `shorebird.yaml` with your own app IDs.
- **CI:** the GitHub Actions workflows in `.github/workflows` run only on manual dispatch. `.github/SECRETS.md` lists the secrets they need.

## Usage

Shared for educational and portfolio purposes. No open-source license is granted.
