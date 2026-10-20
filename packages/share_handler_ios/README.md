# share_handler_ios

## YakiHonne local fork

Vendored from `share_handler_ios` 0.0.15 with its original license. The root
app selects this package through a `dependency_overrides` path entry.

The native model controller adds one open async hook,
`customSharedContent(for:)`, before its ordinary attachment routing. Returning
a string reuses the existing App Group text handoff; returning `nil` preserves
generic sharing. Extension completion now runs after asynchronous attachment
processing instead of in `viewDidAppear`.

YakiHonne's share controller uses this hook to read Safari JavaScript
preprocessing results from an `NSItemProvider` property-list attachment. Its
non-open lifecycle methods are intentionally not overridden. Preserve these
two patches when upgrading the upstream package. No pub-cache edits are needed.

## Upstream usage

This is an implementation of the `share_handler_platform_interface` package for iOS.

## Usage

### With the `share_handler` plugin

This package is the endorsed implementation of the `share_handler` plugin, so it gets automatically added to your [dependencies](https://flutter.dev/platform-plugins/) by adding the `share_handler` package to your `pubspec.yaml`:

```yaml
dependencies:
  share_handler:
```
