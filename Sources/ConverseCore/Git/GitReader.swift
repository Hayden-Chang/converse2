import Foundation

public struct GitFileChange: Identifiable, Equatable {
    public let path: String
    public let stagedStatus: Character
    public let worktreeStatus: Character

    public var id: String { path }

    public var isUntracked: Bool { stagedStatus == "?" && worktreeStatus == "?" }

    public var label: String {
        if isUntracked { return "未跟踪" }
        switch (stagedStatus, worktreeStatus) {
        case ("M", _), (_, "M"): return "修改"
        case ("A", _): return "新增"
        case ("D", _), (_, "D"): return "删除"
        case ("R", _): return "重命名"
        case ("C", _): return "复制"
        default: return "改动"
        }
    }
}

public struct GitStatus: Equatable {
    public let branch: String?
    public let changes: [GitFileChange]
}

public struct GitReader {
    public let repoPath: String

    public init(repoPath: String) {
        self.repoPath = repoPath
    }

    public func isRepo() -> Bool {
        let gitPath = (repoPath as NSString).appendingPathComponent(".git")
        return FileManager.default.fileExists(atPath: gitPath)
    }

    public func currentBranch() throws -> String? {
        let out = try run(["rev-parse", "--abbrev-ref", "HEAD"])
        let trimmed = out.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public func status() throws -> GitStatus {
        let out = try run(["status", "--porcelain=v1"])
        let branch = try currentBranch()
        return GitStatus(branch: branch, changes: GitReader.parsePorcelain(out))
    }

    public func diff(forFile path: String) throws -> String {
        return try run(["diff", "--", path])
    }

    private func run(_ args: [String]) throws -> String {
        let process = Process()
        process.launchPath = "/usr/bin/git"
        process.arguments = ["-C", repoPath] + args
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let errText = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw NSError(domain: "GitReader", code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: errText])
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    public static func parsePorcelain(_ output: String) -> [GitFileChange] {
        var result: [GitFileChange] = []
        for raw in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty, line.count >= 3 else { continue }
            let chars = Array(line)
            let x = chars[0]
            let y = chars[1]
            var path = String(chars.dropFirst(3))
            if let range = path.range(of: " -> ") {
                path = String(path[range.upperBound...])
            }
            path = path.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !path.isEmpty else { continue }
            result.append(GitFileChange(path: path, stagedStatus: x, worktreeStatus: y))
        }
        return result
    }
}
