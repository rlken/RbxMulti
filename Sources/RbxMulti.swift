import SwiftUI
import AppKit

let robloxID = "com.roblox.RobloxPlayer"
let schemes = ["roblox-player", "roblox"]

func robloxApps() -> [NSRunningApplication] {
    NSWorkspace.shared.runningApplications.filter {
        !$0.isTerminated && ($0.bundleIdentifier == robloxID
            || $0.bundleIdentifier?.hasPrefix(IsolatedPlayer.bundlePrefix) == true
            || $0.executableURL?.lastPathComponent == "RobloxPlayer")
    }
}

struct Instance: Identifiable {
    let id = UUID()
    var name: String
    var pid: pid_t
    let started: Date
    var userID: Int? = nil
    var username: String? = nil
    var avatarURL: URL? = nil
    var accountCollision = false
    var isolationLost = false
    var running = true
    var stoppedAt: Date? = nil
    var awaitingSince: Date? = nil
}

private struct RobloxThumbnailResponse: Decodable {
    struct Thumbnail: Decodable { let imageUrl: String? }
    let data: [Thumbnail]
}

private struct RobloxUsernameResponse: Decodable {
    struct User: Decodable {
        let id: Int
        let name: String
    }
    let data: [User]
}

private struct RobloxUserProfile: Decodable {
    let name: String
}

final class Model: ObservableObject {
    static let shared = Model()
    @Published var items: [Instance] = []
    @Published var message = ""
    @Published var handlerOK = true
    @Published var log: [String] = []
    private let servicesEnabled: Bool
    @Published var keepMacAwake = true {
        didSet {
            guard servicesEnabled else { return }
            UserDefaults.standard.set(keepMacAwake, forKey: "keepMacAwake")
            updateWakeLock()
        }
    }
    private var counter = 0
    private var retired = Set<pid_t>()
    private var caffeinate: Process?
    private var lastIdentityScan: Date = .distantPast
    private var identityScanInProgress = false
    private var preparingSlots = Set<String>()
    private let preparationQueue = DispatchQueue(label: "com.rbxmulti.prepare", qos: .userInitiated)
    // Roblox may take a little while to close the old player and start the
    // replacement player during an in-game reconnect. Keep the account slot
    // available long enough to attach that replacement instead of showing it
    // as a new, unrelated account.
    private let reconnectWindow: TimeInterval = 90

    init(startServices: Bool = true) {
        servicesEnabled = startServices
        guard startServices else { return }
        keepMacAwake = UserDefaults.standard.object(forKey: "keepMacAwake") as? Bool ?? true
        // Background Roblox windows can be put into App Nap by macOS. That
        // prevents their game code from reliably running timers (including a
        // game's own, legitimate reconnect/teleport logic). This preference
        // takes effect for players launched after it is set.
        UserDefaults(suiteName: robloxID)?.set(true, forKey: "NSAppSleepDisabled")
        updateWakeLock()
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func updateWakeLock() {
        if keepMacAwake {
            guard caffeinate?.isRunning != true else { return }
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
            // Tie the power assertion to RbxMulti itself. It prevents idle
            // display/system sleep only while the launcher is open; it does
            // not send input to Roblox or interact with the game windows.
            p.arguments = ["-d", "-i", "-s", "-w", "\(getpid())"]
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
            do {
                try p.run()
                caffeinate = p
                note("Keeping Mac awake while RbxMulti is open")
            } catch {
                note("Could not keep Mac awake")
            }
        } else {
            caffeinate?.terminate()
            caffeinate = nil
            note("Mac sleep protection turned off")
        }
    }

    func stopWakeLock() {
        caffeinate?.terminate()
        caffeinate = nil
    }


    var runningCount: Int { items.filter { $0.running }.count }

    func note(_ s: String) {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        log.append("\(f.string(from: Date()))  \(s)")
        if log.count > 30 { log.removeFirst(log.count - 30) }
    }

    func robloxURL() -> URL? {
        let installed = URL(fileURLWithPath: "/Applications/Roblox.app")
        if FileManager.default.fileExists(atPath: installed.path) { return installed }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: robloxID)
    }

    // Legacy force-close helper. Not called by the current startup lifecycle.
    func closeRoblox() {
        let had = !robloxApps().isEmpty
        robloxApps().forEach { $0.forceTerminate() }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        p.arguments = ["-9", "-x", "RobloxPlayer"]
        try? p.run()
        p.waitUntilExit()
        for _ in 0..<30 {
            if robloxApps().isEmpty { break }
            usleep(100_000)
        }
        items.removeAll()
        retired.removeAll()
        if !robloxApps().isEmpty {
            message = "Could not close Roblox. Quit it manually."
            note("Startup: could not close Roblox")
        } else if had {
            message = "Roblox was closed before starting."
            note("Startup: closed running Roblox")
        }
    }

    func track(pid: pid_t, started: Date, awaiting: Bool = false) {
        guard !items.contains(where: { $0.pid == pid }) else { return }
        counter += 1
        items.append(Instance(name: "Account \(counter)", pid: pid, started: started,
                              awaitingSince: awaiting ? Date() : nil))
    }

