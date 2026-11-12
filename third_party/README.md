# Local UI dependencies

These are the published `liquid_glass_widgets` 1.4.4 and `pull_down_button`
0.10.2 sources, including their original licenses. YakiHonne disables their
hover-only visual effects on desktop in `glass_focus_region.dart` and
`pull_down_button/lib/src/_internals/button.dart`. Android and iOS retain the
published hover behavior. Pointer clicks, cursors, pressed states and keyboard
focus remain enabled. Reapply or upstream these small patches when updating
either dependency.

`GlassTextField` also exposes `showFocusRing` (defaulting to true), allowing the
desktop search field to suppress its blue ring without changing text focus.
