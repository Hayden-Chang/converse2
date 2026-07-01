import Foundation

public struct FewShotExample: Equatable, Sendable {
    public let input: String
    public let command: String
    public let cwd: String?
    public let risk: RiskLevel
    public init(input: String, command: String, cwd: String? = nil, risk: RiskLevel = .low) {
        self.input = input; self.command = command; self.cwd = cwd; self.risk = risk
    }
}

public struct FewShotStore: Equatable {
    public let examples: [FewShotExample]
    public init(examples: [FewShotExample]) { self.examples = examples }

    public static let bundled: FewShotStore = FewShotStore(examples: [
        .init(input: "列出当前目录下最大的文件", command: "du -sh * | sort -rh | head", risk: .low),
        .init(input: "重装依赖", command: "rm -rf node_modules && npm install", risk: .high),
        .init(input: "看看 git 状态", command: "git status", risk: .low),
        .init(input: "查看当前改动", command: "git diff", risk: .low),
        .init(input: "提交所有改动", command: "git add . && git commit -m \"message\"", risk: .low),
        .init(input: "找出所有 swift 文件", command: "find . -name \"*.swift\"", risk: .low),
        .init(input: "谁占了 8080 端口", command: "lsof -i :8080", risk: .low),
        .init(input: "解压 tar.gz", command: "tar -xzf file.tar.gz", risk: .low),
        .init(input: "强制结束进程", command: "kill -9 <pid>", risk: .medium),
        .init(input: "安装 ripgrep", command: "brew install ripgrep", risk: .medium),
        .init(input: "切换到新分支", command: "git checkout -b <branch>", risk: .low),
        .init(input: "查看磁盘占用", command: "df -h", risk: .low)
    ])

    public func retrieve(for input: String, limit: Int) -> [FewShotExample] {
        guard limit > 0, !examples.isEmpty else { return [] }
        let inputTokens = Self.normalize(input)
        guard !inputTokens.isEmpty else { return [] }
        let scored = examples.map { ex -> (FewShotExample, Int) in
            let exTokens = Self.normalize(ex.input + " " + ex.command)
            let overlap = inputTokens.filter { exTokens.contains($0) }.count
            return (ex, overlap)
        }
        return scored
            .filter { $0.1 > 0 }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.input.count > rhs.0.input.count
            }
            .prefix(limit)
            .map { $0.0 }
    }

    public static func normalize(_ input: String) -> Set<String> {
        let lowered = input.lowercased()
        let stopwords: Set<String> = [
            "的", "了", "把", "给", "在", "和", "是", "我", "你", "他", "这", "那", "一",
            "the", "a", "an", "to", "of", "and", "for", "in", "on", "please", "me", "i", "want", "need"
        ]
        var tokens = Set<String>()
        func addLatin(_ word: String) {
            let t = word.trimmingCharacters(in: .whitespaces)
            guard t.count >= 2, !stopwords.contains(t) else { return }
            tokens.insert(t)
        }
        func addCjk(_ ch: Character) {
            let s = String(ch)
            guard !stopwords.contains(s) else { return }
            tokens.insert(s)
        }
        var latin = ""
        for ch in lowered {
            if ch.isASCII && (ch.isLetter || ch.isNumber) {
                latin.append(ch)
            } else {
                if !latin.isEmpty { addLatin(latin); latin = "" }
                if ch.isLetter || ch.isNumber { addCjk(ch) }
            }
        }
        if !latin.isEmpty { addLatin(latin) }
        return tokens
    }
}
