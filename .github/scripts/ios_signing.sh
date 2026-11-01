#!/bin/bash
set -euo pipefail
: "${IOS_CERTIFICATE_BASE64:?}" "${IOS_CERTIFICATE_PASSWORD:?}" "${IOS_RUNNER_PROFILE_BASE64:?}" "${IOS_SHARE_PROFILE_BASE64:?}" "${IOS_SAFARI_PROFILE_BASE64:?}" "${KEYCHAIN_PASSWORD:?}"
printf '%s' "$IOS_CERTIFICATE_BASE64" | base64 -D > "$RUNNER_TEMP/distribution.p12"
printf '%s' "$IOS_RUNNER_PROFILE_BASE64" | base64 -D > "$RUNNER_TEMP/runner.mobileprovision"
printf '%s' "$IOS_SHARE_PROFILE_BASE64" | base64 -D > "$RUNNER_TEMP/share.mobileprovision"
printf '%s' "$IOS_SAFARI_PROFILE_BASE64" | base64 -D > "$RUNNER_TEMP/safari.mobileprovision"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$RUNNER_TEMP/release.keychain-db"
security set-keychain-settings -lut 21600 "$RUNNER_TEMP/release.keychain-db"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$RUNNER_TEMP/release.keychain-db"
security import "$RUNNER_TEMP/distribution.p12" -P "$IOS_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$RUNNER_TEMP/release.keychain-db"
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$RUNNER_TEMP/release.keychain-db"
security list-keychains -d user -s "$RUNNER_TEMP/release.keychain-db"
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
for profile in runner share safari; do
  security cms -D -i "$RUNNER_TEMP/$profile.mobileprovision" > "$RUNNER_TEMP/$profile.plist"
  uuid=$(/usr/libexec/PlistBuddy -c 'Print UUID' "$RUNNER_TEMP/$profile.plist")
  cp "$RUNNER_TEMP/$profile.mobileprovision" "$HOME/Library/MobileDevice/Provisioning Profiles/$uuid.mobileprovision"
done
bundle exec ruby .github/scripts/ios_signing.rb
