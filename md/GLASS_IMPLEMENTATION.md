# Glass Mode Implementation Guide

## Overview

Glass mode is a **style layer** toggled on top of the existing 4 color themes (graphite, noir, neige, ivory). It is NOT a 5th theme — it reuses the same `ThemeData` but changes how UI surfaces are rendered: frosted, floating, translucent instead of opaque and pinned.

---

## Toggle mechanism

**State**: `themeCubit.state.isFluid` (`bool`)
- Stored via `localDatabaseRepository.getFluidMode()` / `setFluidMode(bool)`
- Persisted in `SharedPreferences` under key `fluid_mode`
- Cubit: `lib/logic/theme_cubit/theme_cubit.dart`
- State: `lib/logic/theme_cubit/theme_state.dart`

**Reading it anywhere**:
```dart
final isGlass = themeCubit.state.isFluid;   // one-time read in build()
// or
isFluid()                                    // helper from lib/common/functions/functions_set.dart
```

`themeCubit` is a global singleton exported via `lib/utils/utils.dart` → `lib/globals.dart`.

For reactive rebuilds on toggle, wrap with `BlocBuilder<ThemeCubit, ThemeState>`.

**Themes**: `AppPreferredThemes` in `lib/utils/theme/theme.dart` has 4 glass methods: `glassGraphite`, `glassNoir`, `glassNeige`, `glassIvory`. They currently delegate to their normal counterparts and exist as separate methods so glass-specific overrides can be added without touching normal themes.

---

## Core visual recipe

**Use `FluidContainer` — never write `ClipRRect → BackdropFilter → Container` manually.**

```dart
import '../widgets/fluid_blur_container.dart';

FluidContainer(
  child: ...,
)
```

`FluidContainer` handles clipping, blur, background fill, and border in one widget. See the **`FluidContainer` API** section below for all parameters.

Key values:
- **Blur sigma**: `16` (pills, filter rows, tab bars), `20` (large panels: drawer, nav bar, app bar)
- **Background alpha**: `0.55` (default — most surfaces), higher for surfaces needing more opacity
- **Border**: `dividerColor` at `0.5` width (default, included automatically)
- **No `import 'dart:ui'`** needed — `FluidContainer` encapsulates it

---

## `FluidContainer` API

**File**: `lib/views/widgets/fluid_blur_container.dart`

```dart
FluidContainer({
  required Widget child,
  bool blur = true,                        // false = solid fill, no BackdropFilter
  double borderRadius = 300.0,             // pill by default; use kDefaultPadding*N for cards
  BorderRadius? customBorderRadius,        // asymmetric corners (overrides borderRadius)
  double sigma = 16.0,                     // blur intensity
  double backgroundAlpha = 0.55,           // fill opacity
  EdgeInsetsGeometry? padding,
  double? height,
  double? width,
  List<BoxShadow>? boxShadow,
  bool showBorder = true,                  // false = no border
  BoxBorder? customBorder,                 // asymmetric border (overrides showBorder)
  bool showDecoration = true,              // false = clip+blur only, no Container added
  bool useClipRect = false,                // true = ClipRect instead of ClipRRect (full-width bars)
})
```

### Common patterns

**Standard pill** (tab bars, filter rows):
```dart
FluidContainer(
  padding: const EdgeInsets.all(3),
  child: TabBar(...),
)
```

**Larger panel** (drawer, bottom nav):
```dart
FluidContainer(
  sigma: 20,
  borderRadius: kDefaultPadding * 1.5,
  padding: const EdgeInsets.symmetric(
    horizontal: kDefaultPadding / 1.5,
    vertical: kDefaultPadding / 1.5,
  ),
  child: ...,
)
```

**Full-width bar** (main view app bar — rectangular, no border):
```dart
FluidContainer(
  sigma: 20,
  useClipRect: true,
  showBorder: false,
  child: SafeArea(...),
)
```

**Top-only rounded sheet** (bottom sheets, modals):
```dart
FluidContainer(
  customBorderRadius: const BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  ),
  customBorder: Border(
    top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
    left: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
    right: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
  ),
  backgroundAlpha: isFluid() ? 0.55 : 1,
  child: ...,
)
```

**Blur-only wrap** (adding blur to an already-styled widget):
```dart
FluidContainer(
  showDecoration: false,
  borderRadius: 21,
  child: existingStyledWidget,
)
```

