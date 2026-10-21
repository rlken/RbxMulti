import AppKit
import SwiftUI

/// Native rendering fixtures: synthetic accounts, no Roblox or network access.
@main
struct RenderViews {
    static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for (name, width, height, dark, empty) in [
            ("accounts-dark", 720.0, 580.0, true, false),
            ("accounts-light-compact", 620.0, 480.0, false, false),
            ("empty-light", 720.0, 580.0, false, true)
        ] {
            let model = Model(startServices: false)
            if !empty {
                model.items = [
                    Instance(name: "ExampleAccount", pid: -1, started: Date().addingTimeInterval(-3720), userID: 1),
                    Instance(name: "A_long_account_name_to_test_truncation", pid: -2, started: Date().addingTimeInterval(-1800), userID: 2, isolationLost: true),
                    Instance(name: "Account 3", pid: -3, started: Date().addingTimeInterval(-100))
                ]
                model.message = "Session 3 has its own login storage."
            }
            app.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
            let view = NSHostingView(rootView: ContentView(model: model, hide: {}).environment(\.colorScheme, dark ? .dark : .light))
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height), styleMask: [.borderless], backing: .buffered, defer: false)
            window.appearance = app.appearance
            window.contentView = view
            view.frame = NSRect(x: 0, y: 0, width: width, height: height)
            view.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.15))
            guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { fatalError("No bitmap") }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("No PNG") }
            try data.write(to: output.appendingPathComponent(name + ".png"))
        }
        print("Rendered native light, dark, compact, warning, missing-avatar, and empty states.")
    }
}
