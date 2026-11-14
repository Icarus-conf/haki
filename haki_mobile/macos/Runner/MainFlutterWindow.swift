import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(NSRect(x: windowFrame.minX, y: windowFrame.minY, width: 1280, height: 820), display: true)
    self.center()
    // Dark title bar that blends into the app
    self.title = "Haki"
    self.minSize = NSSize(width: 820, height: 560)
    self.titlebarAppearsTransparent = true
    self.appearance = NSAppearance(named: .darkAqua)
    self.backgroundColor = NSColor(red: 0x08 / 255, green: 0x08 / 255, blue: 0x0C / 255, alpha: 1)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