**Inner surface** (nested inside another glass surface — no double blur):
```dart
FluidContainer(
  blur: false,
  backgroundAlpha: 0.75,
  padding: const EdgeInsets.all(3),
  child: TabBar(...),
)
```

### What NOT to replace with `FluidContainer`

| Pattern | Why |
|---------|-----|
| `ClipPath + BackdropFilter + CustomPaint` | Custom shape (bubble tooltip in nav bar) |
| `BackdropFilter` with `sigma: 5` on media content | Sensitivity blur — intentionally subtle, no border |
| Video control overlays in `custom_video_controls.dart` | Video-specific, non-standard sizing |

---

## Bottom navigation bar

**File**: `lib/views/main_view/widgets/bottom_navigation_bar.dart`

### Normal mode
`MainViewBottomNavigationBar` — standard pinned bar at `Scaffold.bottomNavigationBar`.

### Glass mode
`GlassBottomNavigationBar` — floating pill, `Positioned` inside a `Stack` in the body.

**Layout in `main_view.dart`**:
```dart
// Glass: bottomNavigationBar = null, extendBody = false
Stack(
  children: [
    body,
    Positioned(
      left: 0, right: 0,
      bottom: MediaQuery.of(context).padding.bottom / 2 + kDefaultPadding / 4,
      child: Center(child: GlassBottomNavigationBar(onClicked: onScrollTop)),
    ),
  ],
)
```

**Pill structure**:
- `Column(mainAxisSize: min, crossAxisAlignment: end)` — FAB on top, pill below
- FAB: `AnimatedSize` — appears/disappears per view
- Pill: glass recipe, width `90.w`, height `kBottomNavigationBarHeight + kDefaultPadding / 1.5`

**FAB slot** (top-right of pill):
- Leading → add content button
- Media → add media button
- DMs → new DM button
- Other → hidden

