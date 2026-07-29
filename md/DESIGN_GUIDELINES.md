# Design Guidelines

Reference this file whenever building a new view or widget. All values are sourced directly from the codebase — constants in `lib/utils/constants.dart`, themes in `lib/utils/theme/`.

---

## Spacing & Padding

There is one spacing constant in the entire app:

```dart
const kDefaultPadding = 20.0;   // lib/utils/constants.dart
```

All other spacing values are derived from it:

| Usage                  | Value | Expression              |
| ---------------------- | ----- | ----------------------- |
| Standard edge padding  | 20    | `kDefaultPadding`       |
| Half padding           | 10    | `kDefaultPadding / 2`   |
| Tight padding          | ~13   | `kDefaultPadding / 1.5` |
| Quarter padding        | 5     | `kDefaultPadding / 4`   |
| Section gap            | 40    | `kDefaultPadding * 2`   |
| Input field vertical   | ~13   | `kDefaultPadding / 1.5` |
| Input field horizontal | 20    | `kDefaultPadding`       |

**Rule**: never hardcode a pixel value for spacing. Derive from `kDefaultPadding` so layouts scale consistently.

---

## Border Radius

| Usage                     | Value                 | Expression                             |
| ------------------------- | --------------------- | -------------------------------------- |
| Standard card / container | ~13                   | `kDefaultPadding / 1.5`                |
| Input fields              | 15                    | `kDefaultPadding - 5`                  |
| Buttons (normal)          | 10                    | hardcoded `10`                         |
| Buttons (glass)           | 25 or `StadiumBorder` | pill shape                             |
| Pill / badge              | 300                   | full pill `BorderRadius.circular(300)` |
| Small chips / tags        | 5                     | `kDefaultPadding / 4`                  |

---

## Colors

### Semantic usage — always use `Theme.of(context)` properties

| Role                    | How to access                               | Notes                         |
| ----------------------- | ------------------------------------------- | ----------------------------- |
| Page background         | `Theme.of(context).scaffoldBackgroundColor` |                               |
| Card / elevated surface | `Theme.of(context).cardColor`               |                               |
| Borders / dividers      | `Theme.of(context).dividerColor`            | Use at 0.5px width            |
| Primary action          | `Theme.of(context).primaryColor`            | Brand orange by default       |
| On-primary text/icons   | `Theme.of(context).primaryColorDark`        | White in dark, black in light |
| Hint / secondary        | `Theme.of(context).hintColor`               | Defined per theme             |

**Rule**: never hardcode hex values inside widget code. Use `Theme.of(context)` so the widget adapts to all 8 themes automatically.

### Fixed semantic colors (theme-independent)

Use these constants from `lib/utils/constants.dart` only when the color must not change with the theme:

| Constant       | Hex       | Use                                             |
| -------------- | --------- | ----------------------------------------------- |
| `kMainColor`   | `#EE7700` | Brand orange — primary actions                  |
| `kRed`         | `#FF4A4A` | Errors, destructive actions                     |
| `kGreen`       | `#00C04D` | Success states                                  |
| `kYellow`      | `#FFE604` | Warnings / highlights                           |
| `kBlue`        | `#504DFF` | Info / links                                    |
| `kNavyBlue`    | `#1d9bf0` | Twitter/social-style links                      |
| `kWhite`       | `#FFFFFF` | Always-white (e.g. text on primaryColor button) |
| `kBlack`       | `#000000` | Always-black                                    |
| `kTransparent` | —         | `Colors.transparent` alias                      |

### Accent / status colors and their side colors

| State   | Main          | Side (background) |
| ------- | ------------- | ----------------- |
| Error   | `kRed`        | `kRedSide`        |
| Success | `kGreen`      | `kGreenSide`      |
| Warning | `kYellowSide` | `kYellowSide`     |
| Primary | `kMainColor`  | `kMainColorSide`  |
| Info    | `kBlue`       | `kBlueSide`       |

### Theme scaffolding colors (for reference)

| Theme            | Scaffold  | Card                     | Outline                  |
| ---------------- | --------- | ------------------------ | ------------------------ |
| light            | `#FFFFFF` | `#F4F4F4`                | `#E5E5E5`                |
| dark             | `#171718` | `#222525`                | `#393B3B`                |
| black            | `#000000` | `#171718`                | `#404040`                |
| cream            | `#FAF7F3` | `#F0ECE8`                | `#E6E4E2`                |
| glass (graphite) | `#0D1117` | `rgba(255,255,255,0.15)` | `rgba(255,255,255,0.20)` |

---

## Typography

Font family: **DMSans** (set globally). Access via `Theme.of(context).textTheme`.

