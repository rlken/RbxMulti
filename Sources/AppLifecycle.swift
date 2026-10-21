import AppKit
import SwiftUI

/// URL delivery is work, not a request to show the manager.
struct WindowPresentation {
    private(set) var receivedLaunchLink = false
    private(set) var isVisible = false
    mutating func finishStartup() { isVisible = !receivedLaunchLink }
    mutating func receiveLink() { receivedLaunchLink = true; isVisible = false }
    mutating func openExplicitly() { isVisible = true }
    mutating func hide() { isVisible = false }
}

final class LauncherWindow: NSWindowController, NSWindowDelegate {
    init(content: AnyView) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 610),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "RbxMulti"
        window.identifier = NSUserInterfaceItemIdentifier("RbxMulti.accounts")
        window.minSize = NSSize(width: 620, height: 510)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: content)
        window.center()
        super.init(window: window)
        window.delegate = self
        window.setFrameAutosaveName("RbxMultiAccounts-v2")
    }
    required init?(coder: NSCoder) { fatalError("Not supported") }
    func present() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    func conceal() { window?.orderOut(nil) }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        conceal()
        return false
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let model: Model
    private let managesServices: Bool
    private let linkHandler: (URL) -> Void
    private var started = false
    private var pending: [URL] = []
    private var presentation = WindowPresentation()
    private var controller: LauncherWindow?
    private var statusItem: NSStatusItem?
    private let countItem = NSMenuItem(title: "No players running", action: nil, keyEquivalent: "")

    init(model: Model = .shared, managesServices: Bool = true, linkHandler: ((URL) -> Void)? = nil) {
        self.model = model
        self.managesServices = managesServices
        self.linkHandler = linkHandler ?? { model.launch($0) }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMenuBar()
        if managesServices { model.claimLinks() }
        // No automatic SwiftUI Window scene: cold URL launches stay windowless.
        DispatchQueue.main.async {
            self.started = true
            self.presentation.finishStartup()
            if self.presentation.isVisible { self.showAccounts() }
            self.pending.forEach(self.linkHandler)
            self.pending.removeAll()
            if self.managesServices { self.model.refresh() }
        }
    }

    private func installMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "rectangle.stack", accessibilityDescription: "RbxMulti")
        item.button?.toolTip = "RbxMulti — account manager"
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(countItem)
        menu.addItem(.separator())
        for (title, action, key) in [("Show accounts", #selector(showAccounts), ""),
                                     ("Hide window", #selector(hideAccounts), ""),
                                     ("Quit RbxMulti", #selector(quit), "q")] {
            let entry = NSMenuItem(title: title, action: action, keyEquivalent: key)
            entry.target = self
            menu.addItem(entry)
        }
        item.menu = menu
        statusItem = item
        // Standard editing shortcuts continue to work in native text fields.
        let main = NSMenu()
        let appMenu = NSMenuItem()
        let appSubmenu = NSMenu()
        appSubmenu.addItem(withTitle: "Quit RbxMulti", action: #selector(quit), keyEquivalent: "q").target = self
        appMenu.submenu = appSubmenu
        main.addItem(appMenu)
        let edit = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        for (title, action, key) in [("Cut", "cut:", "x"), ("Copy", "copy:", "c"),
                                     ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            editMenu.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        edit.submenu = editMenu
        main.addItem(edit)
        NSApp.mainMenu = main
    }

    func menuWillOpen(_ menu: NSMenu) {
        let count = model.runningCount
        countItem.title = "\(count) \(count == 1 ? "player" : "players") running"
    }

    @objc func showAccounts() {
        presentation.openExplicitly()
        if controller == nil {
            controller = LauncherWindow(content: AnyView(ContentView(model: model, hide: { [weak self] in self?.hideAccounts() })))
        }
        controller?.present()
    }
    @objc func hideAccounts() { presentation.hide(); controller?.conceal() }
    @objc private func quit() { NSApp.terminate(nil) }

    func application(_ application: NSApplication, open urls: [URL]) {
        presentation.receiveLink()
        controller?.conceal()
        if started { urls.forEach(linkHandler) } else { pending += urls }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        // A Finder/app-icon reopen is explicit; receiving a URL is not.
        if NSAppleEventManager.shared().currentAppleEvent?.eventID != 0x4755524C { showAccounts() }
        return false
    }
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { if managesServices { model.stopWakeLock() } }
}

#if !RBXMULTI_TESTING
@main
enum RbxMultiApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        withExtendedLifetime(delegate) { application.run() }
    }
}
#endif
