#!/bin/sh
# Build an unsigned candidate .deb from an existing Linux Flutter bundle.
#
# This script only assembles a package from files the caller already built. It
# does not fetch dependencies, install the package, register a Nostr handler,
# sign, or publish. Producing release packages requires authorization.
#
# Usage: sh build-deb.sh BUNDLE_DIR VERSION OUTPUT_DEB
set -eu

if [ "$#" -ne 3 ]; then
  echo "Usage: sh build-deb.sh BUNDLE_DIR VERSION OUTPUT_DEB" >&2
  exit 2
fi
bundle=$1
version=$2
output=$3
case "$version" in
  ''|*[!0-9A-Za-z.+:~_-]*) echo "Invalid Debian version" >&2; exit 2 ;;
esac
# Debian versions cannot start with a digit-less separator like ':' or '-'.
case "$version" in
  [A-Za-z0-9]*) ;;
  *) echo "Debian version must start with an alphanumeric character" >&2; exit 2 ;;
esac
test -d "$bundle" || { echo "Missing bundle: $bundle" >&2; exit 2; }
test -x "$bundle/yakihonne" || { echo "Missing executable: $bundle/yakihonne" >&2; exit 2; }
test -d "$bundle/data" || { echo "Missing data directory: $bundle/data" >&2; exit 2; }
command -v dpkg-deb >/dev/null || { echo "dpkg-deb is required" >&2; exit 2; }
command -v dpkg >/dev/null || { echo "dpkg is required" >&2; exit 2; }

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
stage=$(mktemp -d "${TMPDIR:-/tmp}/yakihonne-deb.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT HUP INT TERM

# Application files live under /opt so upgrades replace them without touching
# user data. User data is stored by the app (SharedPreferences and the Secret
# Service), not in /opt, so it survives upgrade and removal.
mkdir -p "$stage/DEBIAN" "$stage/opt/yakihonne" "$stage/usr/bin" \
  "$stage/usr/share/applications" "$stage/usr/share/icons/hicolor/512x512/apps" \
  "$stage/usr/share/doc/yakihonne"
cp -R "$bundle/." "$stage/opt/yakihonne/"
ln -s /opt/yakihonne/yakihonne "$stage/usr/bin/yakihonne"
cp "$script_dir/com.yakihonne.yakihonne.desktop" "$stage/usr/share/applications/"
cp "$repo_root/assets/icon.png" \
  "$stage/usr/share/icons/hicolor/512x512/apps/com.yakihonne.yakihonne.png"
cp "$repo_root/linux/packaging/copyright" "$stage/usr/share/doc/yakihonne/copyright"

# Runtime dependencies. These are the shared libraries the Flutter GTK runner and
# its Linux plugins link against. The actual clean-machine check must confirm
# this set against the built bundle and the target distribution:
#   - libgtk-3-0        GTK 3 runner
#   - libsecret-1-0     flutter_secure_storage_linux (Secret Service client)
#   - libgstreamer*     media playback code paths
#   - libglib2.0-0      GTK/GLib runtime (pulled in by GTK, listed explicitly)
#   - libstdc++6/libgcc-s1/libc6  C++ runner
# Plugins such as file_selector_linux and url_launcher_linux link GTK/GLib only.
# GStreamer *plugin* modules (good/bad/ugly, libav) are recommended, not
# depended on, because they are large and media fallbacks exist without them.
cat > "$stage/DEBIAN/control" <<EOF
Package: yakihonne
Version: $version
Section: net
Priority: optional
Architecture: $(dpkg --print-architecture)
Maintainer: YakiHonne <support@yakihonne.com>
Homepage: https://yakihonne.com
Installed-Size: $(du -sk "$stage/opt" | cut -f1)
Depends: libc6, libgcc-s1, libstdc++6, libglib2.0-0, libgtk-3-0, libsecret-1-0, libgstreamer1.0-0, libgstreamer-plugins-base1.0-0
Recommends: gstreamer1.0-plugins-good, gstreamer1.0-plugins-bad, gstreamer1.0-libav, gnome-keyring | kwalletmanager
Description: YakiHonne Nostr client
 YakiHonne is a Nostr social client with a desktop multi-pane interface.
 It stores account keys in the system Secret Service, so a running and
 unlocked keyring is required for sign-in and account switching.
EOF

# Guard against accidentally replacing another Nostr handler: this package
# installs the desktop entry but never sets it as the default in a maintainer
# script. Selecting the handler stays a user action in desktop settings.
dpkg-deb --build --root-owner-group "$stage" "$output"
echo "Built unsigned candidate: $output"
echo "No protocol handler was registered and no package was installed."
