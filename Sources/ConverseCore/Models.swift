import Foundation

/// 风险等级（见设计文档 3.10）
public enum RiskLevel: String, Sendable, Codable {
    case low
    case medium
    case high
    case critical

    public var label: String {
        switch self {
        case .low: "低"
        case .medium: "中"
        case .high: "高"
        case .critical: "极高"
        }
    }
}

/// 确认策略（见 8.4）：standard 中风险仅提示；strict 中风险也需确认
public enum ConfirmationPolicy: String, Sendable, Codable {
    case standard
    case strict
}

/// AI 功能模式（见 3.2）
public enum AiMode: String, Sendable, Codable, CaseIterable {
    case off
    case suggest
    case errorAssist

    public var label: String {
        switch self {
        case .off: "关闭 AI"
        case .suggest: "AI 建议"
        case .errorAssist: "报错辅助"
        }
    }
}

/// 命令来源（见 5.4 CommandRun.source）
public enum CommandSource: String, Sendable, Codable {
    case userDirect = "user_direct"
    case aiSuggested = "ai_suggested"
    case aiEdited = "ai_edited"
    case retry
}

/// 会话状态（见 8.5：精简为 running | missing）
public enum SessionStatus: String, Sendable, Codable {
    case running
    case missing

    public var label: String {
        switch self {
        case .running: "运行"
        case .missing: "丢失"
        }
    }
}

/// AI 建议状态（见 5.4 AiSuggestion.status）
public enum AiSuggestionStatus: String, Sendable, Codable {
    case proposed
    case accepted
    case edited
    case rejected
    case failed
}

/// 输入判定结果（见 3.3.2）
public enum InputClassification: Sendable {
    case shellCommand        // 明确命令，直接执行
    case naturalLanguage     // 非命令，走 AI
    case notCommandNoAi      // 非命令且 AI 关闭
}
