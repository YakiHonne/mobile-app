# Mobile releases

Run **iOS release** or **Android release** from GitHub Actions, choosing a commit/ref and `internal` or `production`. Each workflow releases its named platform. Set `version: X.Y.Z+N` in `pubspec.yaml` and `appVersion` in `lib/utils/constants.dart`, increment the build number for each upload, and add exactly one matching `## [X.Y.Z] - YYYY-MM-DD` section at the top of `CHANGELOG.md`. The selected commit must contain these workflow files. Store notes use that section with category headings removed and all changes grouped together. An optional `release_notes` input replaces the store notes for that run; GitHub's release body always uses the full changelog section. Play limits notes to 500 characters and Apple to 4,000, so the workflow fails before building if the selected store's limit is exceeded. Use a shorter override if necessary.

Android uploads only to the selected Play track. iOS always uploads a normal App Store distribution build to TestFlight; configure an internal group in App Store Connect to automatically receive new builds. Production additionally distributes to the configured external TestFlight groups and submits that exact build for App Store review with automatic release after approval. External beta review and App Store review can delay distribution; required metadata, agreements, export compliance, and group configuration must already be complete in the store consoles. Store uploads cannot reuse a build number, including after a partially successful run. Review the store consoles before retrying with an incremented build number.

After a successful Android production submission, the Android workflow creates a GitHub release named `YakiHonne X.Y.Z`, tagged `YakiHonne-X.Y.Z`, on the dispatched commit, and attaches three ABI-specific APKs. These sideload APKs use `IAP_ENABLED=false`; the Play Store bundle retains the default in-app purchase configuration. iOS releases do not create GitHub releases. An existing tag pointing elsewhere fails before publishing. If GitHub release creation fails after Play submission, create the release and attach the APKs manually; do not blindly rerun the store upload.

## GitHub environments

Create two environments in **Settings → Environments** named exactly `app-store` and `play-store`. The iOS job selects `app-store`; the Android job selects `play-store`. Add credentials as environment secrets within the corresponding environment. Repository and organization secrets can also be inherited by a job, so remove same-named secrets from those scopes if strict separation is required. Add `APP_ENV` and the GlitchTip settings below to each environment that you configure. Neither environment separates internal and production releases; any protection rules apply to both tracks.

### App Store setup

Create `app-store` in **Settings → Environments → New environment**, then add these under **Environment secrets**:

- `APP_ENV`: full contents of the app's `.env` file.
- `GLITCHTIP_AUTH_TOKEN`: GlitchTip API token with access to upload debug files to the project. This is separate from the DSN in `.env`.
- `GOOGLE_SERVICE_INFO_PLIST`: full Firebase `GoogleService-Info.plist` for `com.yakihonne.appyakihonne`.
- `IOS_CERTIFICATE_BASE64`: base64-encoded `.p12` export containing the Apple Distribution certificate and its private key.
- `IOS_CERTIFICATE_PASSWORD`: password used when exporting the `.p12`.
- `IOS_RUNNER_PROFILE_BASE64`: base64-encoded App Store distribution provisioning profile for `com.yakihonne.appyakihonne`.
- `IOS_SHARE_PROFILE_BASE64`: base64-encoded App Store distribution provisioning profile for `com.yakihonne.appyakihonne.ShareExtension`.
- `IOS_SAFARI_PROFILE_BASE64`: base64-encoded App Store distribution provisioning profile for `com.yakihonne.appyakihonne.SafariHighlightExtension`.
- `IOS_KEYCHAIN_PASSWORD`: a new random password used for the temporary CI keychain.
- `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_KEY_CONTENT`: the App Store Connect API key ID, issuer ID, and complete `.p8` private key contents. Use a team API key with sufficient access to upload builds, manage TestFlight and submit the app.

Add the environment secrets `GLITCHTIP_URL` (the base URL of your GlitchTip instance), `GLITCHTIP_ORG` (organization slug), and `GLITCHTIP_PROJECT` (project slug). The workflow passes these and the GlitchTip token to the Sentry-compatible Dart upload plugin. Confirm uploads work with your GlitchTip version.

All profiles must belong to Apple team `JU5BUTKJC2`, include the distribution certificate, and support the targets' enabled capabilities. Set up an internal TestFlight group to automatically receive new builds. For production, add an environment secret named `TESTFLIGHT_EXTERNAL_GROUPS` containing comma-separated names of existing external TestFlight groups. Production also requires completed App Store metadata, agreements and export-compliance information.

### Play Store setup

When ready, create `play-store` and add its environment secrets: `APP_ENV`, `GLITCHTIP_AUTH_TOKEN`, `GOOGLE_SERVICES_JSON` (Firebase JSON), `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`, and `PLAY_SERVICE_ACCOUNT_JSON`. Add the same three `GLITCHTIP_URL`, `GLITCHTIP_ORG`, and `GLITCHTIP_PROJECT` environment secrets, and grant the Google service account Play Console access to the app and releases.

On macOS, `base64 -i path/to/file | tr -d '\n' | pbcopy` copies a binary file's base64 representation for pasting into a secret. For text secrets, paste the entire file or key, including line breaks. Keep signing materials and the `.env` out of git. Verify the workflow's pinned Flutter version and `nostr_core_enhanced` commit when updating dependencies. It uses Flutter 3.44.9 and the dependency commit observed in the local checkout. The iOS workflow selects Xcode 26.3 for the video editor dependency; update the selected version if the runner image changes. The workflow uploads obfuscation symbols to GlitchTip before submitting to a store.
