import Foundation

@main
struct SessionIsolationTests {
    static func main() throws {
        let joinA = "2026-10-15T01:43:04Z,1,6 [FLog::GameJoinLoadTime] Report game_join_loadtime: placeid:1, userid:101, universeid:2,"
        let joinB = "2026-10-15T02:15:44Z,2,6 [FLog::GameJoinLoadTime] Report game_join_loadtime: universeid:2, userid:202,"
        let collision = PlayerSessionLog.identity(in: joinA + "\n" + joinB)!
        precondition(collision.initialUserID == 101 && collision.latestUserID == 202 && collision.changedAccount)
        precondition(PlayerSessionLog.identity(in: joinA + "\n" + joinA)?.changedAccount == false)
        precondition(PlayerSessionLog.identity(in: "[FLog::Output] userid:999") == nil)
        precondition(PlayerSessionLog.identity(in: "[FLog::GameJoinLoadTime] Report game_join_loadtime:\nuserid:999") == nil)
        let paths = PlayerSessionLog.logPaths(from: "p41\nn/tmp/a_Player_1_last.log\np42\nn/tmp/b_Player_2_last.log\nn/tmp/b_Player_2_CrashHandler_last.log\n")
        precondition(paths[41]?.lastPathComponent == "a_Player_1_last.log")
        precondition(paths[42]?.lastPathComponent == "b_Player_2_last.log")
        precondition(IsolatedPlayer.availableSlot(occupied: [IsolatedPlayer.bundleID(slot: 1), IsolatedPlayer.bundleID(slot: 2)]) == 3)

        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("RbxMultiTests-\(UUID().uuidString)")
        try fm.createDirectory(at: temp, withIntermediateDirectories: false)
        defer { try? fm.removeItem(at: temp) }
        let source = temp.appendingPathComponent("Source.app")
        try fm.createDirectory(at: source.appendingPathComponent("Contents/MacOS"), withIntermediateDirectories: true)
        try fm.copyItem(at: URL(fileURLWithPath: "/usr/bin/true"), to: source.appendingPathComponent("Contents/MacOS/RobloxPlayer"))
        let plist: [String: Any] = ["CFBundleIdentifier": "com.roblox.RobloxPlayer", "CFBundleExecutable": "RobloxPlayer",
                                    "CFBundleVersion": "1", "CFBundleShortVersionString": "1.0", "CFBundlePackageType": "APPL", "CFBundleURLTypes": [["CFBundleURLSchemes": ["roblox"]]]]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let plistURL = source.appendingPathComponent("Contents/Info.plist")
        try data.write(to: plistURL)
        let root = temp.appendingPathComponent("Slots")
        let occupiedPath = root.appendingPathComponent("slot2/Roblox.app")
        let occupied = IsolatedPlayer.occupiedIDs(bundleIDs: [IsolatedPlayer.bundleID(slot: 1), "com.roblox.RobloxPlayer"],
                                                 appURLs: [occupiedPath], directory: root)
        precondition(IsolatedPlayer.availableSlot(occupied: occupied) == 3,
                     "An updater-reset bundle ID must not make the running slot look free")
        precondition(IsolatedPlayer.slotID(at: temp.appendingPathComponent("slot2/Roblox.app"), directory: root) == nil)
        precondition(IsolatedPlayer.slotID(at: root.appendingPathComponent("slot02/Roblox.app"), directory: root) == nil)
        let a = try IsolatedPlayer.prepare(source: source, slot: 1, directory: root)
        let b = try IsolatedPlayer.prepare(source: source, slot: 2, directory: root)
        do {
            _ = try IsolatedPlayer.prepare(source: source, slot: 2, directory: root, runningAppURLs: [b.url])
            preconditionFailure("A running slot must never be rebuilt")
        } catch IsolatedPlayer.Failure.occupiedSlot { }
        precondition(IsolatedPlayer.latestSource(installed: source, directory: root) == source,
                     "Private re-signed copies are not official update sources")
        precondition(a.bundleID != b.bundleID && a.url != b.url)
        precondition(Bundle(url: a.url)?.bundleIdentifier == a.bundleID)
        precondition(Bundle(url: b.url)?.bundleIdentifier == b.bundleID)
        let edited = try PropertyListSerialization.propertyList(from: Data(contentsOf: a.url.appendingPathComponent("Contents/Info.plist")), format: nil) as! [String: Any]
        precondition(edited["CFBundleURLTypes"] == nil)
        precondition(edited["LSMultipleInstancesProhibited"] as? Bool == false)
        let unchanged = try Data(contentsOf: plistURL)
        precondition(unchanged == data, "Official source must remain untouched")
        try IsolatedPlayer.run("/usr/bin/codesign", ["--verify", "--deep", "--strict", a.url.path])
        let reused = try IsolatedPlayer.prepare(source: source, slot: 1, directory: root)
        precondition(reused.url == a.url)
        // Simulate an updater resetting the ID without changing the cached
        // source fingerprint. Preparation must read fresh on-disk metadata.
        var reset = edited
        reset["CFBundleIdentifier"] = "com.roblox.RobloxPlayer"
        try PropertyListSerialization.data(fromPropertyList: reset, format: .xml, options: 0)
            .write(to: a.url.appendingPathComponent("Contents/Info.plist"))
        _ = try IsolatedPlayer.prepare(source: source, slot: 1, directory: root)
        precondition(IsolatedPlayer.metadata(at: a.url)?["CFBundleIdentifier"] as? String == a.bundleID)
        var newer = plist
        newer["CFBundleVersion"] = "2"
        newer["CFBundleShortVersionString"] = "2.0"
        try PropertyListSerialization.data(fromPropertyList: newer, format: .xml, options: 0).write(to: plistURL)
        let rebuilt = try IsolatedPlayer.prepare(source: source, slot: 1, directory: root)
        let updated = try PropertyListSerialization.propertyList(from: Data(contentsOf: rebuilt.url.appendingPathComponent("Contents/Info.plist")), format: nil) as! [String: Any]
        precondition(updated["CFBundleVersion"] as? String == "2")
        do {
            _ = try IsolatedPlayer.SigningIdentity(certificateSHA1: "not a certificate")
            preconditionFailure("Malformed certificate pins must be rejected")
        } catch IsolatedPlayer.Failure.invalidSigningIdentity { }

        // Explicit opt-in: uses only the dedicated local signing key, never
        // queries real Roblox credentials or edits their access controls.
        if ProcessInfo.processInfo.environment["RBXMULTI_TEST_LOCAL_SIGNING"] == "1" {
            guard let identity = try IsolatedPlayer.SigningIdentity.configured() else {
                throw IsolatedPlayer.Failure.invalidSigningIdentity
            }
            let signed = try IsolatedPlayer.prepare(source: source, slot: 1, directory: root, signingIdentity: identity)
            let executable = signed.url.appendingPathComponent("Contents/MacOS/RobloxPlayer")
            let before = try Data(contentsOf: executable)
            let requirement = "=" + identity.requirement(bundleID: signed.bundleID)
            try IsolatedPlayer.run("/usr/bin/codesign", ["--verify", "--strict", "-R", requirement, signed.url.path])
            let reusedSigned = try IsolatedPlayer.prepare(source: source, slot: 1, directory: root, signingIdentity: identity)
            precondition(reusedSigned.url == signed.url)
            newer["CFBundleVersion"] = "3"
            newer["CFBundleShortVersionString"] = "3.0"
            try PropertyListSerialization.data(fromPropertyList: newer, format: .xml, options: 0).write(to: plistURL)
            _ = try IsolatedPlayer.prepare(source: source, slot: 1, directory: root, signingIdentity: identity)
            let after = try Data(contentsOf: executable)
            precondition(before != after, "Test must actually change the signed build")
            try IsolatedPlayer.run("/usr/bin/codesign", ["--verify", "--strict", "-R", requirement, signed.url.path])
            let other = try IsolatedPlayer.prepare(source: source, slot: 2, directory: root, signingIdentity: identity)
            // A newer signed local copy remains a usable source even after no
            // updated vendor-signed slot remains. Never trust a bare bundle ID.
            let fromLocal = try IsolatedPlayer.prepare(source: signed.url, slot: 3, directory: root, signingIdentity: identity)
            precondition(IsolatedPlayer.isLocalSignedCopy(fromLocal.url, identity: identity, directory: root))
            precondition(!IsolatedPlayer.isLocalSignedCopy(fromLocal.url, identity: nil, directory: root))
            try data.write(to: plistURL) // Simulate an older /Applications copy.
            let chosenSource = IsolatedPlayer.latestSource(installed: source, directory: root, signingIdentity: identity)
            precondition(chosenSource.resolvingSymlinksInPath().path == signed.url.resolvingSymlinksInPath().path)
            precondition(IsolatedPlayer.latestSource(installed: source, directory: root) == source)
            do {
                try IsolatedPlayer.run("/usr/bin/codesign", ["--verify", "-R", requirement, other.url.path])
                preconditionFailure("Another slot must not satisfy this slot's requirement")
            } catch IsolatedPlayer.Failure.command { }
            // Fail closed if a configured certificate disappears; leave the
            // previously prepared player untouched instead of re-signing ad hoc.
            do {
                let missing = try IsolatedPlayer.SigningIdentity(certificateSHA1: String(repeating: "0", count: 40))
                _ = try IsolatedPlayer.prepare(source: source, slot: 1, directory: root, signingIdentity: missing)
                preconditionFailure("Missing key must fail closed")
            } catch IsolatedPlayer.Failure.signingFailed { }
            let preserved = try Data(contentsOf: executable)
            precondition(preserved == after)
            try IsolatedPlayer.run("/usr/bin/codesign", ["--force", "--sign", "-", "--identifier", signed.bundleID, signed.url.path])
            do {
                try IsolatedPlayer.run("/usr/bin/codesign", ["--verify", "-R", requirement, signed.url.path])
                preconditionFailure("Matching the bundle ID alone must not satisfy certificate trust")
            } catch IsolatedPlayer.Failure.command { }
            print("PASS: persistent certificate identity across changed builds, distinct slot trust, missing-key fail-closed, and rejection of identifier-only impersonation")
        }
        print("PASS: identity parsing, PID/log matching, path-based occupancy after updates, running-slot protection, distinct session IDs, signatures, source preservation, cache reuse and update repair")
    }
}
