import AppKit
import SwiftUI

@main
struct WindowBehaviorTests {
    static func main() {
        var state = WindowPresentation()
        state.finishStartup()
        precondition(state.isVisible)
        state.receiveLink()
        precondition(!state.isVisible)
        state.openExplicitly()
        precondition(state.isVisible)
        state.hide()
        state.receiveLink()
        precondition(!state.isVisible)
        var cold = WindowPresentation()
        cold.receiveLink()
        cold.finishStartup()
        precondition(!cold.isVisible)

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let fake = Model(startServices: false)
        var handled = 0
        let delegate = AppDelegate(model: fake, managesServices: false) { _ in handled += 1 }
        app.delegate = delegate
        // Exercise real delegate + NSWindow behavior, never launch Roblox or
        // claim protocol handlers. Synthetic links are delivered to a test sink.
        let link = URL(string: "roblox-player://test-only")!
        delegate.application(app, open: [link])
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        precondition(handled == 1)
        precondition(!app.windows.contains { $0.identifier?.rawValue == "RbxMulti.accounts" && $0.isVisible })
        delegate.showAccounts()
        let window = app.windows.first { $0.identifier?.rawValue == "RbxMulti.accounts" }!
        precondition(window.isVisible)
        delegate.application(app, open: [link, link])
        precondition(handled == 3 && !window.isVisible)
        delegate.showAccounts()
        window.performClose(nil)
        precondition(!window.isVisible)
        delegate.application(app, open: [link])
        precondition(handled == 4 && !window.isVisible)
        _ = delegate.applicationShouldHandleReopen(app, hasVisibleWindows: false)
        precondition(window.isVisible)
        delegate.hideAccounts()
        print("PASS: cold-link launch stays windowless, repeated links hide the manager, close keeps the app alive, explicit reopen restores the window")
    }
}
