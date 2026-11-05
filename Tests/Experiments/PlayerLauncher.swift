import AppKit
import Foundation

/// Restricts only the launched process and its children. It does not edit
/// Keychain items, their access lists, or the user's Keychain search order.
enum PlayerLaunchPolicy {
    static let profile = """
    (version 1)
    (allow default)
    (deny file-read* file-write*
        (subpath (param "USER_KEYCHAINS"))
        (subpath (param "RESOLVED_USER_KEYCHAINS")))
    """

    static func arguments(app: URL, link: URL, keychains: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Keychains", isDirectory: true)) -> [String] {
        ["-D", "USER_KEYCHAINS=" + keychains.standardizedFileURL.path,
         "-D", "RESOLVED_USER_KEYCHAINS=" + keychains.resolvingSymlinksInPath().standardizedFileURL.path,
         "-p", profile,
         app.appendingPathComponent("Contents/MacOS/RobloxPlayer").path,
         "-protocolString", link.absoluteString]
    }
}

final class PlayerLauncher {
    enum Failure: LocalizedError {
        case unavailable, exited, registrationTimedOut
        var errorDescription: String? {
            switch self {
            case .unavailable: return "This Mac cannot start a Keychain-isolated player. No unrestricted fallback was launched."
            case .exited: return "The isolated Roblox player exited before it finished opening."
            case .registrationTimedOut: return "Roblox started but could not be identified. Check its window before trying again."
            }
        }
    }

    // Keeping Process alive also keeps its termination callback alive. Quitting
    // the manager releases these references without terminating the players.
    private var processes: [pid_t: Process] = [:]

    func launch(app: URL, link: URL, completion: @escaping (NSRunningApplication?, Error?) -> Void) {
        precondition(Thread.isMainThread)
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/sandbox-exec") else {
            completion(nil, Failure.unavailable)
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sandbox-exec")
        process.arguments = PlayerLaunchPolicy.arguments(app: app, link: link)
        // Launch URLs contain authentication material. Never pipe them into
        // the manager's Activity feed or diagnostics.
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { [weak self] child in
            DispatchQueue.main.async { self?.processes.removeValue(forKey: child.processIdentifier) }
        }
        do {
            try process.run()
            processes[process.processIdentifier] = process
            identify(process, deadline: Date().addingTimeInterval(15), completion: completion)
        } catch {
            completion(nil, error)
        }
    }

    private func identify(_ process: Process, deadline: Date,
                          completion: @escaping (NSRunningApplication?, Error?) -> Void) {
        guard process.isRunning else {
            completion(nil, Failure.exited)
            return
        }
        if let app = NSRunningApplication(processIdentifier: process.processIdentifier),
           app.bundleURL != nil, app.bundleIdentifier != nil, app.isFinishedLaunching {
            completion(app, nil)
        } else if Date() >= deadline {
            completion(nil, Failure.registrationTimedOut)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
                identify(process, deadline: deadline, completion: completion)
            }
        }
    }
}