    func add(_ app: NSRunningApplication) {
        track(pid: app.processIdentifier, started: app.launchDate ?? Date())
    }

    func launch(_ url: URL) {
        note("Link received (\(url.scheme ?? "?"))")
        guard schemes.contains(url.scheme?.lowercased() ?? "") else { return }
        guard let appURL = robloxURL() else {
            message = "Roblox is not installed in /Applications."
            note("Roblox.app not found")
            return
        }
        let currentPlayers = robloxApps()
        let runningURLs = currentPlayers.compactMap { $0.bundleURL }
        let occupied = IsolatedPlayer.occupiedIDs(bundleIDs: currentPlayers.compactMap { $0.bundleIdentifier },
                                                 appURLs: runningURLs).union(preparingSlots)
        let slot = IsolatedPlayer.availableSlot(occupied: occupied)
        let bundleID = IsolatedPlayer.bundleID(slot: slot)
        preparingSlots.insert(bundleID)
        message = "Preparing separate session \(slot)…"
        preparationQueue.async {
            do {
                let signingIdentity = try IsolatedPlayer.SigningIdentity.configured()
                let source = IsolatedPlayer.latestSource(installed: appURL, signingIdentity: signingIdentity)
                let player = try IsolatedPlayer.prepare(source: source, slot: slot, runningAppURLs: runningURLs,
                                                        signingIdentity: signingIdentity)
                DispatchQueue.main.async {
                    let livePlayers = robloxApps()
                    let liveIDs = IsolatedPlayer.occupiedIDs(bundleIDs: livePlayers.compactMap { $0.bundleIdentifier },
                                                           appURLs: livePlayers.compactMap { $0.bundleURL })
                    guard !liveIDs.contains(bundleID) else {
                        self.preparingSlots.remove(bundleID)
                        self.message = "Session \(slot) is already running. Click Play again for a free session."
                        self.note("Launch cancelled: session \(slot) became occupied")
                        return
                    }
                    let existingPIDs = Set(livePlayers.map { $0.processIdentifier })
                    let configuration = NSWorkspace.OpenConfiguration()
                    configuration.createsNewApplicationInstance = true
                    configuration.allowsRunningApplicationSubstitution = false
                    configuration.arguments = ["-protocolString", url.absoluteString]
                    NSWorkspace.shared.openApplication(at: player.url, configuration: configuration) { app, error in
                        DispatchQueue.main.async {
                            self.preparingSlots.remove(bundleID)
                            if let app {
                                guard !existingPIDs.contains(app.processIdentifier),
                                      app.bundleIdentifier == bundleID,
                                      app.bundleURL?.standardizedFileURL == player.url.standardizedFileURL else {
                                    self.message = "Roblox did not open a new isolated session. Existing games were left running; try Play again."
                                    self.note("Launch returned an unexpected player; not counted as a new session")
                                    return
                                }
                                self.add(app)
                                self.note("Started isolated session \(slot) (process \(app.processIdentifier))")
                                self.message = "Session \(slot) has its own login storage."
                            } else {
                                self.message = "Could not start session \(slot): \(error?.localizedDescription ?? "unknown error")"
                                self.note("Could not start isolated session \(slot)")
                            }
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.preparingSlots.remove(bundleID)
                    self.message = error.localizedDescription
                    self.note("Session preparation failed; no shared-storage player was launched")
                }
            }
        }
    }

    // Sends the roblox-player link to ONE specific process (an Apple 'open URL' event)
    static func sendURL(_ url: URL, to pid: pid_t) -> Bool {
        let target = NSAppleEventDescriptor(processIdentifier: pid)
        let event = NSAppleEventDescriptor(eventClass: 0x4755524C, eventID: 0x4755524C,
                                           targetDescriptor: target,
                                           returnID: -1, transactionID: 0)
        event.setParam(NSAppleEventDescriptor(string: url.absoluteString), forKeyword: 0x2D2D2D2D)
        do {
            _ = try event.sendEvent(options: [.noReply], timeout: 10)
            return true
        } catch {
            return false
        }
    }

    func claimLinks() {
        for s in schemes {
            NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL,
                                                     toOpenURLsWithScheme: s) { _ in }
        }
    }

    func restoreLinks() {
        guard let r = robloxURL() else { return }
        for s in schemes {
            NSWorkspace.shared.setDefaultApplication(at: r, toOpenURLsWithScheme: s) { _ in }
        }
        note("Roblox links given back to Roblox")
    }

    func close(_ i: Instance) {
        guard i.running else { return }
        NSRunningApplication(processIdentifier: i.pid)?.forceTerminate()
        kill(i.pid, SIGKILL)
        message = "Closed \(i.name)."
        note("Closed \(i.name) (process \(i.pid))")
    }

    func closeAll() {
        let live = items.filter { $0.running }
        if live.isEmpty { message = "Nothing to close."; return }
        live.forEach { close($0) }
    }

    private func scanAccountIdentities() {
        guard !identityScanInProgress,
              Date().timeIntervalSince(lastIdentityScan) > 5 else { return }
        identityScanInProgress = true
        lastIdentityScan = Date()
        let pids = items.filter { $0.running }.map { $0.pid }
        DispatchQueue.global(qos: .utility).async {
            let found = PlayerSessionLog.inspect(pids: pids)
            DispatchQueue.main.async {
                self.identityScanInProgress = false
                for index in self.items.indices {
                    guard let identity = found[self.items[index].pid] else { continue }
                    if identity.changedAccount && !self.items[index].accountCollision {
                        self.note("Account collision: process \(self.items[index].pid) changed from \(identity.initialUserID) to \(identity.latestUserID)")
                    }
                    self.items[index].accountCollision = identity.changedAccount
                    if self.items[index].userID != identity.initialUserID {
                        self.items[index].userID = identity.initialUserID
                        self.items[index].avatarURL = nil
                        self.fetchProfile(for: self.items[index].id, userID: identity.initialUserID)
                        self.fetchAvatar(for: self.items[index].id, userID: identity.initialUserID)
                    }
                }
            }
        }
    }

    private func fetchProfile(for instanceID: UUID, userID: Int) {
        guard let url = URL(string: "https://users.roblox.com/v1/users/\(userID)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let profile = try? JSONDecoder().decode(RobloxUserProfile.self, from: data) else { return }
            DispatchQueue.main.async {
                guard let index = self.items.firstIndex(where: { $0.id == instanceID }) else { return }
                self.items[index].username = profile.name
                self.items[index].name = profile.name
            }
        }.resume()
    }

    private func fetchAvatar(for instanceID: UUID, userID: Int) {
        guard let url = URL(string: "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=\(userID)&size=150x150&format=Png&isCircular=false") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let response = try? JSONDecoder().decode(RobloxThumbnailResponse.self, from: data),
                  let imageURL = response.data.first?.imageUrl,
                  let avatarURL = URL(string: imageURL) else { return }
            DispatchQueue.main.async {
                guard let index = self.items.firstIndex(where: { $0.id == instanceID }) else { return }
                self.items[index].avatarURL = avatarURL
            }
        }.resume()
    }

