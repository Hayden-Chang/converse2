import Foundation

public struct PromptBuilder {
    public static let version = "v1"

    public static func buildSystemPrompt(cwd: String, sessionName: String, fewShot: [FewShotExample]) -> String {
        var s = "你是 Converse 终端的命令翻译助手。用户用自然语言描述意图，你输出可在 macOS zsh 执行的命令。\n"
        s += "规则：\n"
        s += "- 默认只输出命令本身，不要 markdown 代码块。\n"
        s += "- 命令必须是 macOS zsh 可直接执行的。\n"
        s += "- 涉及删除/覆盖/权限/网络脚本/系统目录的命令，在命令行后另起一行用 [risk: high|critical] 标注。\n"
        s += "- 不要生成需要 sudo 隐藏密码输入的命令。\n"
        s += "- 若用户意图不明确，输出最贴近的单一命令，不要反问。\n\n"
        if !cwd.isEmpty { s += "上下文（已脱敏）：\n\(cwd)\n\n" }
        if !sessionName.isEmpty { s += "会话：\(sessionName)\n\n" }
        if !fewShot.isEmpty {
            s += "示例：\n"
            for ex in fewShot {
                s += "- \"\(ex.input)\" → \(ex.command)\n"
            }
        }
        return s
    }

    public static func buildUserMessage(_ naturalLanguage: String) -> String {
        return Sanitizer.sanitize(naturalLanguage)
    }
}
