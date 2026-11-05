import Foundation

enum PlayerVersionCheck {
    enum Failure: LocalizedError {
        case unavailable, invalidChannel, updateRequired
        var errorDescription: String? {
            switch self {
            case .unavailable: return "Could not check Roblox's current version. Check your connection and try Play again."
            case .invalidChannel: return "The Roblox launch link has an unsupported update channel. Open a fresh Play link from the Roblox website."
            case .updateRequired: return "Roblox needs an update before a separate session can open. Update the official Roblox app, close its home window, then click Play in your browser again."
            }
        }
    }

    static func channel(for link: URL) throws -> String {
        let fields = link.absoluteString.components(separatedBy: "+").filter { $0.hasPrefix("channel:") }
        guard fields.count <= 1 else { throw Failure.invalidChannel }
        let channel = fields.first.map { String($0.dropFirst("channel:".count)) } ?? ""
        guard channel.count <= 64,
              channel.isEmpty || channel.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil else {
            throw Failure.invalidChannel
        }
        return channel.isEmpty ? "LIVE" : channel
    }

    static func version(from data: Data) throws -> String {
        struct Response: Decodable { let version: String }
        guard let response = try? JSONDecoder().decode(Response.self, from: data),
              response.version.range(of: "^[0-9]+(?:\\.[0-9]+){1,4}$", options: .regularExpression) != nil else {
            throw Failure.unavailable
        }
        return response.version
    }

    // Worker-queue only. Ephemeral session: no Roblox login cookies or tickets
    // are included in this public version request.
    static func validate(source: URL, link: URL) throws {
        let required = try requiredVersion(for: link)
        guard IsolatedPlayer.metadata(at: source)?["CFBundleShortVersionString"] as? String == required else {
            throw Failure.updateRequired
        }
    }

    static func requiredVersion(for link: URL) throws -> String {
        let channel = try channel(for: link)
        let endpoint = URL(string: "https://clientsettingscdn.roblox.com/v2/client-version/MacPlayer/channel/\(channel)")!
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 12
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let result = ResponseBox()
        let task = session.dataTask(with: endpoint) { data, response, error in
            result.lock.lock()
            if error == nil, (response as? HTTPURLResponse)?.statusCode == 200 { result.data = data }
            result.lock.unlock()
            result.ready.signal()
        }
        task.resume()
        guard result.ready.wait(timeout: .now() + 13) == .success else { throw Failure.unavailable }
        result.lock.lock()
        let data = result.data
        result.lock.unlock()
        guard let data else { throw Failure.unavailable }
        return try version(from: data)
    }

    private final class ResponseBox: @unchecked Sendable {
        let lock = NSLock()
        let ready = DispatchSemaphore(value: 0)
        var data: Data?
    }
}
