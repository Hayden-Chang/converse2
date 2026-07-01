import Foundation
import GRDB

public final class HistoryService {
    private let db: AppDatabase

    public init(db: AppDatabase) {
        self.db = db
    }

    @discardableResult
    public func recordRun(sessionId: Int64, source: CommandSource, userInput: String?, command: String,
                          cwdBefore: String?, cwdAfter: String?, risk: RiskLevel,
                          confirmation: String, exitCode: Int?, output: String) throws -> CommandRun {
        let cleaned = Sanitizer.sanitize(output)
        let (excerpt, truncated) = OutputSummarizer.summarize(cleaned)
        var run = CommandRun(id: nil, sessionId: sessionId, source: source, userInput: userInput,
                             commandText: command, cwdBefore: cwdBefore, cwdAfter: cwdAfter,
                             riskLevel: risk, confirmationStatus: confirmation,
                             startedAt: Date(), endedAt: exitCode != nil ? Date() : nil,
                             exitCode: exitCode, outputExcerpt: excerpt, outputExcerptTruncated: truncated)
        try db.dbQueue.write { try run.insert($0) }
        return run
    }

    public func recentCommands(sessionId: Int64, limit: Int = 50) throws -> [CommandRun] {
        try db.dbQueue.read {
            try CommandRun.filter(sql: "session_id = ?", arguments: [sessionId])
                .order(Column("started_at").desc, Column("id").desc)
                .fetchAll($0)
        }
    }

    public func searchCommands(sessionId: Int64?, keyword: String, limit: Int = 20) throws -> [CommandRun] {
        try db.dbQueue.read {
            var query = CommandRun.filter(sql: "command_text LIKE ?", arguments: ["%\(keyword)%"])
            if let sid = sessionId {
                query = query.filter(sql: "session_id = ?", arguments: [sid])
            }
            return try query.order(Column("started_at").desc, Column("id").desc).fetchAll($0)
        }
    }
}
