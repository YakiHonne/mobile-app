# Windows packaging and Nostr protocol integration

Nothing here has been built, signed, installed, or tested on Windows. These are
reviewed inputs, not release artifacts. Packaging, code signing, installing a
handler, and publishing require explicit authorization and a native Windows host.

## Pieces

- `yakihonne.iss` — per-user Inno Setup 6 definition. Installs the Flutter
  bundle under `%LOCALAPPDATA%\Programs\YakiHonne`, does not require elevation,
  keeps user data across upgrade/uninstall, and offers an **optional, unchecked**
  `nostr:` handler registration.
- `register-nostr-protocol.ps1` — manual per-user registration for testing an
  existing executable without an installer. It only writes under `HKCU` and
  never sets the default handler.
- `unregister-nostr-protocol.ps1` — removes only the registration this project
  writes, for a clean test reset.

## WebView2

`flutter_inappwebview_windows` uses the Microsoft Edge WebView2 runtime. The
installer definition warns and links the Evergreen bootstrapper when the runtime
is absent, but it does **not** install WebView2. Decide before release whether to
bundle a fixed-version runtime, chain the bootstrapper, or require the runtime as
a documented prerequisite. Verify both per-machine and per-user WebView2 layouts
on a clean machine.

## Secure storage

`flutter_secure_storage_windows` uses DPAPI-backed storage per user. Account
data is per Windows user; a roaming profile or copied app data is not portable.
Confirm account recovery on a second Windows user and after a password reset.

## Dependencies and runtime

The runner and its plugins are x64. Confirm the Visual C++ runtime dependency set
against the built bundle. Plugins registered for Windows are listed in
`windows/flutter/generated_plugins.cmake`; `app_links`, `connectivity_plus`,
`file_selector_windows`, `flutter_inappwebview_windows`,
`flutter_secure_storage_windows`, `url_launcher_windows`, `share_plus`,
`permission_handler_windows`, `fc_native_video_thumbnail` and
`pro_video_editor` are the native ones to smoke-test.

## Upgrade and uninstall

- Upgrades install over `{app}`; `ignoreversion` lets bundle files replace each
  other. User preferences and secure storage live outside `{app}` and survive.
- Uninstall removes `{app}` and the optional handler keys it wrote. It preserves
  app data and WebView2 user data.
- Before release, verify: upgrade from the previous version keeps accounts and
  settings; uninstall leaves user data; reinstall finds existing accounts;
  uninstalling while another Nostr handler exists does not break that handler.

## Link delivery

The runner waits for Dart's readiness signal before forwarding a running
`nostr:` link, and now offers a retry dialog when forwarding times out or fails.
Cold-start links still arrive through `app_links` using the process argument.

Test on Windows:

1. Cold start by opening a `nostr:` link with no instance running.
2. Start the app, wait for the shell, then open one link.
3. Start the app and immediately open three links; confirm all arrive.
4. Force the readiness timeout (attach a debugger to the first window) and
   confirm the retry dialog appears and a retry succeeds or a missing window
   lets a new instance handle the link.
5. Exit the only instance and open a link; confirm a new instance starts.

## Signing and release

Sign `YakiHonne.exe` and the installer with Authenticode, verify the chain, and
test SmartScreen behavior on a clean machine. Do not publish without
authorization.