| Style            | Size | Weight | Use for                   |
| ---------------- | ---- | ------ | ------------------------- |
| `displayLarge`   | 57   | bold   | —                         |
| `displayMedium`  | 45   | bold   | —                         |
| `displaySmall`   | 36   | bold   | Hero headings             |
| `headlineLarge`  | 32   | w500   | Section titles            |
| `headlineMedium` | 28   | w500   | Page titles               |
| `headlineSmall`  | 24   | w500   | Card titles               |
| `titleLarge`     | 22   | w500   | Sub-section headers       |
| `titleMedium`    | 16   | w500   | List item titles          |
| `titleSmall`     | 14   | w500   | Captions / labels         |
| `bodyLarge`      | 16   | normal | Body text                 |
| `bodyMedium`     | 16   | normal | Body text (same as Large) |
| `bodySmall`      | 12   | normal | Secondary body text       |
| `labelLarge`     | 14   | normal | Button labels, tags       |
| `labelMedium`    | 12   | normal | Chips, metadata           |
| `labelSmall`     | 10   | normal | Timestamps, fine print    |

**Rule**: always use `Theme.of(context).textTheme.<style>` — never hardcode a `TextStyle` with a raw font size unless adding a `.copyWith()` override on top of a theme style.

---

## Buttons

All button styles are set via `ThemeData` — use standard Flutter button widgets and they inherit the correct style automatically.

### Which button type to use

| Situation                                | Widget               | Style behavior                                                        |
| ---------------------------------------- | -------------------- | --------------------------------------------------------------------- |
| Primary action (submit, confirm)         | `ElevatedButton`     | Filled with `primaryColor`, white text                                |
| Secondary / alternative action           | `TextButton`         | Filled with `primaryColor`, white text (same as elevated in this app) |
| Destructive / cancel with visible border | `OutlinedButton`     | Border + foreground in `primaryColor`, transparent fill               |
| Icon-only actions                        | `CustomIconButton`   | `lib/views/widgets/custom_icon_buttons.dart`                          |
| Icon with visible border                 | `BorderedIconButton` | `lib/views/widgets/buttons_containers_widgets.dart`                   |
| Status/tag pill                          | `StatusButton`       | `lib/views/widgets/buttons_containers_widgets.dart`                   |

### Button sizing (all themes)

- Padding: `horizontal: 16, vertical: 12`
- Border radius: `10` (normal), `StadiumBorder` (glass)
- Border width on `OutlinedButton`: `1.5`

### `CustomIconButton`

```dart
CustomIconButton(
  icon: someIcon,
  onPressed: () {},
  // optional glass mode:
  isGlass: isFluid(),
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  borderColor: Theme.of(context).dividerColor,
)
```

### Glass buttons

Glass mode uses `StadiumBorder` (fully rounded) and `TbuttonsTheme.glassTextButtonTheme()` with a `LinearGradient` fill + top border only. See `GLASS_IMPLEMENTATION.md`.

---

## Input Fields

All inputs inherit `InputDecorationTheme` from the active `ThemeData`. Just use `TextField` / `TextFormField` with no explicit decoration for correct styling. If you need explicit decoration, mirror these values:

```dart
InputDecoration(
  filled: true,
  fillColor: Theme.of(context).cardColor,
  contentPadding: EdgeInsets.symmetric(
    horizontal: kDefaultPadding,
    vertical: kDefaultPadding / 1.5,
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(kDefaultPadding - 5),  // 15
    borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
  ),
)
```

---

## Container / Card Patterns

### Standard card border

```dart
final containerBorder = OutlineInputBorder(
  borderSide: BorderSide(color: kDimGrey, width: 0.5),
  borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
);
```

This is pre-declared as `containerBorder` in `lib/utils/constants.dart` — import and use directly.

### Typical card padding

```dart
padding: EdgeInsets.all(kDefaultPadding)
// or
padding: EdgeInsets.symmetric(
  horizontal: kDefaultPadding,
  vertical: kDefaultPadding / 2,
)
```

### `ContentContainer` / `DottedContainer`

Pre-built container widgets in `lib/views/widgets/` — glass-aware, use these before rolling a custom container.

---

## Shared Widgets Inventory

Reach for these before building something new:

### Buttons & Icons

| Widget                        | File                                      | Use                                       |
| ----------------------------- | ----------------------------------------- | ----------------------------------------- |
| `CustomIconButton`            | `widgets/custom_icon_buttons.dart`        | All icon-only actions; supports `isGlass` |
| `CustomIconButtonWithTooltip` | `widgets/custom_icon_buttons.dart`        | Icon button with long-press tooltip       |
| `BorderedIconButton`          | `widgets/buttons_containers_widgets.dart` | Icon with circular border                 |
| `NewBorderedIconButton`       | `widgets/buttons_containers_widgets.dart` | Updated bordered icon variant             |
| `StatusButton`                | `widgets/buttons_containers_widgets.dart` | Pill-shaped status/tag button             |

### Containers & Cards

