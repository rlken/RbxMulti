import Foundation

struct PlayerSessionIdentity {
    let initialUserID: Int
    let latestUserID: Int
    var changedAccount: Bool { initialUserID != latestUserID }
}

enum PlayerSessionLog {
    /// Only the numeric identity in the client's own join telemetry is read.
    /// No game scripts, URL tickets, cookie values, or other players' IDs.
    static func identity(in text: String) -> PlayerSessionIdentity? {
        let pattern = #"(?m)^.*\[FLog::GameJoinLoadTime\] Report game_join_loadtime:[^\r\n]*\buserid:([0-9]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let ids = matches.compactMap { match -> Int? in
            guard let range = Range(match.range(at: 1), in: text), let value = Int(text[range]), value > 0 else { return nil }
            return value
        }
        guard let first = ids.first, let last = ids.last else { return nil }
        return PlayerSessionIdentity(initialUserID: first, latestUserID: last)
    }

    static func logPaths(from output: String) -> [Int32: URL] {
        var pid: Int32?
        var paths: [Int32: URL] = [:]
        for line in output.split(separator: "\n") {
            if line.first == "p" { pid = Int32(line.dropFirst()) }
            if line.first == "n", let pid {
                let path = String(line.dropFirst())
                let url = URL(fileURLWithPath: path)
                let filename = url.lastPathComponent
                if filename.contains("_Player_"), filename.hasSuffix("_last.log"),
                   !filename.contains("CrashHandler") { paths[pid] = url }
            }
        }
        return paths
    }

    /// Match open log descriptors to PIDs, never guess by nearby timestamps.
    static func inspect(pids: [Int32]) -> [Int32: PlayerSessionIdentity] {
        guard !pids.isEmpty else { return [:] }
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-n", "-P", "-a", "-p", pids.map(String.init).joined(separator: ","), "-Fpn"]
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do { try task.run() } catch { return [:] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        let paths = logPaths(from: String(decoding: data, as: UTF8.self))
        var identities: [Int32: PlayerSessionIdentity] = [:]
        for (pid, path) in paths {
            guard let text = try? String(contentsOf: path, encoding: .utf8) else { continue }
            identities[pid] = identity(in: text)
        }
        return identities
    }
}
