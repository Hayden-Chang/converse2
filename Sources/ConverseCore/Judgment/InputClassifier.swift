import Foundation

public struct InputClassifier {

    private let pathDirs: [String]

    public init() {
        self.pathDirs = Self.defaultPathDirs()
    }

    public init(pathDirs: [String]) {
        self.pathDirs = pathDirs
    }

    public func classify(_ input: String) -> InputClassification {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .naturalLanguage
        }
        guard let token = Self.firstToken(trimmed) else {
            return .naturalLanguage
        }
        let remainder = Self.remainderAfterFirstToken(trimmed)
        if Self.containsCJK(remainder) {
            return .naturalLanguage
        }
        if Self.builtins.contains(token) {
            return .shellCommand
        }
        if token.hasPrefix("/") {
            return .shellCommand
        }
        if token.contains("/") {
            return .shellCommand
        }
        if Self.isInPath(token, pathDirs: pathDirs) {
            return .shellCommand
        }
        return .naturalLanguage
    }

    public static func isInPath(_ cmd: String) -> Bool {
        isInPath(cmd, pathDirs: defaultPathDirs())
    }

    private static func isInPath(_ cmd: String, pathDirs: [String]) -> Bool {
        guard !cmd.isEmpty else { return false }
        let fm = FileManager.default
        for dir in pathDirs {
            let candidate = (dir as NSString).appendingPathComponent(cmd)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: candidate, isDirectory: &isDir), !isDir.boolValue {
                return true
            }
        }
        return false
    }

    public static func containsCJK(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }

    public static func firstToken(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let first = trimmed.first!
        if first == "\"" || first == "'" {
            let quote = first
            let rest = trimmed.dropFirst()
            if let end = rest.firstIndex(of: quote) {
                return String(rest[rest.startIndex..<end])
            }
            return String(rest)
        }
        if let idx = trimmed.firstIndex(where: { $0 == " " || $0 == "\t" }) {
            return String(trimmed[trimmed.startIndex..<idx])
        }
        return trimmed
    }

    private static func remainderAfterFirstToken(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let first = trimmed.first!
        if first == "\"" || first == "'" {
            let quote = first
            let rest = trimmed.dropFirst()
            if let end = rest.firstIndex(of: quote) {
                let after = rest.index(after: end)
                return String(rest[after...])
            }
            return ""
        }
        if let idx = trimmed.firstIndex(where: { $0 == " " || $0 == "\t" }) {
            return String(trimmed[idx...])
        }
        return ""
    }

    public static let builtins: Set<String> = [
        "cd", "echo", "ls", "pwd", "export", "set", "unset", "alias",
        "source", "exit", "type", "which", "printf", "true", "false",
        "read", "pushd", "popd", "dirs", "history", "bg", "fg", "jobs",
        "kill", "umask", "command", "builtin", "times", "wait", "trap",
        "return", "break", "continue", "eval", "exec", "hash", "let",
        "local", "logout", "mapfile", "readarray", "getopts", "shift",
        "shopt", "suspend", "test", "ulimit", "help", ".", ":"
    ]

    private static func defaultPathDirs() -> [String] {
        guard let path = ProcessInfo.processInfo.environment["PATH"] else { return [] }
        return path.split(separator: ":").map(String.init)
    }
}
