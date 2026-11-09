# GitHub Actions secrets for User-Mobile-App

Every workflow in `.github/workflows/` needs these secrets set in
**Repo Settings → Secrets and variables → Actions → Repository secrets**.

Nothing here is optional — a missing secret fails the run at the step that reads it.

## Shorebird (1)

| Secret | Where to get it |
| --- | --- |
| `SHOREBIRD_TOKEN` | Shorebird Console → Account → API Keys → Create key. Paste the token as-is. |

Verify: run the `Shorebird Smoke Test` workflow first. It only checks auth.

## Android signing (5)

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i upload-keystore.jks \| pbcopy` on macOS. Paste the string. |
| `ANDROID_STORE_PASSWORD` | The keystore's storePassword. |
| `ANDROID_KEY_PASSWORD` | The key's password (often the same as storePassword). |
| `ANDROID_KEY_ALIAS` | The alias inside the keystore, e.g. `upload`. |
| `MAPS_API_KEY` | Google Maps API key from Google Cloud Console. |

## iOS signing (3)

| Secret | Value |
| --- | --- |
| `IOS_CERTIFICATE_BASE64` | Distribution certificate exported from Keychain as `.p12`, then `base64 -i cert.p12 \| pbcopy`. |
| `IOS_CERTIFICATE_PASSWORD` | Password you set when exporting the .p12. |
| `IOS_PROVISIONING_PROFILE_BASE64` | The `.mobileprovision` for the prod bundle ID, `base64 -i profile.mobileprovision \| pbcopy`. |

## Google Play (1)

Used by the "Upload to Google Play" step in `shorebird_release_android.yaml`.

Generate a service account:
1. Play Console → Setup → API access → Choose or create a Google Cloud project
2. Create service account (in Google Cloud IAM) → grant role **Service Account User**
3. Back in Play Console → API access → Grant access to that service account → give it "Release manager" (or "Release apps to testing tracks only" for stricter scope)
4. In Google Cloud IAM → click the service account → Keys → Add key → JSON. A `.json` file downloads.

**First-ever upload to a Play app must be done by hand.** Google refuses API uploads until the app exists in Play Console with at least one build. After that, this workflow works.

| Secret | Value |
| --- | --- |
| `PLAY_SERVICE_ACCOUNT_JSON` | Full contents of the downloaded `.json` file (paste as-is, including braces). |

## App Store Connect API (3)

Used by the "Upload to App Store Connect" step in `shorebird_release_ios.yaml`.

Generate the key in **App Store Connect → Users and Access → Integrations → App Store Connect API**.
Role must be **App Manager** or higher. The `.p8` file can only be downloaded once — save it.

| Secret | Value |
| --- | --- |
| `ASC_ISSUER_ID` | Shown at the top of the Keys tab, format `abc123-...`. Same for every key in your team. |
| `ASC_KEY_ID` | Shown on the key row, format `ABC123DEF4`. |
| `ASC_KEY_P8` | Full contents of the `.p8` file, including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines. |

## Total: 13 secrets

Run the smoke test workflow first, then a `staging` Android release (cheapest full test),
then a `staging` iOS release (proves signing + ASC upload work), then `production` / `prod`.
