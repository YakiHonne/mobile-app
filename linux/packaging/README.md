# Linux packaging and Nostr protocol integration

The desktop workflow builds an unsigned candidate `.deb`. Installation,
SQLite loading, application startup, and feed behavior still need verification
on a clean Linux desktop before release.

## Pieces

- `com.yakihonne.yakihonne.desktop` — desktop entry with `%u` so a clicked
  `nostr:` link becomes a command-line argument. It declares the handler but
  does not make itself the default.
- `build-deb.sh` — assembles an unsigned candidate `.deb` from an existing
  Flutter bundle. It installs under `/opt/yakihonne`, adds a `/usr/bin`
  launcher, the desktop entry, an icon, and dependency metadata. It does not
  install, register a default handler, sign, or publish. Release packages
  require authorization.
- `copyright` — required package metadata placeholder; the shipping license
  must be set before distribution.

## Dependencies

`build-deb.sh` declares the runtime shared libraries the GTK runner and its
plugins link against: `libgtk-3-0`, `libsecret-1-0`, `libsqlite3-0`, GLib, GStreamer core/base,
and the C++ runtime. GStreamer *plugin* bundles and a keyring daemon are
`Recommends`, not hard dependencies, so the app can start without them and use
its documented media fallbacks.

The launcher includes the app's `lib` directory in the library search path.
There, `libsqlite3.so` points to the multiarch system runtime `libsqlite3.so.0`,
so the sqlite3 FFI fallback does not require `libsqlite3-dev`. The workflow
checks that the packaged link resolves and that the library can be loaded, but
that check does not replace testing the installed Flutter app on a clean system.

The dependency list is unverified against a real bundle. Confirm it with:

```
dpkg-shlibdeps -O /path/to/bundle/yakihonne
ldd /path/to/bundle/yakihonne
```

on the target distribution(s), including the oldest supported one. Plugin
`.so` files under `bundle/lib` link the same set; check a few of them too.

## Secure storage (Secret Service)

`flutter_secure_storage_linux` requires a running Secret Service
implementation (GNOME Keyring, KWallet with the Secret Service bridge, or
KeePassXC's Secret Service integration). If the keyring is locked or absent:

- Startup shows the localized "account storage could not be opened" screen with
  Linux keyring guidance and a retry, and does not overwrite or clear accounts.
- Account changes report failure and require a restart; no account is published
  from a write whose outcome is unknown.

There is now also a cross-process file lock for account storage under the
app support directory and a compare-and-swap guard on save. Confirm on a real
desktop session that two instances (temporarily permitted by `G_APPLICATION`
flags or launched manually) cannot both write account data, and that a crashed
instance does not leave a stale lock (the OS releases it on exit).

## Link delivery

The runner now owns a readiness channel: remote `nostr:` command lines are
buffered until Dart reports readiness, then delivered in order; the primary
launch URI still arrives through process arguments. The old gtk-plugin path is
suppressed for these Nostr command lines so a link is not delivered twice.

Test on Linux (X11 and Wayland):

1. Cold start from a `nostr:` link with no instance running.
2. Start the app, then open one link from a browser/terminal.
3. Start the app and immediately open three links; confirm order and count.
4. Open the same link twice; confirm both arrive (no time-window dedupe).
5. Close the app and open a link; confirm a new instance starts.
6. Confirm links do not appear in any log.

## Upgrade and uninstall

`/opt/yakihonne` is replaced on upgrade; user data lives in the app support
directory and the Secret Service, so it survives upgrades and removal. Verify:
upgrade keeps accounts, uninstall leaves user data, reinstall finds accounts,
and removing the package does not change or break another installed Nostr
handler.

## Icon

`assets/icon.png` is confirmed 512×512. The script installs it as the hicolor
512×512 icon. Ship additional sizes if the target desktop requests them.
