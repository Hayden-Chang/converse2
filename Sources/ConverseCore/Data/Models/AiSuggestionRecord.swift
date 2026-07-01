import Foundation
import GRDB

public struct AiSuggestionRecord: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "ai_suggestions"
    public var id: Int64?
    public var sessionId: Int64
    public var commandRunId: Int64?
    public var provider: String
    public var model: String
    public var promptVersion: String
    public var naturalLanguageInput: String
    public var generatedCommand: String
    public var explanation: String?
    public var riskLevel: String
    public var status: String
    public var createdAt: Date
    enum CodingKeys: String, CodingKey {
        case id, provider, model, explanation, status
        case sessionId = "session_id", commandRunId = "command_run_id", promptVersion = "prompt_version"
        case naturalLanguageInput = "natural_language_input", generatedCommand = "generated_command"
        case riskLevel = "risk_level", createdAt = "created_at"
    }
    public init(id: Int64? = nil, sessionId: Int64, commandRunId: Int64? = nil,
                provider: String, model: String, promptVersion: String,
                naturalLanguageInput: String, generatedCommand: String,
                explanation: String? = nil, riskLevel: RiskLevel = .low,
                status: AiSuggestionStatus = .proposed, createdAt: Date = Date()) {
        self.id = id; self.sessionId = sessionId; self.commandRunId = commandRunId
        self.provider = provider; self.model = model; self.promptVersion = promptVersion
        self.naturalLanguageInput = naturalLanguageInput; self.generatedCommand = generatedCommand
        self.explanation = explanation; self.riskLevel = riskLevel.rawValue
        self.status = status.rawValue; self.createdAt = createdAt
    }
    public mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}