| Widget                 | File                                      | Use                                  |
| ---------------------- | ----------------------------------------- | ------------------------------------ |
| `ContentContainer`     | `widgets/content_container.dart`          | Feed card container, glass-aware     |
| `DottedContainer`      | `widgets/dotted_container.dart`           | Dotted-border container, glass-aware |
| `InfoRoundedContainer` | `widgets/buttons_containers_widgets.dart` | Rounded info box                     |
| `PubKeyContainer`      | `widgets/buttons_containers_widgets.dart` | Pubkey/address display pill          |
| `DotContainer`         | `widgets/buttons_containers_widgets.dart` | Small status dot                     |

### Empty / Loading States

| Widget          | File                              | Use                                                |
| --------------- | --------------------------------- | -------------------------------------------------- |
| `LoadingWidget` | `widgets/loading_indicators.dart` | Full-screen / section loading state (pulsing logo) |

**Loading spinner rule:** Never use `CircularProgressIndicator`. For all inline/button/small loading indicators use `SpinKitCircle` from `package:flutter_spinkit/flutter_spinkit.dart`. Standard usage:

```dart
SpinKitCircle(color: Theme.of(context).primaryColorDark, size: 32) // full-area center
SpinKitCircle(color: theme.primaryColorDark, size: 20)              // inline / button
```

| `HorizontalViewModeWidget` | `widgets/no_content_widgets.dart` | Horizontal empty state with CTA |
| `VerticalViewModeWidget` | `widgets/no_content_widgets.dart` | Vertical empty state with CTA |
| `WrongView` | `widgets/no_content_widgets.dart` | Error / unexpected state |
| `NoInternetView` | `widgets/no_content_widgets.dart` | No connectivity full-view |
| `NoInternetRow` | `widgets/no_content_widgets.dart` | No connectivity inline row |

### Content Display

| Widget               | File                                | Use                        |
| -------------------- | ----------------------------------- | -------------------------- |
| `ArticleContainer`   | `widgets/article_container.dart`    | Article feed card          |
| `CurationContainer`  | `widgets/curation_container.dart`   | Curation feed card         |
| `FlashNewsContainer` | `widgets/flash_news_container.dart` | Flash news card            |
| `CommonThumbnail`    | `widgets/common_thumbnail.dart`     | Image thumbnail            |
| `ContentStats`       | `widgets/content_stats.dart`        | Reactions/zaps/replies row |
| `MarkDownWidget`     | `widgets/mark_down_widget.dart`     | Rendered markdown          |
| `LinkPreviewer`      | `widgets/link_previewer.dart`       | URL card preview           |

### Navigation & App Bars

| Widget              | File                                      | Use                               |
| ------------------- | ----------------------------------------- | --------------------------------- |
| `CustomAppBar`      | `widgets/custom_app_bar.dart`             | Standard app bar                  |
| `GlassAppBarInset`  | `widgets/glass_appbar_inset.dart`         | Top inset provider for glass mode |
| `ResetScrollButton` | `widgets/buttons_containers_widgets.dart` | FAB to scroll back to top         |

### Animated

| Widget                | File                                             | Use                             |
| --------------------- | ------------------------------------------------ | ------------------------------- |
| `AnimatedFlipCounter` | `widgets/animated_flip_counter.dart`             | Number counter animation        |
| `AnimatedPulseLine`   | `widgets/animated_components/animated_line.dart` | Pulsing line indicator          |
| `GlassButton`         | `widgets/animated_components/glass_button.dart`  | Rotating-border animated button |

---

## App Bar Guidelines

- Use `CustomAppBar` for all secondary views (push routes)
- Main view app bar is `GlassMainViewAppBar` (glass) or the standard `MainViewAppBar`
- App bar height is always `kToolbarHeight` (Flutter standard = 56)
- In glass mode, use `GlassAppBarInset.of(context)` to get the current top inset for content padding

---

## Responsive Sizing

The app uses the **sizer** package. Use `x.w` (percent of screen width) and `x.h` (percent of screen height) for responsive dimensions:

```dart
width: 90.w   // 90% of screen width
height: 5.h   // 5% of screen height
```

Use `x.sp` for font sizes only if the text must scale with screen size (rare — prefer textTheme).

---

## State & Widget Patterns

- Prefer `HookWidget` over `StatefulWidget` for local ephemeral state
- Access global cubits/repos directly from `lib/utils/utils.dart` (no `context.read<>()` needed for one-off calls)
- Use `BlocBuilder<XCubit, XState>` only when the widget must rebuild when state changes
- Use `BlocConsumer` only when you need both `builder` and `listener`

---

## View Scaffold Template

A typical secondary view scaffold:

```dart
Scaffold(
  appBar: CustomAppBar(/* ... */),
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: /* content */,
    ),
  ),
)
```

For glass mode, the bottom inset must be added manually — see `GLASS_IMPLEMENTATION.md`.
