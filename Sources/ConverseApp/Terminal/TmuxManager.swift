import Foundation

final class TmuxManager {
    static let prefix = "converse_"

    static func sessionName(for id: String) -> String {
        prefix + id
    }

    static func parseConverseSessionIDs(lines: [String]) -> [String] {
        var ids: [String] = []
        for line in lines {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let name = String(line[..<colon])
            guard name.hasPrefix(prefix) else { continue }
            ids.append(String(name.dropFirst(prefix.count)))
        }
        return ids
    }

    static func parseConverseSessionIDs(rawLsOutput: String) -> [String] {
        parseConverseSessionIDs(
            lines: rawLsOutput
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
        )
    }

    static func resolvedBinPath() -> String? {
        if let env = ProcessInfo.processInfo.environment["CONVERSE_TMUX_BIN"],
           FileManager.default.isExecutableFile(atPath: env) {
            return env
        }
        for c in ["/usr/local/bin/tmux", "/opt/homebrew/bin/tmux", "/usr/bin/tmux"]
            where FileManager.default.isExecutableFile(atPath: c) {
            return c
        }
        return runWhich("tmux")
    }

    private static func runWhich(_ cmd: String) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        p.arguments = [cmd]
        let pipe = Pipe()
        p.standardOutput = pipe
        do { try p.run() } catch { return nil }
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let s = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (s?.isEmpty == false) ? s : nil
    }

    private let binPath: String

    init(binPath: String? = TmuxManager.resolvedBinPath()) {
        self.binPath = binPath ?? "/usr/local/bin/tmux"
    }

    func hasSession(id: String) -> Bool {
        runTmux(["has-session", "-t", Self.sessionName(for: id)]).status == 0
    }

    func ensureSession(id: String, cwd: String, shell: String?) throws {
        guard !hasSession(id: id) else { return }
        let sh = shell ?? ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let args = ["new-session", "-d", "-s", Self.sessionName(for: id),
                    "-c", cwd, "-x", "200", "-y", "50", sh]
        let r = runTmux(args)
        guard r.status == 0 else {
            throw NSError(domain: "TmuxManager", code: Int(r.status),
                          userInfo: [NSLocalizedDescriptionKey: r.stderr])
        }
    }

    func killSession(id: String) {
        _ = runTmux(["kill-session", "-t", Self.sessionName(for: id)])
    }

    func listConverseSessions() -> [String] {
        let r = runTmux(["ls"])
        guard r.status == 0 else { return [] }
        return Self.parseConverseSessionIDs(rawLsOutput: r.stdout)
    }

    func attachArgs(for id: String) -> (executable: String, args: [String]) {
        (binPath, ["attach", "-t", Self.sessionName(for: id)])
    }

    func orphanedConverseSessions(recordedIDs: [String]) -> [String] {
        let live = Set(listConverseSessions())
        let recorded = Set(recordedIDs)
        return Array(live.subtracting(recorded)).sorted()
    }

    @discardableResult
    private func runTmux(_ args: [String]) -> (status: Int32, stdout: String, stderr: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: binPath)
        p.arguments = args
        let out = Pipe(); let err = Pipe()
        p.standardOutput = out; p.standardError = err
        do { try p.run() } catch {
            return (-1, "", error.localizedDescription)
        }
        p.waitUntilExit()
        let s = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let e = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (p.terminationStatus, s, e)
    }
}
