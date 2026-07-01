import Foundation

public struct ParsedCommand: Equatable {
    public struct Segment: Equatable {
        public let tokens: [String]
        public let hasSudo: Bool
        public let hasRedirect: Bool
    }
    public let raw: String
    public let segments: [Segment]
}

public enum ShellCommandParser {

    public static func parse(_ raw: String) -> ParsedCommand {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let chunks = splitOperators(trimmed).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let segments = chunks.map { buildSegment($0) }
        return ParsedCommand(raw: raw, segments: segments)
    }

    private static func splitOperators(_ s: String) -> [String] {
        var segments: [String] = []
        var current = ""
        var quote: Character? = nil
        let chars = Array(s)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if let q = quote {
                current.append(c)
                if c == q { quote = nil }
                i += 1
                continue
            }
            if c == "\"" || c == "'" {
                quote = c
                current.append(c)
                i += 1
                continue
            }
            if c == "&" && i + 1 < chars.count && chars[i + 1] == "&" {
                segments.append(current); current = ""
                i += 2; continue
            }
            if c == "|" && i + 1 < chars.count && chars[i + 1] == "|" {
                segments.append(current); current = ""
                i += 2; continue
            }
            if c == "|" || c == ";" {
                segments.append(current); current = ""
                i += 1; continue
            }
            current.append(c)
            i += 1
        }
        segments.append(current)
        return segments
    }

    private static func buildSegment(_ raw: String) -> ParsedCommand.Segment {
        let tokens = tokenize(raw.trimmingCharacters(in: .whitespaces))
        let hasSudo = tokens.first == "sudo"
        let hasRedirect = tokens.contains { $0.hasPrefix(">") || $0.hasPrefix("<") }
        return ParsedCommand.Segment(tokens: tokens, hasSudo: hasSudo, hasRedirect: hasRedirect)
    }

    private static func tokenize(_ s: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var quote: Character? = nil
        for c in s {
            if let q = quote {
                current.append(c)
                if c == q { quote = nil }
                continue
            }
            if c == "\"" || c == "'" {
                quote = c
                current.append(c)
                continue
            }
            if c.isWhitespace {
                if !current.isEmpty { tokens.append(current); current = "" }
                continue
            }
            current.append(c)
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}
