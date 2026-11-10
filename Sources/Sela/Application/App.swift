import AppKit

@main
enum SelaApplication {
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--smoke-test") {
            print("Sela: starting UI smoke test")
            fflush(nil)
        }
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        application.delegate = delegate
        if delegate.isOffscreenTesting {
            delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
            return
        }
        withExtendedLifetime(delegate) { application.run() }
    }
}
