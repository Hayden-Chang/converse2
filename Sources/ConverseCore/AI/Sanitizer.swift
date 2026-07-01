import Foundation

public struct Sanitizer {
    public static let placeholder = "[REDACTED]"

    public static func sanitize(_ text: String) -> String {
        var out = text
        out = apply(out, pattern: #"-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----"#, template: placeholder)
        out = apply(out, pattern: #"sk-[A-Za-z0-9]{20,}"#, template: placeholder)
        out = apply(out, pattern: #"Bearer\s+[A-Za-z0-9_\-\.\"]{16,}"#, template: "Bearer \(placeholder)")
        out = apply(out, pattern: #"\b[A-Za-z0-9_\-]{40,}\b"#, template: placeholder)
        out = apply(out, pattern: #"(?im)^(password|passwd|secret|token|api_key|apikey|access_key|private_key)\s*=\s*\S+"#, template: "$1=\(placeholder)")
        out = apply(out, pattern: #"(?im)^Password:\s*\S+"#, template: "Password: \(placeholder)")
        return out
    }

    public static func sanitizeContext(
        cwd: String,
        sessionName: String,
        recentCommands: [String],
        recentOutput: String?
    ) -> String {
        var s = "cwd: \(cwd)\nsession: \(sessionName)\n"
        if !recentCommands.isEmpty {
            s += "recent:\n" + recentCommands.map { "  \($0)" }.joined(separator: "\n") + "\n"
        }
        if let o = recentOutput, !o.isEmpty { s += "output:\n\(o)\n" }
        return sanitize(s)
    }

    private static func apply(_ input: String, pattern: String, template: String) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return input }
        let range = NSRange(input.startIndex..., in: input)
        return re.stringByReplacingMatches(in: input, range: range, withTemplate: template)
    }
}
