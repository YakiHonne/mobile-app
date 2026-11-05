import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Must run after super, which re-applies the nib's frame.
    // Two 520-point panes, a 1-point divider, the 72-point compact rail,
    // and 40 points of horizontal shell padding.
    self.minSize = NSSize(width: 1153, height: 600)
    // AppKit persists and restores the frame across launches for us — no plugin
    // needed. ponytail: the first-launch default size is left to AppKit; setting
    // it explicitly here gets overridden by something later in window setup and
    // it only matters until the user resizes once.
    self.setFrameAutosaveName("YakiHonneMainWindow")
    // An older saved window may already be narrower than the new minimum.
    if self.frame.width < self.minSize.width {
      var frame = self.frame
      frame.size.width = self.minSize.width
      self.setFrame(frame, display: true)
    }

    // The titlebar stays (traffic lights, drag, double-click-to-zoom) but stops
    // painting: no chrome, no separator, no title, and the Flutter view spans
    // its height so the strip shows the app's own glass background. Dart keeps
    // content clear of the buttons via kMacTitlebarInset.
    // ponytail: no isMovableByWindowBackground — AppKit would steal drags from
    // Flutter scrolling and text selection app-wide. The titlebar's own empty
    // region is draggable regardless.
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
  }
}
