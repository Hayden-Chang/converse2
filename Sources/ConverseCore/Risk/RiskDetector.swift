import Foundation

extension RiskLevel {
    public var severity: Int {
        switch self {
        case .low: 0
        case .medium: 1
        case .high: 2
        case .critical: 3
        }
    }
}

public struct RiskDetector {

    public init() {}

    public func assess(_ command: String, policy: ConfirmationPolicy = .standard) -> RiskAssessment {
        let parsed = ShellCommandParser.parse(command)
        let segments = parsed.segments
        var perSegment: [[Hit]] = segments.map { Self.segmentHits($0) }

        for i in 0..<segments.count {
            let cur = Self.effectiveCmd(segments[i])
            if (cur == "curl" || cur == "wget"), i + 1 < segments.count {
                let nxt = Self.effectiveCmd(segments[i + 1])
                if let n = nxt, Self.shells.contains(n) {
                    let hit = Hit(.critical, "network_script_exec", "执行网络下载的脚本")
                    perSegment[i].append(hit)
                    perSegment[i + 1].append(hit)
                }
            }
        }

        let allHits = perSegment.flatMap { $0 }
        let level = allHits.map(\.level).max(by: { $0.severity < $1.severity }) ?? .low
        let rules = Self.dedupe(allHits.map(\.rule))
        let scope = allHits
            .filter { $0.level == level }
            .map(\.scope)
            .filter { !$0.isEmpty }
            .joined(separator: "；")

        let confirm: Bool
        switch level {
        case .low: confirm = false
        case .medium: confirm = (policy == .strict)
        case .high, .critical: confirm = true
        }

        return RiskAssessment(
            level: level,
            matchedRules: rules,
            impactScope: scope,
            requiresConfirmation: confirm
        )
    }

    private struct Hit {
        let level: RiskLevel
        let rule: String
        let scope: String
        init(_ level: RiskLevel, _ rule: String, _ scope: String) {
            self.level = level; self.rule = rule; self.scope = scope
        }
    }

    private static let shells: Set<String> = [
        "sh", "bash", "zsh", "fish", "dash", "perl", "python", "python2", "python3", "ruby", "env"
    ]

    private static let systemDirs: [String] = [
        "/etc", "/usr", "/System", "/var", "/bin", "/sbin", "/boot", "/dev", "/lib", "/opt", "/private"
    ]

    private static func dedupe(_ rules: [String]) -> [String] {
        var seen = Set<String>()
        var out = [String]()
        for r in rules where !seen.contains(r) {
            seen.insert(r); out.append(r)
        }
        return out
    }

    private static func effectiveTokens(_ seg: ParsedCommand.Segment) -> [String] {
        seg.hasSudo ? Array(seg.tokens.dropFirst()) : seg.tokens
    }

    private static func effectiveCmd(_ seg: ParsedCommand.Segment) -> String? {
        effectiveTokens(seg).first?.lowercased()
    }

    private static func shortFlags(_ tokens: [String]) -> Set<Character> {
        var flags = Set<Character>()
        for t in tokens {
            if t.hasPrefix("--") { continue }
            if t.hasPrefix("-") { for c in t.dropFirst() { flags.insert(c) } }
        }
        return flags
    }

    private static func targetsSystem(_ args: [String]) -> Bool {
        for a in args {
            if a == "/" || a == "/*" { return true }
            for d in systemDirs where a == d || a.hasPrefix(d + "/") { return true }
        }
        return false
    }

