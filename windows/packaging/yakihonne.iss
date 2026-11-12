; Unverified per-user Inno Setup 6 installer definition for YakiHonne.
;
; Build on Windows after producing an unsigned Flutter release bundle:
;   ISCC.exe /DBundleDir=C:\path\to\build\windows\x64\runner\Release ^
;            /DAppVersion=2.0.6 yakihonne.iss
;
; This definition:
;   * installs per user under %LOCALAPPDATA%\Programs\YakiHonne (no elevation);
;   * preserves user data on upgrade and uninstall (data lives in %APPDATA%);
;   * offers Nostr protocol registration as an explicit, optional, unchecked
;     task and removes only its own registration;
;   * detects a missing WebView2 runtime and points the user at the installer
;     URL rather than silently failing embedded web content at runtime.
;
; It does NOT install WebView2 automatically, sign binaries, or publish. Those
; steps and the clean-machine checks require authorization and native testing.
#ifndef BundleDir
  #error Pass /DBundleDir=<absolute path to the Flutter Windows release bundle>
#endif
#ifndef AppVersion
  #error Pass /DAppVersion=<version>
#endif

#define AppExe "YakiHonne.exe"
#define ProtocolKey "Software\Classes\nostr"

[Setup]
AppId={{F9C6F0E2-4A11-47DB-9D7A-CC6DCE8828E4}
AppName=YakiHonne
AppVersion={#AppVersion}
AppPublisher=YakiHonne
AppPublisherURL=https://yakihonne.com
AppSupportURL=https://github.com/YakiHonne
DefaultDirName={localappdata}\Programs\YakiHonne
DefaultGroupName=YakiHonne
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputBaseFilename=YakiHonne-{#AppVersion}-windows-setup
Compression=lzma2
SolidCompression=yes
UninstallDisplayIcon={app}\{#AppExe}
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
; Never delete user data on uninstall or upgrade; it is outside {app}.
UninstallDisplayName=YakiHonne

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked
Name: "nostrprotocol"; Description: "Register YakiHonne as a handler for nostr: links (optional; change later in Windows Settings)"; GroupDescription: "Integration:"; Flags: unchecked

[Files]
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\YakiHonne"; Filename: "{app}\{#AppExe}"
Name: "{group}\Uninstall YakiHonne"; Filename: "{uninstallexe}"
Name: "{autodesktop}\YakiHonne"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "Launch YakiHonne"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Only remove files the installer created outside {app}. User data in %APPDATA%
; and the secure-storage records are intentionally preserved.
Type: filesandordirs; Name: "{localappdata}\YakiHonne\WebView2"

[Registry]
; Opt-in Nostr handler. Changes are made under HKCU only, so no elevation is
; needed and other users are unaffected. The default handler is still chosen by
; the user; this makes YakiHonne an available candidate.
Root: HKCU; Subkey: "{#ProtocolKey}"; ValueType: string; ValueName: ""; ValueData: "URL:Nostr Protocol"; Flags: uninsdeletekey; Tasks: nostrprotocol
Root: HKCU; Subkey: "{#ProtocolKey}"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Flags: uninsdeletekey; Tasks: nostrprotocol
Root: HKCU; Subkey: "{#ProtocolKey}\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#AppExe},0"; Flags: uninsdeletekey; Tasks: nostrprotocol
Root: HKCU; Subkey: "{#ProtocolKey}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""; Flags: uninsdeletekey; Tasks: nostrprotocol

[Code]
const
  WebView2ClientKey =
    'Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}';
  WebView2Url = 'https://go.microsoft.com/fwlink/p/?LinkId=2124703';

function WebView2RuntimeMissing(): Boolean;
var
  Version: String;
begin
  // The Evergreen WebView2 Runtime registers its version under this key for
  // per-machine and per-user installs.
  Result := not (
    RegQueryStringValue(HKLM, WebView2ClientKey, 'pv', Version) or
    RegQueryStringValue(HKCU, WebView2ClientKey, 'pv', Version)
  );
end;

procedure InitializeWizard();
begin
  if WebView2RuntimeMissing() then
  begin
    MsgBox(
      'The Microsoft Edge WebView2 Runtime was not detected. YakiHonne uses ' +
      'it for embedded web content such as sign-in. Install it before or ' +
      'after setup:' + #13#10 + WebView2Url,
      mbInformation, MB_OK);
  end;
end;
