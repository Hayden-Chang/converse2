import Foundation
import GRDB

public struct CommandRun: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "command_runs"
    public var id: Int64?
    public var sessionId: Int64
    public var source: String
    public var userInput: String?
    public var commandText: String
    public var cwdBefore: String?
    public var cwdAfter: String?
    public var riskLevel: String
    public var confirmationStatus: String
    public var startedAt: Date
    public var endedAt: Date?
    public var exitCode: Int?
    public var outputExcerpt: String
    public var outputExcerptTruncated: Bool
    enum CodingKeys: String, CodingKey {
        case id, source
        case sessionId = "session_id", userInput = "user_input", commandText = "command_text"
        case cwdBefore = "cwd_before", cwdAfter = "cwd_after", riskLevel = "risk_level"
        case confirmationStatus = "confirmation_status", startedAt = "started_at", endedAt = "ended_at"
        case exitCode = "exit_code", outputExcerpt = "output_excerpt", outputExcerptTruncated = "output_excerpt_truncated"
    }
    public init(id: Int64? = nil, sessionId: Int64, source: CommandSource, userInput: String? = nil,
                commandText: String, cwdBefore: String? = nil, cwdAfter: String? = nil,
                riskLevel: RiskLevel = .low, confirmationStatus: String = "auto",
                startedAt: Date = Date(), endedAt: Date? = nil, exitCode: Int? = nil,
                outputExcerpt: String = "", outputExcerptTruncated: Bool = false) {
        self.id = id; self.sessionId = sessionId; self.source = source.rawValue
        self.userInput = userInput; self.commandText = commandText
        self.cwdBefore = cwdBefore; self.cwdAfter = cwdAfter
        self.riskLevel = riskLevel.rawValue; self.confirmationStatus = confirmationStatus
        self.startedAt = startedAt; self.endedAt = endedAt; self.exitCode = exitCode
        self.outputExcerpt = outputExcerpt; self.outputExcerptTruncated = outputExcerptTruncated
    }
    public mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}