**Bottom inset for content** (so content isn't hidden behind the floating bar):
```dart
kBottomNavigationBarHeight + kDefaultPadding * 2 + MediaQuery.of(context).padding.bottom / 2
```

---

## Scaffold rules in glass mode

| Property | Normal | Glass |
|----------|--------|-------|
| `bottomNavigationBar` | `MainViewBottomNavigationBar` | `null` |
| `extendBody` | `true` | `false` |
| `SafeArea(bottom:)` on body | `true` | `false` (handled per-view) |

FABs move inside the glass pill — no external `floatingActionButton` in glass mode.

---

## Design rules

1. **Always check `isGlass` first** — glass and normal paths are completely separate branches, never merged with ternaries inside a single widget tree
2. **`ClipRRect` wraps `BackdropFilter`** — never skip the clip
3. **No explicit width on floating elements** — use `mainAxisSize: MainAxisSize.min`; provide explicit `height` so children have a constraint
4. **`themeCubit.state.isFluid`** for one-time layout decisions in `build`; `BlocBuilder` for reactive rebuilds on toggle
5. **Inner views / detail screens** do NOT get glass scaffolds — glass treatment is limited to surfaces that float over blurred content (the bottom bar, the app bar, filter rows, overlaid cards). Plain list tiles, form fields, and settings rows stay opaque.
6. **Bottom sheets and dialogs** in glass mode use the glass recipe on their container surface only (the sheet itself), not on every child widget inside.

---

## Reusable glass-aware components

Reach for these before building a new glass surface from scratch:

| Component | File | Usage |
|-----------|------|-------|
| **`FluidContainer`** | `lib/views/widgets/fluid_blur_container.dart` | **Universal glass surface — use this first for any new frosted surface** |
| `GlassBottomNavigationBar` | `lib/views/main_view/widgets/bottom_navigation_bar.dart` | Floating pill nav bar |
| `FluidMainViewAppBar` | `lib/views/main_view/widgets/main_view_appbar.dart` | Glass app bar for main view |
| `FluidSourceFilterRow` | `lib/views/widgets/fluid_source_filter_row.dart` | Floating filter pill (leading/media/discover/notifications) |
| `GlassAppBarInset` | `lib/views/widgets/glass_appbar_inset.dart` | `InheritedWidget` — provides top inset to children when glass app bar is visible |
| `GlassButton` | `lib/views/widgets/animated_components/glass_button.dart` | Animated rotating-border button (used for redeem) |
| `_FluidFloatingTabBar` | `lib/views/dm_view/dm_view.dart` | Floating tab bar inside DMs (reference implementation) |
| `CustomIconButton(isGlass: true, ...)` | `lib/views/widgets/custom_icon_buttons.dart` | Icon button with glass gradient style |
| `TbuttonsTheme.glassTextButtonTheme()` | `lib/utils/theme/custom/buttons_theme.dart` | TextButton with gradient fill + top border |
| `DottedContainer(isGlass: ...)` | `lib/views/widgets/dotted_container.dart` | Dotted border container, glass-aware |
| `ContentContainer` (glass branch) | `lib/views/widgets/content_container.dart` | Card container with built-in BackdropFilter |

---

## NoteStats glass redesign

`NoteStats` (`lib/views/widgets/note_stats.dart`) has a significantly different layout in glass mode. Document this fully before implementing.

---

### What changes

| Element | Normal mode | Glass mode |
|---------|-------------|------------|
| Action buttons | tap = action, long press = show people list | tap = action only, **no long press** |
| Quote button | standalone `CustomIconButton` in stats row | **removed** from stats row |
| Repost button | single tap = repost | `PullDownButton` with two items: Repost + Quote |
| Translation button | end of stats row | moved to `_generalInfoRow` in `DetailedNoteContainer` |
| `PullDownGlobalButton` ("...") | end of stats row | moved to `_generalInfoRow` in `DetailedNoteContainer` |
| People lists (reactions/reposts/etc.) | long press on each button | new **Stats button** at end of stats row, opens unified modal |

---

### Stats row layout (glass mode)

```
[ reactions ] [ replies ] [ repost▼ ] [ zap ]   ...   [ stats ]
```

- Each button: tap-only, no long press, no quote standalone button
- `repost▼` is a `PullDownButton` — tap opens a pulldown with "Repost" and "Quote" items
- `stats` button at the far end opens the unified stats modal sheet

Normal mode stats row layout is unchanged.

---

### `_generalInfoRow` layout (glass mode)

In `DetailedNoteContainer._generalInfoRow`, append `TranslationButton` and `PullDownGlobalButton` at the end of the name/time row:

```
[ avatar ]  [ name · time ]  ···  [ translate ] [ ... ]
```

Normal mode keeps `TranslationButton` and `PullDownGlobalButton` in the stats row. The `isFluid()` guard switches which row receives them.

---

### Repost pulldown button (glass mode)

Replace `_repostButton` with a `PullDownButton`:

```dart
PullDownButton(
  itemBuilder: (context) => [
    PullDownMenuItem(
      title: context.t.repost.capitalizeFirst(),
      icon: /* FeatureIcons.repost */,
      onTap: () => doIfCanSign(
        func: () => notesEventsCubit.repostNote(model as DetailedNoteModel),
        context: context,
      ),
    ),
    PullDownMenuItem(
      title: context.t.quote.capitalizeFirst(),
      icon: /* FeatureIcons.quote */,
      onTap: () => doIfCanSign(
        func: () => showModalBottomSheet(/* AddReply with isQuote: true */),
        context: context,
      ),
    ),
  ],
  buttonBuilder: (context, showMenu) => CustomIconButton(
    icon: FeatureIcons.repost,
    backgroundColor: kTransparent,
    onClicked: showMenu,
    value: (reposts.length + quotes.length).toString(),  // combined count
    iconColor: (selfRepost || selfQuote)
        ? Theme.of(context).primaryColor
        : Theme.of(context).highlightColor,
    size: 18,
    fontSize: 15,
  ),
)
```

---

### Stats modal sheet (glass mode)

The Stats button opens a `DraggableScrollableSheet` modal with a `TabBar` containing 5 tabs. Each tab shows the content that was previously only accessible via long press.

**Tab structure:**

| Tab | Icon | Content source | Data |
|-----|------|---------------|------|
| Reactions | `FeatureIcons.heart` | `NetStatsView(type: NoteRelatedEventsType.reactions)` | Users who reacted |
| Replies | `FeatureIcons.comments` | `NetStatsView(type: NoteRelatedEventsType.replies)` | Users who replied |
| Reposts | `FeatureIcons.repost` | `NetStatsView(type: NoteRelatedEventsType.reposts)` | Users who reposted |
| Quotes | `FeatureIcons.quote` | `NetStatsView(type: NoteRelatedEventsType.quotes)` | Users who quoted |
| Zaps | `FeatureIcons.zap` | `ZappersView(zappers: zappers)` | Zappers list |

**Modal layout:**

```dart
DraggableScrollableSheet(
  initialChildSize: 0.9,
  minChildSize: 0.60,
  maxChildSize: 0.9,
  expand: false,
  builder: (_, controller) => Column(
    children: [
      ModalBottomSheetHandle(),
      // Glass tab bar pill (see Glass Tab Bar pattern section)
      _GlassStatsTabBar(tabController: tabController),
      SizedBox(height: kDefaultPadding / 2),
      Expanded(
        child: TabBarView(
          controller: tabController,
          children: [
            NetStatsView(id: id, type: NoteRelatedEventsType.reactions),
            NetStatsView(id: id, type: NoteRelatedEventsType.replies),
            NetStatsView(id: id, type: NoteRelatedEventsType.reposts),
            NetStatsView(id: id, type: NoteRelatedEventsType.quotes),
            ZappersView(zappers: zappers),
          ],
        ),
      ),
    ],
  ),
)
```

The tab bar inside the modal uses the glass pill pattern (see **Glass Tab Bar pattern** section), with `width: 90.w` to fit 5 tabs.

**Stats button widget:**

```dart
CustomIconButton(
  icon: FeatureIcons.stats,   // confirm icon name
  backgroundColor: kTransparent,
  iconColor: Theme.of(context).highlightColor,
  size: 18,
  onClicked: () => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (_) => _NoteStatsModal(id: model.id, zappers: zappers),
  ),
)
```

---

### Implementation checklist for NoteStats glass mode

- [ ] `buildActionButtons` — remove long press from all buttons when `isFluid()`
- [ ] `buildActionButtons` — remove standalone quote button when `isFluid()`
- [ ] `_repostButton` — replace with pulldown (repost + quote) when `isFluid()`
- [ ] `NoteStats.build` — move `TranslationButton` + `PullDownGlobalButton` out of stats row when `isFluid()`
- [ ] `DetailedNoteContainer._generalInfoRow` — append `TranslationButton` + `PullDownGlobalButton` when `isFluid()`
- [ ] Stats button — add at end of stats row when `isFluid()`
- [ ] `_NoteStatsModal` — new widget: `DraggableScrollableSheet` + glass `TabBar` + 5 `TabBarView` children

---

## Glass Tab Bar pattern

When a view uses a `TabBar` in glass mode, replace the standard tab bar with a floating pill using `FluidContainer`. Reference: `_FluidFloatingTabBar` in `lib/views/dm_view/dm_view.dart`.

```dart
import '../widgets/fluid_blur_container.dart';

SizedBox(
  width: 70.w,   // adjust per view if labels are long
  child: FluidContainer(
    padding: const EdgeInsets.all(3),
    child: TabBar(
      controller: tabController,
      dividerHeight: 0,
      indicatorSize: TabBarIndicatorSize.tab,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.all(3),
      indicator: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(300),
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.w500,
      ),
      tabs: [
        Tab(height: 28, text: 'Tab 1'),
        Tab(height: 28, text: 'Tab 2'),
      ],
    ),
  ),
)
```

| Property | Value | Notes |
|----------|-------|-------|
| Pill width | `70.w` | Adjust if tab labels are long |
| Border radius | `300` | Full pill |
| Blur | `sigmaX/Y: 16` | Slightly less than main surfaces (20) |
| Background alpha | `0.55` | Same as all glass surfaces |
| Indicator | `cardColor` pill | |
| Tab height | `28` | Keeps the pill compact |
| Inner padding | `EdgeInsets.all(3)` | Gives indicator breathing room |

In normal mode, keep the standard `TabBar` in the app bar's `bottom:` property — only the glass path uses the pill.

---

## Progress checklist

Update this as views are completed. "Done" means both the bottom inset AND any floating surfaces (filter rows, app bars, overlays) within that view are implemented.

### Core shell
| Component | Status | Notes |
|-----------|--------|-------|
| `main_view.dart` — scaffold switch | ✅ done | Stack + GlassBottomNavigationBar |
| `main_view_appbar.dart` — GlassMainViewAppBar | ✅ done | |
| `bottom_navigation_bar.dart` — GlassBottomNavigationBar | ✅ done | FAB slot, pill |
| `drawer_view.dart` | ✅ done | |
| `add_content_appbar.dart` | ✅ done | `isGlass` passed to CustomIconButton |

### Main tab views
| View | Status | Notes |
|------|--------|-------|
| `leading_view` | ✅ done | SliverPadding inset + GlassSourceFilterRow |
| `discover_view` | ✅ done | SliverPadding inset + GlassSourceFilterRow + NewContentContainer pill |
| `media_view` | ✅ done | SliverPadding inset + GlassSourceFilterRow |
| `dm_view` | ✅ done | ListView inset + _GlassFloatingTabBar |
| `notifications_view` | ✅ done | ListView inset + glass filter header |
| `wallet_view` | ✅ done | Bottom SizedBox inset |

### Secondary views (push routes)
| View | Status | Notes |
|------|--------|-------|
| `smart_widgets_view` / `smart_widgets_search` | 🚧 partial | Bottom inset only |
| `wallet_cashu_view` / `cashu_view` | 🚧 partial | Bottom inset only |
| `profile_view` | 🚧 partial | `OptionsHeader` glass pill tab bar; blur untested visually |
| `profile_settings_view` | ❌ pending | |
| `settings_view` | ❌ pending | |
| `article_view` | 🚧 partial | `_fluidContent` column layout done; appbar/scaffold glass treatment pending |
| `logify_view` | ✅ done | `FluidLogifyView` in `widgets/fluid_logify_view.dart` — mesh bg, centered glass card, selection → login/signup flows |
| `note_view` | ❌ pending | |
| `threads_view` | ❌ pending | |
| `search_view` | ✅ done | floating glass search bar + glass tab pill below it |
| `curation_view` | ❌ pending | |
| `dashboard_view` | ❌ pending | |
| `add_content_view` | ❌ pending | |
| `add_bookmark_view` | ❌ pending | |
| `polls_view` | ❌ pending | |
| `write_note_view` | ❌ pending | |
| `write_zap_poll_view` | ❌ pending | |
| `explore_packs_view` | ❌ pending | |
| `explore_relays_view` | ❌ pending | |
| `rewards_view` | ❌ pending | |
| `points_management_view` | ✅ done | Transparent `SliverAppBar`, `FluidCardContainer` for XP/Points/OneTime/Repeated reward cards, glass pill buttons |
| `relay_feed_view` | ✅ done | Floating `TabBar` pill (bottom), `FluidCardContainer` for reviews + nip43 sections, FAB lifted above tab bar |
| `uncensored_notes_view` | ❌ pending | |
| `gallery_view` | ❌ pending | |
| `giphy_view` | ❌ pending | |

### What "done" means for a secondary view
- Bottom padding inset applied (so content clears the floating bar)
- Any sticky/floating surfaces inside the view (filter chips, inner app bars, FABs) use glass recipe
- No `Scaffold.bottomNavigationBar` set — routing handles this at the main_view level

---

## File map

| File | Role |
|------|------|
| `lib/logic/theme_cubit/theme_cubit.dart` | Toggle logic, `isFluid` state |
| `lib/utils/theme/theme.dart` | `AppPreferredThemes.glassGraphite/Noir/Neige/Ivory` |
| `lib/utils/constants.dart` | `kDefaultPadding`, color constants |
| `lib/common/functions/functions_set.dart` | `isFluid()` helper |
| `lib/views/widgets/fluid_blur_container.dart` | `FluidContainer` — universal glass surface widget |
| `lib/views/main_view/main_view.dart` | Scaffold switch: normal vs glass body layout |
| `lib/views/main_view/widgets/bottom_navigation_bar.dart` | `GlassBottomNavigationBar`, `BottomNavBarItem`, `_GlassFab` |
| `lib/views/main_view/widgets/main_view_appbar.dart` | `GlassMainViewAppBar` |
| `lib/views/main_view/widgets/drawer_view.dart` | Drawer glass treatment |
| `lib/views/widgets/glass_source_filter_row.dart` | Floating filter pill |
| `lib/views/widgets/glass_appbar_inset.dart` | `GlassAppBarInset` inherited widget |
| `lib/views/widgets/animated_components/glass_button.dart` | Animated border `GlassButton` |
| `lib/views/widgets/custom_icon_buttons.dart` | `CustomIconButton(isGlass: true)` |
| `lib/views/widgets/content_container.dart` | Glass card container |
| `lib/views/widgets/dotted_container.dart` | Glass-aware dotted container |
| `lib/utils/theme/custom/buttons_theme.dart` | `TbuttonsTheme.glassTextButtonTheme()` |
