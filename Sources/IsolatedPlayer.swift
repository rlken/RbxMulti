import Foundation

/// Each concurrently running player needs its own macOS cookie-store identity.
/// Changing the path alone does not isolate NSHTTPCookieStorage.
enum IsolatedPlayer {
    static let bundlePrefix = "com.rbxmulti.player.slot"
    static let root = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/RbxMulti/Players", isDirectory: true)

    struct SigningIdentity {
        let certificateSHA1: String

        init(certificateSHA1: String) throws {
            guard certificateSHA1.range(of: "^[0-9A-Fa-f]{40}$", options: .regularExpression) != nil else {
                throw Failure.invalidSigningIdentity
            }
            self.certificateSHA1 = certificateSHA1.uppercased()
        }

        func requirement(bundleID: String) -> String {
            // A real certificate pin, not an identifier-only trust rule.
            "identifier \"\(bundleID)\" and certificate leaf = H\"\(certificateSHA1)\""
        }

        static func configured() throws -> SigningIdentity? {
            let file = root.deletingLastPathComponent().appendingPathComponent("Signing/identity.plist")
            guard FileManager.default.fileExists(atPath: file.path) else { return nil }
            let data = try Data(contentsOf: file)
            guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let hash = plist["certificateSHA1"] as? String else { throw Failure.invalidSigningIdentity }
            return try SigningIdentity(certificateSHA1: hash)
        }
    }

    struct Prepared {
        let url: URL
        let bundleID: String
    }

    enum Failure: LocalizedError {
        case invalidSource, occupiedSlot, invalidSigningIdentity, signingFailed, command(String)
        var errorDescription: String? {
            switch self {
            case .invalidSource: return "The installed Roblox app could not be read. Reinstall Roblox and try again."
            case .occupiedSlot: return "This session is already running. Its files were left unchanged; click Play again to use a free session."
            case .invalidSigningIdentity: return "The local signing configuration is invalid. Repair it before launching another session."
            case .signingFailed: return "Local session signing failed. Check any macOS signing-key prompt or repair the configured certificate. No temporary-signature fallback was used."
            case .command(let tool): return "Could not prepare the separate Roblox session (\(tool))."
            }
        }
    }

    static func bundleID(slot: Int) -> String { "\(bundlePrefix)\(slot)" }

    // An official auto-update can replace Info.plist and reset the bundle ID.
    // The on-disk slot is still occupied even when its ID no longer matches.
    static func slotID(at app: URL, directory: URL = root) -> String? {
        let path = app.resolvingSymlinksInPath().standardizedFileURL
        let parent = path.deletingLastPathComponent()
        guard path.lastPathComponent == "Roblox.app",
              parent.deletingLastPathComponent().path == directory.resolvingSymlinksInPath().standardizedFileURL.path,
              parent.lastPathComponent.hasPrefix("slot"),
              let slot = Int(parent.lastPathComponent.dropFirst(4)), slot > 0,
              parent.lastPathComponent == "slot\(slot)" else { return nil }
        return bundleID(slot: slot)
    }

    static func occupiedIDs(bundleIDs: [String], appURLs: [URL], directory: URL = root) -> Set<String> {
        Set(bundleIDs).union(appURLs.compactMap { slotID(at: $0, directory: directory) })
    }

