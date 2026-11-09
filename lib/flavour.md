### ⚙️ Flavors

This app has three flavors. Every `run` and `build` command needs **two** things: the
flavor (`--flavor`) and the entry point (`-t`). Passing only one of them fails.

| Flavor | Entry point | Android flavor | iOS scheme |
|---|---|---|---|
| Dev | `lib/main_dev.dart` | `dev` | `Dev` |
| Staging | `lib/main_staging.dart` | `staging` | `Staging` |
| Production | `lib/main_prod.dart` | `production` | `Prod` |

> ⚠️ **Production is named differently on each platform.** Android calls it
> `production`, iOS calls it `Prod`. Use `--flavor production` for Android and
> `--flavor prod` for iOS. Dev and Staging are the same on both.

---

### ▶️ Running the App

### Run Dev Flavor

Android and iOS:

```
flutter run --flavor dev -t lib/main_dev.dart
```

### Run Staging Flavor

Android and iOS:

```
flutter run --flavor staging -t lib/main_staging.dart
```

### Run Production Flavor

Android:

```
flutter run --flavor production -t lib/main_prod.dart
```

iOS:

```
flutter run --flavor prod -t lib/main_prod.dart
```

---

### 🏗 Building for Android

### Build Dev APK

```
flutter build apk --flavor dev -t lib/main_dev.dart
```

### Build Staging APK

```
flutter build apk --flavor staging -t lib/main_staging.dart
```

### Build Production APK

```
flutter build apk --flavor production -t lib/main_prod.dart
```

### Build Production App Bundle (Play Store)

```
flutter build appbundle --flavor production -t lib/main_prod.dart
```

---

### 🍎 Building for iOS

### Build Dev

```
flutter build ios --flavor dev -t lib/main_dev.dart
```

### Build Staging

```
flutter build ios --flavor staging -t lib/main_staging.dart
```

### Build Production IPA (App Store)

```
flutter build ipa --flavor prod -t lib/main_prod.dart
```

---

### 🩺 When it fails

**"Gradle build failed to produce an .apk file"** — you forgot `--flavor`. Look at the
log: it says `Running Gradle task 'assembleDebug'` instead of `assembleDevDebug`. With
flavors defined, plain `assembleDebug` builds nothing at the path the tool expects.

**"The Xcode project defines schemes: Dev, Prod, Runner, Staging"** — the flavor name
does not match an iOS scheme. Most often this is `--flavor production` on iOS: use
`--flavor prod` there.

**iOS builds but behaves like the wrong environment** — you omitted `--flavor`, so Xcode
built the plain `Runner` scheme with the base config instead of `Debug-Dev` and friends.
iOS does not error here, it just builds the wrong thing.

**Wrong app launches, or the flavor picker keeps the old one** — `-t` and `--flavor` must
agree. `--flavor dev` with `-t lib/main_prod.dart` compiles fine and installs an app
pointing at the wrong backend.
