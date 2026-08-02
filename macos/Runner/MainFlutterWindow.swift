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
    // Below 720pt the layout falls back to the MOBILE breakpoint, which is not
    // a shape this window should ever be resizable into.
    self.minSize = NSSize(width: 720, height: 600)
    // AppKit persists and restores the frame across launches for us — no plugin
    // needed. ponytail: the first-launch default size is left to AppKit; setting
    // it explicitly here gets overridden by something later in window setup and
    // it only matters until the user resizes once.
    self.setFrameAutosaveName("YakiHonneMainWindow")

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
