import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Host-side checks for packaging inputs. These verify structure and safety
/// intent only; they cannot validate Inno Setup, dpkg, code signing, install,
/// uninstall, or a target-machine result.
void main() {
  final root = Directory.current;

  String read(String relative) =>
      File('${root.path}${Platform.pathSeparator}$relative').readAsStringSync();

  group('Linux desktop entry', () {
    final entry = read('linux/packaging/com.yakihonne.yakihonne.desktop');

    test('is a valid Application entry with a nostr URI handler', () {
      expect(entry, contains('[Desktop Entry]'));
      expect(entry, contains('Type=Application'));
      expect(entry, contains('Exec=/opt/yakihonne/yakihonne %u'));
      expect(entry, contains('MimeType=x-scheme-handler/nostr;'));
      expect(entry, contains('Icon=com.yakihonne.yakihonne'));
      expect(entry, contains('StartupWMClass=com.yakihonne.yakihonne'));
    });

    test('does not force itself as the default handler', () {
      // A default handler is chosen by the user, not a packaging input.
      expect(entry, isNot(contains('xdg-mime default')));
    });
  });

  group('Linux build-deb.sh', () {
    final script = read('linux/packaging/build-deb.sh');

    test('installs under /opt and symlinks onto PATH', () {
      expect(script, contains('/opt/yakihonne'));
      expect(script, contains('ln -s /opt/yakihonne/yakihonne'));
    });

    test('declares Secret Service and GStreamer runtime dependencies', () {
      expect(script, contains('libsecret-1-0'));
      expect(script, contains('libgstreamer1.0-0'));
      expect(script, contains('libgtk-3-0'));
    });

    test('treats media plugins and keyring as recommendations, not hard deps',
        () {
      final depends = RegExp(r'^Depends:.*$', multiLine: true)
          .firstMatch(script)!
          .group(0)!;
      final recommends = RegExp(r'^Recommends:.*$', multiLine: true)
          .firstMatch(script)!
          .group(0)!;
      expect(depends, isNot(contains('gstreamer1.0-plugins-good')));
      expect(recommends, contains('gstreamer1.0-plugins-good'));
      expect(recommends, contains('gnome-keyring'));
    });

    test('does not install, register a handler, or sign', () {
      expect(script, isNot(contains('dpkg -i')));
      expect(script, isNot(contains('apt install')));
      expect(script, isNot(contains('xdg-mime default')));
      expect(script, isNot(contains('gpg')));
      expect(script, isNot(contains('debsign')));
    });

    test('rejects an invalid Debian version before packaging', () {
      expect(script, contains('Invalid Debian version'));
      expect(script, contains('must start with an alphanumeric'));
    });

    test('ships required metadata files', () {
      expect(script, contains('copyright'));
      expect(File('${root.path}/linux/packaging/copyright').existsSync(),
          isTrue);
    });
  });

  group('Windows Inno Setup definition', () {
    final iss = read('windows/packaging/yakihonne.iss');

    test('is per-user and does not request elevation', () {
      expect(iss, contains('PrivilegesRequired=lowest'));
      expect(iss, contains(r'{localappdata}\Programs\YakiHonne'));
    });

    test('Nostr registration is optional and unchecked', () {
      final taskLine = RegExp(r'Name: "nostrprotocol".*')
          .firstMatch(iss)!
          .group(0)!;
      expect(taskLine, contains('Flags: unchecked'));
      expect(iss, contains('Tasks: nostrprotocol'));
    });

    test('handler changes are per-user and removed on uninstall', () {
      expect(iss, contains('Root: HKCU; Subkey: "{#ProtocolKey}"'));
      expect(iss, contains('uninsdeletekey'));
      expect(iss, isNot(contains('Root: HKLM')));
    });

    test('warns about a missing WebView2 runtime without bundling it', () {
      expect(iss, contains('WebView2RuntimeMissing'));
      expect(iss, contains('WebView2Url'));
      // It must not silently download or install the runtime.
      expect(iss, isNot(contains('WebView2Loader')));
      expect(iss, isNot(contains('DownloadTemporaryFile')));
    });

    test('preserves user data on uninstall', () {
      expect(iss, contains('UninstallDelete'));
      // Only WebView2 cache is removed; app/account data is outside {app}.
      expect(iss, isNot(contains('Type: filesandordirs; Name: "{app}"')));
    });
  });

  group('Windows protocol scripts', () {
    final register = read('windows/packaging/register-nostr-protocol.ps1');
    final unregister = read('windows/packaging/unregister-nostr-protocol.ps1');

    test('register is HKCU-only and asks before replacing a handler', () {
      expect(register, contains(r"'HKCU:\Software\Classes\nostr'"));
      expect(register, contains('Read-Host'));
      expect(register, isNot(contains('HKLM')));
    });

    test('unregister only removes a YakiHonne registration', () {
      expect(unregister, contains('yakihonne'));
      expect(unregister, contains('-Force'));
      expect(unregister, contains(r"'HKCU:\Software\Classes\nostr'"));
    });
  });
}
