import AppKit
import Foundation
import Darwin

final class OfficialPlayerLauncher {
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

    func launch(app: URL, profile: URL, link: URL, completion: @escaping (NSRunningApplication?, Error?) -> Void) {
        precondition(Thread.isMainThread)
        let process = Process()
        process.executableURL = app.appendingPathComponent("Contents/MacOS/RobloxPlayer")
        process.arguments = ["-protocolString", link.absoluteString]
        var environment = ProcessInfo.processInfo.environment
        environment["CFFIXED_USER_HOME"] = profile.path
        process.environment = environment
        process.standardInput = FileHandle.nullDevice
        // Launch URLs contain authentication material. Never pipe them into
        // the manager's Activity feed or diagnostics.
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { [weak self] child in
            DispatchQueue.main.async { self?.processes.removeValue(forKey: child.processIdentifier) }
        }
        do {
            if sem_unlink("/RobloxPlayerUniq") != 0 && errno != ENOENT {
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            }
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