    private static func segmentHits(_ seg: ParsedCommand.Segment) -> [Hit] {
        let tokens = effectiveTokens(seg)
        guard let cmd = tokens.first?.lowercased(), !cmd.isEmpty else { return [] }
        let rest = Array(tokens.dropFirst())
        let flags = shortFlags(rest)
        let args = rest.filter { !$0.hasPrefix("-") }
        let hasRecursive = flags.contains("r") || rest.contains("--recursive")
        let hasForce = flags.contains("f") || rest.contains("--force")
        let hasRF = hasRecursive && hasForce
        let capR = rest.contains { $0.hasPrefix("-R") }
        let systemTarget = targetsSystem(args)
        var hits: [Hit] = []

        if cmd == "dd" {
            hits.append(Hit(.critical, "dd_disk", "底层磁盘读写"))
        }
        if cmd == "mkfs" || cmd.hasPrefix("mkfs.") || cmd == "newfs" || cmd.hasPrefix("newfs") {
            hits.append(Hit(.critical, "format_disk", "格式化磁盘"))
        }

        if cmd == "rm" {
            if systemTarget {
                hits.append(Hit(.critical, "system_destruction", "影响系统目录"))
            } else if hasRF {
                let target = args.isEmpty ? "文件" : args.joined(separator: " ")
                hits.append(Hit(.high, "file_deletion", "递归强制删除 \(target)"))
            } else if args.contains(where: { $0.contains("*") }) {
                hits.append(Hit(.high, "file_deletion", "批量删除 \(args.joined(separator: " "))"))
            } else if hasForce || hasRecursive {
                let target = args.isEmpty ? "文件" : args.joined(separator: " ")
                hits.append(Hit(.high, "file_deletion", "删除 \(target)"))
            }
        }

        if cmd == "git" {
            let sub = args.first?.lowercased() ?? ""
            if sub == "reset" && rest.contains("--hard") {
                hits.append(Hit(.high, "git_destructive", "Git 重置丢弃提交"))
            }
            if sub == "clean" && flags.contains("f") && (flags.contains("d") || flags.contains("x")) {
                hits.append(Hit(.high, "git_destructive", "Git 清理未跟踪文件"))
            }
        }

        if cmd == "chmod" {
            let mode777 = args.contains("777") || args.contains("000") || args.contains("a+rw")
            if systemTarget {
                hits.append(Hit(.critical, "system_destruction", "修改系统目录权限"))
            } else if capR || hasRecursive || mode777 {
                hits.append(Hit(.high, "permission_change", "修改文件权限"))
            }
        }

        if cmd == "chown" {
            if systemTarget {
                hits.append(Hit(.critical, "system_destruction", "修改系统目录属主"))
            } else if capR || hasRecursive {
                hits.append(Hit(.high, "permission_change", "递归修改属主"))
            }
        }

        if cmd == "mv" {
            if systemTarget {
                hits.append(Hit(.critical, "system_destruction", "移动影响系统目录"))
            } else if args.contains(where: { $0.contains("*") }) {
                hits.append(Hit(.high, "file_move", "批量移动覆盖"))
            }
        }

        if cmd == ":" && seg.hasRedirect {
            hits.append(Hit(.high, "file_truncate", "截断覆盖文件"))
        }

        let packageCmds: Set<String> = ["npm", "yarn", "pnpm", "pip", "pip3", "cargo", "brew", "gem", "go", "apt", "apt-get"]
        if packageCmds.contains(cmd) {
            let installSubs: Set<String> = ["install", "add", "i", "get", "upgrade"]
            let sub = args.first?.lowercased() ?? ""
            if installSubs.contains(sub) {
                let pkg = args.dropFirst().joined(separator: " ")
                hits.append(Hit(.medium, "package_install", pkg.isEmpty ? "安装包" : "安装包 \(pkg)"))
            }
        }

        if cmd == "kill" && (rest.contains("-9") || rest.contains("-KILL") || flags.contains("9")) {
            hits.append(Hit(.medium, "process_kill", "强制结束进程"))
        }

        if seg.hasRedirect && hits.isEmpty {
            hits.append(Hit(.medium, "file_overwrite", "覆盖文件"))
        }

        let segLevel = hits.map(\.level).max(by: { $0.severity < $1.severity }) ?? .low
        if seg.hasSudo && segLevel.severity >= RiskLevel.high.severity {
            hits.append(Hit(.critical, "sudo_destructive", "提权执行危险操作"))
        }

        return hits
    }
}