    // Some Roblox launches do not write an identity to the local log until a
    // later teleport. The editable account name doubles as a privacy-safe
    // fallback: entering a public username lets us resolve only that public
    // profile ID and its public headshot—never a browser cookie or token.
    func resolveUsername(for instanceID: UUID, username: String) {
        let cleaned = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !cleaned.hasPrefix("Account "),
              let url = URL(string: "https://users.roblox.com/v1/usernames/users") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["usernames": [cleaned]])
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data,
                  let response = try? JSONDecoder().decode(RobloxUsernameResponse.self, from: data),
                  let user = response.data.first else { return }
            DispatchQueue.main.async {
                guard let index = self.items.firstIndex(where: { $0.id == instanceID }) else { return }
                self.items[index].userID = user.id
                self.items[index].username = user.name
                self.items[index].name = user.name
                self.fetchAvatar(for: instanceID, userID: user.id)
            }
        }.resume()
    }

    func refresh() {
        let apps = robloxApps()
        let live = Set(apps.map { $0.processIdentifier })
        retired.formIntersection(live)
        for i in items.indices {
            // This PID is the player we launched, so it is no longer waiting
            // for its startup/restart process. Leaving this set made a later
            // AFK reconnect get attached to an arbitrary older account.
            if live.contains(items[i].pid) {
                items[i].awaitingSince = nil
                if let app = apps.first(where: { $0.processIdentifier == items[i].pid }),
                   let url = app.bundleURL, let expectedID = IsolatedPlayer.slotID(at: url) {
                    let lost = app.bundleIdentifier != expectedID
                        || IsolatedPlayer.metadata(at: url)?["CFBundleIdentifier"] as? String != expectedID
                    if lost && !items[i].isolationLost {
                        note("Roblox updated \(items[i].name); relaunch that account when ready to restore separate login storage")
                    }
                    items[i].isolationLost = lost
                }
            } else if let t = items[i].awaitingSince, Date().timeIntervalSince(t) > reconnectWindow {
                items[i].awaitingSince = nil
            }
            // An account waiting for its restart still counts as running.
            let now = live.contains(items[i].pid) || items[i].awaitingSince != nil
            if items[i].running && !now {
                items[i].stoppedAt = Date()
                note("\(items[i].name) (process \(items[i].pid)) stopped")
            }
            items[i].running = now
        }
        // Discover processes independently; nearby startup times do not prove
        // that a new process belongs to an older account.
        for app in apps {
            let pid = app.processIdentifier
            if retired.contains(pid) || items.contains(where: { $0.pid == pid }) { continue }
            add(app)
            note("Found Roblox process \(pid)")
        }
        scanAccountIdentities()
        // Keep a stopped row just long enough to attach a legitimate Roblox
        // reconnect. After that it is no longer useful in the status list.
        items.removeAll {
            guard !$0.running, let stoppedAt = $0.stoppedAt else { return false }
            return Date().timeIntervalSince(stoppedAt) > reconnectWindow
        }
        let h = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "roblox-player://x")!)
        handlerOK = h?.standardizedFileURL == Bundle.main.bundleURL.standardizedFileURL
    }
}
