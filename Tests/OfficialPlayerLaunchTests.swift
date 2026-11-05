import AppKit

private var failureCleanup: (() -> Void)?

private func require(_ condition: Bool, _ message: String) {
    guard condition else {
        fputs("FAIL: \(message)\n", stderr)
        failureCleanup?()
        exit(1)
    }
}

private final class ProbeDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.global().async {
            let args = CommandLine.arguments
            require(args.count == 3 && args[1] == "-protocolString", "Protocol argument delivery")
            let url = URLComponents(string: args[2])!
            let values = Dictionary(uniqueKeysWithValues: url.queryItems!.map { ($0.name, $0.value!) })
            require(values["ticket"] == "fake + & \" $() only", "Protocol argument preserved")
            try! Data("passed".utf8).write(to: URL(fileURLWithPath: values["result"]!), options: .atomic)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { NSApp.terminate(nil) }
        }
    }
}

@main
enum OfficialPlayerLaunchTests {
    static func main() throws {
        if CommandLine.arguments.contains("-protocolString") {
            let app = NSApplication.shared
            app.setActivationPolicy(.accessory)
            let delegate = ProbeDelegate()
            app.delegate = delegate
            withExtendedLifetime(delegate) { app.run() }
            return
        }
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let launcher = OfficialPlayerLauncher()
        var players: [NSRunningApplication] = []
        defer { for player in players where !player.isTerminated { player.terminate() } }
        for slot in 1...2 {
            let app = root.appendingPathComponent("Session \(slot).app")
            var link = URLComponents(string: "roblox-player://test-only")!
            link.queryItems = [URLQueryItem(name: "ticket", value: "fake + & \" $() only"),
                               URLQueryItem(name: "result", value: root.appendingPathComponent("result\(slot)").path)]
            let profile = root.appendingPathComponent("profile\(slot)")
            try FileManager.default.createDirectory(at: profile, withIntermediateDirectories: true)
            launcher.launch(app: app, profile: profile, link: link.url!) { running, error in
                require(error == nil && running != nil, "Player registered: \(error?.localizedDescription ?? "missing app")")
                require(running!.bundleURL?.standardizedFileURL == app.standardizedFileURL, "Exact application path")
                require(running!.bundleIdentifier == "com.rbxmulti.launch-probe.slot\(slot)", "Exact application identity")
                require(!players.contains { $0.processIdentifier == running!.processIdentifier }, "Distinct process")
                players.append(running!)
            }
        }
        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            if players.count == 2 && (1...2).allSatisfy({
                (try? String(contentsOf: root.appendingPathComponent("result\($0)"), encoding: .utf8)) == "passed"
            }) { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        require(players.count == 2, "Both player identities registered")
        for slot in 1...2 {
            require((try? String(contentsOf: root.appendingPathComponent("result\(slot)"), encoding: .utf8)) == "passed", "Child \(slot) completed")
        }
        failureCleanup = nil
        print("PASS: two direct-launch players, exact identities and protocol arguments")
    }
}