    static func metadata(at app: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: app.appendingPathComponent("Contents/Info.plist")) else { return nil }
        return try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    }

    static func isLocalSignedCopy(_ app: URL, identity: SigningIdentity?, directory: URL) -> Bool {
        guard let identity, let id = slotID(at: app, directory: directory),
              metadata(at: app)?["CFBundleIdentifier"] as? String == id else { return false }
        return (try? run("/usr/bin/codesign", ["--verify", "--deep", "--strict", "-R",
            "=" + identity.requirement(bundleID: id), app.path])) != nil
    }

    // Once an updated private copy is signed locally, it still needs to be
    // reusable as a source. Otherwise an older /Applications install wins on
    // the next launch and starts another update/re-signing cycle.
    static func latestSource(installed: URL, directory: URL = root, signingIdentity: SigningIdentity? = nil) -> URL {
        let slots = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        var best = installed
        var version = metadata(at: installed)?["CFBundleShortVersionString"] as? String ?? "0"
        for folder in slots.sorted(by: { $0.path < $1.path }) {
            let app = folder.appendingPathComponent("Roblox.app", isDirectory: true)
            guard slotID(at: app, directory: directory) != nil,
                  let info = metadata(at: app),
                  info["CFBundleExecutable"] as? String == "RobloxPlayer",
                  let candidate = info["CFBundleShortVersionString"] as? String,
                  candidate.compare(version, options: .numeric) == .orderedDescending else { continue }
            let official = info["CFBundleIdentifier"] as? String == "com.roblox.RobloxPlayer"
                && (try? run("/usr/bin/codesign", ["--verify", "--deep", "--strict", "-R",
                    "=anchor apple generic and identifier \"com.roblox.RobloxPlayer\" and certificate leaf[subject.OU] = \"2CFABCH843\"", app.path])) != nil
            guard official || isLocalSignedCopy(app, identity: signingIdentity, directory: directory) else { continue }
            best = app
            version = candidate
        }
        return best
    }

    static func availableSlot(occupied: Set<String>) -> Int {
        var slot = 1
        while occupied.contains(bundleID(slot: slot)) { slot += 1 }
        return slot
    }

    static func run(_ executable: String, _ arguments: [String]) throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try task.run()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else {
            throw Failure.command(URL(fileURLWithPath: executable).lastPathComponent)
        }
    }

    /// Called on a worker queue, only for a slot with no live player.
    /// Cached copies are rebuilt when the official player's version/files change.
    static func prepare(source: URL, slot: Int, directory: URL = root, runningAppURLs: [URL] = [],
                        signingIdentity: SigningIdentity? = nil) throws -> Prepared {
        guard !runningAppURLs.contains(where: { slotID(at: $0, directory: directory) == bundleID(slot: slot) }) else {
            throw Failure.occupiedSlot
        }
        let fm = FileManager.default
        let info = source.appendingPathComponent("Contents/Info.plist")
        let sourceData = try Data(contentsOf: info)
        guard var plist = try PropertyListSerialization.propertyList(from: sourceData, format: nil) as? [String: Any],
              (plist["CFBundleIdentifier"] as? String == "com.roblox.RobloxPlayer"
               || isLocalSignedCopy(source, identity: signingIdentity, directory: directory)),
              let executable = plist["CFBundleExecutable"] as? String,
              executable == "RobloxPlayer" else { throw Failure.invalidSource }
        let attributes = try fm.attributesOfItem(atPath: source.appendingPathComponent("Contents/MacOS/\(executable)").path)
        let fingerprint: [String: Any] = [
            "info": sourceData,
            "size": attributes[.size] ?? 0,
            "modified": attributes[.modificationDate] ?? Date.distantPast,
            "formatVersion": 2,
            "signingCertificate": signingIdentity?.certificateSHA1 ?? "ad-hoc"
        ]
        let fingerprintData = try PropertyListSerialization.data(fromPropertyList: fingerprint, format: .binary, options: 0)
        let slotRoot = directory.appendingPathComponent("slot\(slot)", isDirectory: true)
        try fm.createDirectory(at: slotRoot, withIntermediateDirectories: true,
                               attributes: [.posixPermissions: 0o700])
        let app = slotRoot.appendingPathComponent("Roblox.app", isDirectory: true)
        let marker = slotRoot.appendingPathComponent("source.plist")
        let id = bundleID(slot: slot)
        let savedFingerprint = (try? Data(contentsOf: marker)).flatMap {
            try? PropertyListSerialization.propertyList(from: $0, format: nil) as? NSDictionary
        }
        var verification = ["--verify", "--deep", "--strict"]
        if let identity = signingIdentity {
            verification += ["-R", "=" + identity.requirement(bundleID: id)]
        }
        if savedFingerprint == fingerprint as NSDictionary,
           metadata(at: app)?["CFBundleIdentifier"] as? String == id,
           (try? run("/usr/bin/codesign", verification + [app.path])) != nil {
            return Prepared(url: app, bundleID: id)
        }

        // Stage a complete verified copy before replacing an idle slot. Never
        // edit /Applications/Roblox.app or copy any existing account cookies.
        let staging = slotRoot.appendingPathComponent("prepare-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? fm.removeItem(at: staging) }
        let stagedApp = staging.appendingPathComponent("Roblox.app", isDirectory: true)
        do {
            // APFS copy-on-write avoids duplicating the large asset files.
            try run("/bin/cp", ["-cR", source.path, stagedApp.path])
        } catch {
            if fm.fileExists(atPath: stagedApp.path) { try fm.removeItem(at: stagedApp) }
            try fm.copyItem(at: source, to: stagedApp)
        }
        plist["CFBundleIdentifier"] = id
        plist["CFBundleDisplayName"] = "Roblox — Session \(slot)"
        plist["LSMultipleInstancesProhibited"] = false
        plist["NSAppSleepDisabled"] = true
        // Private copies must not take over browser links from RbxMulti.
        plist.removeValue(forKey: "CFBundleURLTypes")
        let output = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try output.write(to: stagedApp.appendingPathComponent("Contents/Info.plist"), options: .atomic)
        if let identity = signingIdentity {
            do {
                // Sign nested helpers with their own identifiers, then give the
                // outer player its stable per-slot ID and certificate pin.
                try run("/usr/bin/codesign", ["--force", "--deep", "--timestamp=none", "--sign", identity.certificateSHA1, stagedApp.path])
                try run("/usr/bin/codesign", ["--force", "--timestamp=none", "--sign", identity.certificateSHA1,
                    "--identifier", id, "--requirements", "=designated => " + identity.requirement(bundleID: id), stagedApp.path])
            } catch { throw Failure.signingFailed }
        } else {
            try run("/usr/bin/codesign", ["--force", "--deep", "--sign", "-", stagedApp.path])
        }
        try run("/usr/bin/codesign", verification + [stagedApp.path])

        // This folder is an app-generated cache, with no login data inside it.
        if fm.fileExists(atPath: app.path) { try fm.removeItem(at: app) }
        try fm.moveItem(at: stagedApp, to: app)
        try fingerprintData.write(to: marker, options: .atomic)
        return Prepared(url: app, bundleID: id)
    }
}
