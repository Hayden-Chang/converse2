import Foundation

public struct OutputSummarizer {
    public static let maxLines = 200
    public static let maxBytes = 8192

    public enum DisplayLine {
        case line(String)
        case omitted(Int)
    }

    public static func summarize(_ output: String) -> (excerpt: String, truncated: Bool) {
        var truncated = false
        var working = output

        if working.utf8.count > maxBytes {
            truncated = true
            var bytes = 0
            var idx = working.startIndex
            while idx < working.endIndex {
                let len = String(working[idx]).utf8.count
                if bytes + len > maxBytes { break }
                bytes += len
                idx = working.index(after: idx)
            }
            working = String(working[working.startIndex..<idx])
        }

        let allLines = working.components(separatedBy: "\n")
        if allLines.count > maxLines {
            truncated = true
            working = allLines.suffix(maxLines).joined(separator: "\n")
        }

        return (working, truncated)
    }

    public static func displaySplit(_ lines: [String], threshold: Int = 400, head: Int = 200, tail: Int = 200) -> [DisplayLine] {
        if lines.count > threshold {
            let headPart = lines.prefix(head).map { DisplayLine.line($0) }
            let tailPart = lines.suffix(tail).map { DisplayLine.line($0) }
            let omittedCount = lines.count - head - tail
            return headPart + [.omitted(omittedCount)] + tailPart
        }
        return lines.map { DisplayLine.line($0) }
    }
}
