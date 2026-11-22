# Yaki Pro desktop implementation handoff

**Prepared:** 2026-11-15  
**Source:** YakiHonne Flutter desktop work, `DESKTOP` branch through `66cafd5`  
**Audience:** the engineer or coding agent starting Yaki Pro desktop

This is a transfer guide, not a claim that Yaki Pro shares YakiHonne's code,
dependencies, product requirements, or release readiness. Inspect the Yaki Pro
repository, its instructions and current product behavior first. Select the
applicable patterns; do not copy YakiHonne platform guards, identifiers,
credentials, package manifests or UI decisions without checking their fit.

## 1. Executive brief

The successful approach was to build a desktop **workspace**, not just stretch
mobile screens: a navigation rail, a main region and a persistent side region
with its own navigation and useful base content. Preserve each region's state
while navigating, measure layouts against the width actually available to each
pane, and keep mobile/tablet behavior explicitly protected. Treat native
storage, plugins, protocol links, installation and distribution as separate
engineering tracks from Flutter layout.

The largest release risk discovered was account storage: a locked or unavailable
keyring could be mistaken for an empty account list, and a swallowed write
failure could look like a successful login. Solve that before migrating real
accounts. A native build passing in CI is useful evidence of compilation and
packaging, but it does not prove that an installed app, keyring, protocol
handler, DPI behavior or recovery works.

**Yaki Pro's first task is discovery:** identify its platforms, current native
runners, SDK and lockfile, app architecture, account/storage model, navigation,
plugins, billing and release pipeline. Establish product requirements and an
isolated test profile before designing the shell or migration.

## 2. Evidence and limits from YakiHonne

- The user reported the macOS shell baseline working on 2026-11-11, including
  navigation/return, DM switching, draft retention, same-account refresh,
  side-pane recovery, compose/settings, pane dragging/reset, VoiceOver,
  appearance/language and media. The exact build and full test matrix were not
  recorded; do not extrapolate this to every screen or other operating systems.
- One observed and accepted YakiHonne behavior is that an **open note draft
  remains visible after switching accounts**; it disappears after the editor is
  closed and reopened. This is not cross-account draft isolation. Yaki Pro must
  explicitly choose its own policy and verify the active signing identity.
- Disposable widget and state tests, focused analysis, a separate macOS debug
  fixture and several native macOS observations provided useful evidence. They
  did not prove all real-content, localization, accessibility or live network
  cases. Some automated pointer drags in a fixture did not move the divider;
  that observation alone did not establish a defect.
