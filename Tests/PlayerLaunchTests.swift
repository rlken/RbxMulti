import AppKit
import Security

private var failureCleanup: (() -> Void)?

private func require(_ condition: Bool, _ message: String) {
    guard condition else {
        fputs("FAIL: \(message)\n", stderr)
        failureCleanup?()
        exit(1)
    }
}

private func item(_ service: String) -> [String: Any] {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: service, kSecAttrAccount as String: "disposable-test"]
}

private func readDummy(_ service: String) -> Bool {
    var query = item(service)
    query[kSecReturnData as String] = true
    var result: CFTypeRef?
    return SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess
        && result as? Data == Data("not-a-real-credential".utf8)
}

private final class ProbeDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.global().async {
            let args = CommandLine.arguments
            require(args.count == 3 && args[1] == "-protocolString", "Protocol argument delivery")
            let url = URLComponents(string: args[2])!
            let values = Dictionary(uniqueKeysWithValues: url.queryItems!.map { ($0.name, $0.value!) })
            require(values["ticket"] == "fake + & \" $() only", "Protocol argument preserved")
            if let service = values["service"] {
                require(service.hasPrefix("com.rbxmulti.isolation-probe."), "Disposable item only")
                SecKeychainSetUserInteractionAllowed(false)
                var query = item(service)
                query[kSecReturnData as String] = true
                var result: CFTypeRef?
                require(SecItemCopyMatching(query as CFDictionary, &result) != errSecSuccess && result == nil,
                        "Restricted read")
                require(SecItemUpdate(item(service) as CFDictionary,
                                     [kSecValueData as String: Data("changed".utf8)] as CFDictionary) != errSecSuccess,
                        "Restricted update")
                require(SecItemDelete(item(service) as CFDictionary) != errSecSuccess, "Restricted delete")
                let curl = Process()
                curl.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
                curl.arguments = ["--fail", "--silent", "--max-time", "20", "--output", "/dev/null", "https://www.roblox.com/"]
                try! curl.run()
                curl.waitUntilExit()
                require(curl.terminationStatus == 0, "Inherited sandbox permits HTTPS")
            }
            try! Data("passed".utf8).write(to: URL(fileURLWithPath: values["result"]!), options: .atomic)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { NSApp.terminate(nil) }
        }
    }
}

@main
enum PlayerLaunchTests {
    static func main() throws {
        if ["--create-dummy", "--verify-delete-dummy", "--delete-dummy"].contains(CommandLine.arguments[1]) {
            let service = CommandLine.arguments[2]
            let prefix = "com.rbxmulti.isolation-probe."
            require(service.hasPrefix(prefix) && UUID(uuidString: String(service.dropFirst(prefix.count))) != nil,
                    "Disposable service only")
            SecKeychainSetUserInteractionAllowed(false)
            if CommandLine.arguments[1] == "--create-dummy" {
                var query = item(service)
                query[kSecValueData as String] = Data("not-a-real-credential".utf8)
                require(SecItemAdd(query as CFDictionary, nil) == errSecSuccess, "Create dummy")
                require(readDummy(service), "Same executable reads dummy without restriction")
            } else {
                let intact = readDummy(service)
                let status = SecItemDelete(item(service) as CFDictionary)
                require(status == errSecSuccess || status == errSecItemNotFound, "Remove dummy")
                if CommandLine.arguments[1] == "--verify-delete-dummy" { require(intact, "Dummy remains unchanged") }
            }
            return
        }
        if CommandLine.arguments.contains("-protocolString") {
            let app = NSApplication.shared
            app.setActivationPolicy(.accessory)
            let delegate = ProbeDelegate()
            app.delegate = delegate
            withExtendedLifetime(delegate) { app.run() }
            return
        }
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let useKeychain = CommandLine.arguments.contains("--allow-disposable-keychain-item")
        var dummies: [(URL, String)] = []
        func runDummy(_ app: URL, _ mode: String, _ service: String) -> Bool {
            let process = Process()
            process.executableURL = app.appendingPathComponent("Contents/MacOS/RobloxPlayer")
            process.arguments = [mode, service]
            do { try process.run(); process.waitUntilExit(); return process.terminationStatus == 0 }
            catch { return false }
        }
        failureCleanup = {
            for (app, service) in dummies {
                if !runDummy(app, "--delete-dummy", service) { fputs("Cleanup needed for dummy service \(service)\n", stderr) }
            }
        }
        let launcher = PlayerLauncher()
        var players: [NSRunningApplication] = []
        defer { for player in players where !player.isTerminated { player.terminate() } }
        for slot in 1...2 {
            let app = root.appendingPathComponent("Session \(slot).app")
            let service = "com.rbxmulti.isolation-probe." + UUID().uuidString
            if useKeychain {
                dummies.append((app, service))
                require(runDummy(app, "--create-dummy", service), "Unrestricted baseline for exact child executable")
            }
            var link = URLComponents(string: "roblox-player://test-only")!
            link.queryItems = [URLQueryItem(name: "ticket", value: "fake + & \" $() only"),
                               URLQueryItem(name: "result", value: root.appendingPathComponent("result\(slot)").path)]
            if useKeychain { link.queryItems!.append(URLQueryItem(name: "service", value: service)) }
            let args = PlayerLaunchPolicy.arguments(app: app, link: link.url!,
                                                    keychains: root.appendingPathComponent("Keychains with spaces ' \""))
            require(args.last == link.url!.absoluteString && args[args.count - 2] == "-protocolString", "Argument boundaries")
            launcher.launch(app: app, link: link.url!) { running, error in
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
        for (app, service) in dummies {
            require(runDummy(app, "--verify-delete-dummy", service), "Same executable verifies and removes dummy")
        }
        failureCleanup = nil
        print("PASS: two restricted players, exact identities and protocol arguments" + (useKeychain ? ", dummy Keychain blocked, HTTPS works" : ""))
    }
}
