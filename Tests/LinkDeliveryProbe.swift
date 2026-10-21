import AppKit

/// Launched by `open -a` to exercise real Launch Services URL delivery.
@main
enum LinkDeliveryProbe {
    static func main() {
        guard CommandLine.arguments.count == 3 else { exit(2) }
        let resultPath = CommandLine.arguments[1]
        let warm = CommandLine.arguments[2] == "warm"
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        var links = 0
        var initiallyVisible = false
        let delegate = AppDelegate(model: Model(startServices: false), managesServices: false) { _ in links += 1 }
        app.delegate = delegate
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            initiallyVisible = app.windows.contains { $0.identifier?.rawValue == "RbxMulti.accounts" && $0.isVisible }
        }
        Timer.scheduledTimer(withTimeInterval: warm ? 3 : 1, repeats: false) { _ in
            let visible = app.windows.contains { $0.identifier?.rawValue == "RbxMulti.accounts" && $0.isVisible }
            let result: [String: Any] = ["links": links, "initiallyVisible": initiallyVisible, "finallyVisible": visible]
            try! JSONSerialization.data(withJSONObject: result, options: .prettyPrinted).write(to: URL(fileURLWithPath: resultPath))
            app.terminate(nil)
        }
        withExtendedLifetime(delegate) { app.run() }
    }
}