- On 2026-11-15 GitHub Actions run
  [43687217711](https://github.com/YakiHonne/mobile-app/actions/runs/43687217711)
  compiled and packaged Windows, Linux and macOS candidates and uploaded three
  installers and three debug-symbol artifacts. It did not install or run them.
  Candidates are unsigned (macOS ad-hoc signed), and macOS notarization,
  Windows signing and native Linux distribution checks remain open.
- The current snapshot-storage and cross-process safeguards have disposable
  tests but remain a **Windows/Linux release blocker** until real backend,
  crash, recovery and downgrade scenarios pass on target machines.
- Older sections in the implementation audit and product assessment are
  historical. In particular, the old proposed outer-pane DM layout, source
  selector and expanded-pane mode do not describe the later shell. The older
  local `md/DESKTOP_HANDOFF.md` also predates Windows/Linux work. Use later
  audit entries and current code when studying implementation details.

## 3. Product and architecture decisions to make first

1. **Define the supported targets and feature scope.** For each desktop OS,
   enumerate workflows users actually need, unsupported mobile capabilities,
   whether external browser flows are acceptable, online/offline expectations,
   and minimum supported OS/display. Do not assume YakiHonne's Nostr, wallet,
   media or billing scope maps directly to Pro.
2. **Map state ownership before duplicating views.** Inventory app-wide
   services, account-specific state, controllers, subscriptions, routes,
   dialogs, drafts, media sessions and caches. Decide which data may be shared
   and which pane needs independent UI state. A single `ScrollController`
   cannot safely attach to two lists; a second copy of a global feed view can
   clobber refresh/pagination state or duplicate relay requests.
3. **Define navigation and account invariants.** Write down where a page opens,
   what Back/Escape closes, what survives tab changes, what happens to an open
   editor and pending asynchronous work on account switch, and how dialogs
   interact with nested navigators. Treat same-account metadata refresh
   separately from changing signing identity.
4. **Record evidence per feature.** Keep a current implementation audit with
   date, commit/build, OS, display scale, account/fixture type and actual
   outcome. Distinguish source inspection, automated test, native compilation,
   isolated native fixture, user-reported checks and installed-app validation.
   Mark superseded plans clearly instead of letting older claims appear current.

## 4. Workspace and navigation patterns

### Shell and pane lifecycle

YakiHonne uses a compact/expanded rail, main content, and a permanent outer
right pane. The right pane's nested navigator retains a useful Home-derived
base underneath temporary destinations; opening a detail and going Back returns
to the base. The main region remains mounted independently. The base eventually
became Home media/suggestion sections, rather than the earlier Following/source
selector proposal. That content is a YakiHonne product decision, not a Pro
requirement. Pick a useful Pro default with explicit loading, empty, error and
signed-out states.

Map **every** route entry point: named routes, builder routes, direct pushes,
replacements, links, dialogs that launch pages, compose, settings and account
switches. A dialog dismissal must not pop an unrelated root route. Test a base →
detail → nested detail → Back sequence, tab changes and restoration of scroll
position, as well as a dialog above each navigator. Check lifecycle/disposal so
hidden pages do not leak listeners or retain active subscriptions indefinitely.

YakiHonne's later DM layout is an **inner split inside the main region**: list
and conversation coexist while the outer side pane remains mounted. Below a
600-point main-region width, the list is shown and the selected conversation is
kept offstage for restoration. This is an example of preserving state while
adapting local layout; Pro should choose its own conversation behavior.

### Divider and sizing

The YakiHonne split uses a 520-point default side width and approximately 400
points per pane when space permits, with a constrained fallback. These are
provisional implementation values, not universal requirements. Persist the
split locally, clamp restored values to current constraints, and provide drag,
keyboard adjustment, semantics and reset. Test a restored oversized frame,
fullscreen, display removal/change, small screens and scaling on each native
window manager. A `1153 × 600` logical native minimum was added on Windows and
Linux to match the existing macOS value; actual usable client size and target
behavior remain unverified.

A YakiHonne-specific user request removed hover highlights and the divider's
visible focus highlight. The latter leaves keyboard focus less discoverable; do
not copy it as an accessibility standard. Yaki Pro should retain a visible,
accessible focus indication unless its own requirements explicitly decide
otherwise, and validate that alternative with keyboard and assistive technology.

### Local constraints instead of global screen width

A desktop window may contain multiple narrow regions. Use the constraints of
the actual pane, dialog or parent (`LayoutBuilder` or equivalent) for grids,
editor previews, sheets and cards; screen-wide media queries and mobile sizing
helpers can produce overflow in a narrow pane. Bound media and QR codes while
preserving aspect ratio. Scroll short dialogs and long forms; allow translated
labels and buttons to wrap or grow. Test narrow, intermediate and wide panes,
short windows, large text (at least 1.5× and 2× where practical), RTL and long
translations. Include actual representative content, not only empty boxes.

### Preserve mobile and touch behavior

Introduce platform-appropriate branches at the narrowest practical boundary.
Shared buttons, sheets, media widgets, navigation, third-party overrides and
state can affect mobile even when a new screen is desktop-only. Compare old and
new behavior; test both sides of each guard and visually check representative
phone/tablet screens. Use the target app's design system and localization
workflow, not YakiHonne constants or generated translation files by assumption.
New controls need accessible names, sensible tab order, pointer behavior,
keyboard activation and usable hit targets. YakiHonne used a 44-point minimum
for several desktop controls, allowing growth for text scaling.

## 5. Account storage, migration and recovery

### The failure mode

YakiHonne's legacy repository caught secure-storage reads as missing values
and hid write errors. Startup could therefore show no accounts when the keyring
was unavailable, and sign-in could update in-memory state despite a failed
persistent write. Several account maps and the active account index also had to
change consistently. Pro should audit its own code for the same classes of
failure even if its storage backend is different.

### Invariants for a safe design

- Distinguish a genuinely empty store from inaccessible, locked, malformed or
  uncertain data. A failed read must never authorize an empty-store overwrite.
- Treat account identities, key types, signer metadata and active selection as
  one coherent state transition. Persist and verify before reporting success or
  applying irreversible in-memory/signing side effects. Serialize mutations.
- Treat a failed write as **unknown**, because the backend may have changed the
  value before returning an error. Block further mutations until a trustworthy
  reload or restart. Inject both no-change and changed-before-error failures.
- Maintain a versioned format and validate it. Define conflict detection,
  rollback/recovery, interruption and retry behavior before deleting legacy data.
  Verify a replacement before cleanup and make cleanup resumable; recheck for
  legacy changes. Retain data when conflict is detected.
- Gate startup on usable storage and present actionable, localized retry and
  platform-specific guidance. Do not silently fall back to an unlocked account
  store if the lock path or secure store cannot be opened.
- Synchronize cooperating processes using an OS-backed advisory lock around
  the complete read/modify/write operation and detect stale snapshots before
  writes. Design for crashes, timeouts and same-process concurrency. Locks do
  not control older versions or code that ignores them, different paths, other
  isolates, or a removed/replaced lock file. File locking and backend durability
  differ by OS; confirm actual semantics rather than assuming atomicity.
- Avoid deleting user keys or signer records on failed persistence. Test add,
  switch, remove active/inactive/all accounts and remote-signer lifecycle.
  Ensure asynchronous login, callback and account-switch results cannot apply
  to the wrong identity.

YakiHonne's `AccountSnapshotStore` consolidates account maps, active index and
remote signers; it uses a prior snapshot, conflict checks and a file lock. Its
recovery and migration behavior is a **reference implementation under test**,
not a proven general-purpose storage library. The Linux backend depends on a
working Secret Service implementation; Windows storage is per user. Keyring
contents should not be assumed portable across OS users, machines or profiles.

### Downgrade and validation

Older versions may not understand a migrated snapshot and may show no accounts.
A product-supported downgrade path has not been proven. Design version
coexistence and a protected, independently restorable backup **before** Pro
migration; do not delete a migrated profile because an older version looks
empty. A restored old backup cannot include later changes. Verify each actual
account recovery method and public identity in a separate disposable profile,
including remote signers and any threshold-recovery configuration. A public key
alone is not a private-key backup.

On every supported Windows/Linux target, use synthetic credentials and isolated
OS profiles to test: empty and populated legacy stores; locked, absent and
restarted keyring; read, write, verification and cleanup failures; process
termination at each migration step; simultaneous cooperating instances;
restart; account mutations; backup restoration; and downgrade. Never log,
commit, screenshot or upload credentials. Record results without secrets.

## 6. Native plugins, media and platform behavior

Build a matrix from **the target app's current lockfile, generated plugin
registrants, native runner and actual call sites**. Plugin registration or a
successful build is not proof that a method is implemented. For every feature,
record native support, dependencies, fallback, tests and owner.

YakiHonne found that some locked desktop implementations for video, audio and
webviews were absent even though related plugins were registered. Its main
Windows/Linux audio, video, YouTube and Smart Widget paths use explicit
external-browser fallbacks; unsupported local video playback/trim controls are
hidden rather than constructing an unavailable player. Linux Google sign-in
and embedded X content have guarded fallbacks. Pro should audit all entry
points, not only the most visible screen, and offer clear errors when launching
a browser or external handler fails.

Audit file picker and save dialogs, camera/gallery, clipboard, thumbnails,
codecs, editor previews, generated images and downloads separately. File-save
fixtures should cover cancellation, exact bytes, spaces/non-ASCII paths,
overwrite policy, permission errors and temporary-file cleanup; verify the
native dialog on a real target. Protect key export and financial flows with a
separate review. Windows WebView2 and Linux GStreamer/Secret Service are runtime
prerequisites where the chosen plugins require them; package installation alone
does not establish a working service or codec.

Coordinate desktop media ownership across inline video, embedded media and
editor previews; cancel pending play intents on account changes and disposal.
Do not infer native playback or codec availability from a mocked player. Guard
unsupported notification, camera, IAP and other platform APIs explicitly. In
YakiHonne, macOS notification methods in the locked plugin were nonfunctional;
a guard was added and system notifications were later removed from that
project's scope. Pro must make its own notification and billing decisions.

Device interface availability, DNS reachability, relay socket state and actual
successful content delivery are distinct. Do not label an interface as proof of
Internet access or an open socket as proof of relay authorization or fresh data.
Keep unsent work on failed retries and clearly state partial/unknown states.
Do not introduce a transport overhaul merely to make a status label look green.

## 7. Deep links and process lifecycle

Define a link contract before implementing it: supported schemes and payloads,
validation, cold start, already-running delivery, startup queue, account
readiness, navigation readiness, duplicate policy, errors, cancellation and
privacy. Links can arrive before Flutter or the destination view is ready.
Buffer a bounded number, preserve ordering, and make deliberate identical
links distinguishable from accidental duplicate delivery. Do not log URLs that
may contain secrets. Recheck current plugin versions and native message contracts.

YakiHonne examples:

- On macOS an isolated, separately identified debug app received synthetic cold
  and running Nostr links targeted at that app. This did not verify default OS
  handler registration, actual destination navigation or live relay lookup.
- Linux runner owns a readiness channel: the primary launch URI arrives via
  startup arguments; remote GTK command lines are buffered until Dart subscribes.
  Nostr handling avoids also sending the same command through the plugin.
- Windows forwards to an existing window only after Dart signals readiness;
  a failed or timed-out send offers retry rather than silently opening a second
  app against the same profile. The runner uses a plugin-specific message
  contract that must be checked again whenever that plugin changes.

These native Linux/Windows paths have been compiled in CI but not verified as
installed protocol handlers. Test cold/running/early delivery, repeated identical
and rapid links, startup timeout/retry, window exit during forwarding,
signed-out and account-switch cases, multi-instance races and correct target
navigation on real OSes. Include Linux X11/Wayland and Windows focus behavior.
Registration should be opt-in and uninstall must not break another app's
handler; never register handlers on a developer's live profile merely for CI.
Wallet-link behavior was explicitly outside YakiHonne's later scope and should
not be assumed to work.

## 8. Packaging, CI and distribution

1. Pin the Flutter SDK and dependency revisions; enforce the lockfile and make
   path dependencies reproducibly available to CI. Audit installed native
   build dependencies separately from runtime dependencies.
2. Provide only distributable client configuration in bundled assets. A CI
   secret can protect delivery to the build runner, but any value bundled in an
   app can be extracted by recipients. Never include private credentials.
3. Build all supported targets natively, preserve matching obfuscation symbols
   for every distributed build, and upload them to the project's crash-reporting
   service after configuring and verifying its release process. Seven-day CI
   artifacts are not a sufficient long-term symbol archive.
4. Package candidates, test installation and upgrade/uninstall on clean target
   machines, then establish signing, provenance, notarization where applicable,
   updates, release access control and user-facing distribution. A CI build is
   not a distribution approval.

YakiHonne's manual [desktop workflow](../.github/workflows/desktop.yml) is an
example: Flutter 3.44.9, pinned sibling dependency, environment-provided build
configuration, obfuscation and per-platform candidates. Windows uses Inno Setup,
macOS creates a DMG, and Linux creates an AppImage. The installer files are
uploaded individually with `actions/upload-artifact@v7` and `archive: false`;
its single-file requirement matters. Symbols are separate; raw build-bundle
uploads were removed. These artifacts require workflow access and expire after
seven days, so they are not a durable public download mechanism.

A concrete CI failure illustrates why runner drift matters: `ubuntu-latest`
moved to Ubuntu 26.04, where the GTK plugin for linuxdeploy attempted to copy a
missing GDK Pixbuf loader directory. Installing `librsvg2-common` supplies an
SVG loader; the workflow now checks it and pins Ubuntu 24.04. The follow-up CI
packaged an AppImage successfully. Pinning an older runner does not by itself
prove compatibility with all older distributions. The linuxdeploy and GTK
plugin downloads are not pinned and require supply-chain review. The separate
Debian builder and packaging READMEs are historical candidate inputs; inspect
actual code and current audit before treating their untested statements as
current results.

Windows: audit per-user install, WebView2 and Visual C++ prerequisites,
optional protocol selection, Authenticode, SmartScreen, upgrade and uninstall.
Linux: audit ABI and oldest-supported distribution, GTK/libsecret/GStreamer,
codecs, keyring availability, executable permissions, icon/desktop entry,
AppImage or package dependencies, handler selection and package signing. macOS:
audit bundle identity, keychain groups, hardened runtime, distribution signing,
notarization/stapling, permissions and update delivery. Verify that uninstall
and upgrade preserve user data and do not affect unrelated handlers.

## 9. Suggested implementation sequence for Yaki Pro

1. **Inventory and baseline.** Read Pro's project instructions, architecture,
   design system, platform runners, lockfile and current CI. Build a feature and
   plugin matrix. Establish synthetic content and isolated accounts/OS profiles.
   Capture existing phone/tablet behavior and desktop baseline; record unknowns.
2. **Protect account data first.** Map storage and signer flows; fix swallowed
   errors and define versioning, concurrency, recovery and downgrade. Add fault
   injection before connecting any migration to real accounts. Keep native
   storage and recovery as an explicit release gate.
3. **Ship a small shell slice.** Implement a rail, one main view and one useful
   side base with nested navigation, local constraints and state retention.
   Test detail/back, independent scroll, dialog order, resize and account change.
   Get product feedback before converting every destination.
4. **Adapt core workflows incrementally.** Audit pane-local sizing, short
   dialogs, forms, lists, media and navigation routes. Preserve mobile behavior;
   test large text, RTL and themes in representative views. Expand features only
   after their state ownership and fallbacks are understood.
5. **Integrate OS services.** Add explicit plugin capability guards, file
   dialogs, link buffering/forwarding, window sizing and DPI handling. Validate
   with disposable native fixtures before installing handlers or using accounts.
6. **Build candidates and validate installed apps.** Reproducible CI builds,
   symbol retention and package candidates come before clean-machine install,
   upgrade/uninstall, storage, DPI, accessibility, protocol and recovery tests.
   Resolve signing and distribution separately. Do not publish from a CI success
   alone.

## 10. Acceptance and test matrix

For each row record target OS/version, architecture, build/commit, display and
scale, fixture/profile, steps, expected/observed result and unresolved issue.
Use fakes for fault injection and disposable data; native tests must not use a
real wallet or publish/upload content unless separately authorized.

| Area | Minimum evidence before considering it complete |
| --- | --- |
| Shell and navigation | Main/side state retained; base → detail → back; route variants and dialogs; tab changes; short/narrow/wide and restored windows. |
| Account and drafts | Same-key refresh versus account change; selected signer; draft policy; stale async work and signer lifecycle; no cross-account data leakage according to Pro's policy. |
| Storage | Empty/legacy/corrupt/locked/unavailable states; uncertain writes; concurrent processes; interruption, restart, backup restore and downgrade on each target. |
| Layout and accessibility | Real content, themes, large text, long labels, RTL, keyboard and visible focus, screen reader, display/DPI changes, mobile/tablet regression. |
| Media and files | Supported and unsupported plugin paths; browser failure; actual native picker/save/cancel/overwrite; codecs, playback and account/disposal races. |
| Links | Cold/running/early, repeated/rapid, timeout/retry, signed-out, navigation and handler install/uninstall on each target. |
| Networking | Interface unknown/offline, partial service, retry and unsent work using controlled fakes; targeted live behavior only in a safe test setup. |
| Package and operations | Fresh install, start, upgrade, uninstall/reinstall, prerequisites, keyring, signing, symbol matching, update and rollback on clean machines. |

## 11. Source map in YakiHonne

Paths below are relative to the **YakiHonne** checkout, not promises that the
same paths exist in Yaki Pro. Read current source and version history before
reusing any implementation.

| Topic | Starting points |
| --- | --- |
| Product decisions and audit | `md/DESKTOP_TASK_PLAN.md`, `md/DESKTOP_IMPLEMENTATION.md`, `md/DESKTOP_PRODUCT_ASSESSMENT.md`, `md/DESKTOP_ACCOUNT_RECOVERY.md` |
| Shell, routing and pane | `lib/views/main_view/main_view.dart`, `lib/views/main_view/widgets/detail_pane.dart`, `detail_pane_scope.dart`, `lib/routes/navigator.dart` |
| Split, base and DMs | `lib/views/main_view/desktop/desktop_pane_split.dart`, `desktop_home_sidebar.dart`, `desktop_dm_workspace.dart`, `desktop_dm_routing.dart` |
| Account protection | `lib/repositories/account_storage_snapshot.dart`, `account_storage_lock.dart`, `lib/logic/settings_cubit/`, `lib/initializers.dart` |
| Link lifecycle | `lib/logic/main_cubit/desktop_link_channel.dart`, `linux/my_application.cc`, `windows/runner/main.cpp`, `windows/runner/flutter_window.cpp` |
| Platform/media/files | `lib/utils/platform_utils.dart`, `lib/views/widgets/desktop_media_fallback.dart`, `lib/common/media_handler/desktop_file_save.dart` |
| Packaging and CI | `.github/workflows/desktop.yml`, `windows/packaging/`, `linux/packaging/`, native runner configuration |
| Test examples | `test/desktop_pane_split_test.dart`, `test/desktop_pane_account_safety_test.dart`, `test/desktop_link_channel_test.dart`, `test/desktop_file_save_test.dart`, `test/repositories/account_storage_snapshot_test.dart`, `account_storage_lock_test.dart` |

Some source documents in YakiHonne are ignored local files, and older package
READMEs contain pre-CI statements. Copy the handoff itself to the Pro project
or make it accessible there; do not assume every linked document will exist in
another checkout. Revalidate paths and current project instructions on arrival.
