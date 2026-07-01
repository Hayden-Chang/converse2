import XCTest
@testable import ConverseCore

final class OutputSummarizerTests: XCTestCase {

    func testSmallOutputNotTruncated() throws {
        let lines = (1...50).map { "line\($0)" }
        let output = lines.joined(separator: "\n")
        let result = OutputSummarizer.summarize(output)
        XCTAssertEqual(result.excerpt, output)
        XCTAssertFalse(result.truncated)
    }

    func testTruncatesToLast200Lines() throws {
        let lines = (1...300).map { "line\($0)" }
        let output = lines.joined(separator: "\n")
        let result = OutputSummarizer.summarize(output)
        XCTAssertTrue(result.truncated)
        let kept = result.excerpt.components(separatedBy: "\n")
        XCTAssertEqual(kept.count, OutputSummarizer.maxLines)
        XCTAssertEqual(kept.last, "line300")
        XCTAssertEqual(kept.first, "line101")
    }

    func testHugeSingleLineTruncatedByBytes() throws {
        let output = String(repeating: "x", count: 9000)
        let result = OutputSummarizer.summarize(output)
        XCTAssertTrue(result.truncated)
        XCTAssertLessThanOrEqual(result.excerpt.utf8.count, OutputSummarizer.maxBytes + 200)
        XCTAssertEqual(result.excerpt.components(separatedBy: "\n").count, 1)
    }

    func testDisplaySplitOmitsMiddle() {
        let lines = (1...500).map { "l\($0)" }
        let split = OutputSummarizer.displaySplit(lines)
        let omitted = split.compactMap { if case .omitted(let n) = $0 { return n } else { return nil } }
        XCTAssertEqual(omitted, [100])
        XCTAssertEqual(split.count, 200 + 1 + 200)
        if case .line(let text) = split.first { XCTAssertEqual(text, "l1") }
        if case .line(let text) = split.last { XCTAssertEqual(text, "l500") }
    }

    func testDisplaySplitNoTruncationUnderThreshold() {
        let lines = (1...50).map { "l\($0)" }
        let split = OutputSummarizer.displaySplit(lines)
        XCTAssertEqual(split.count, 50)
        XCTAssertFalse(split.contains { if case .omitted = $0 { return true } else { return false } })
    }
}

final class HistoryServiceTests: XCTestCase {

    private func makeSession() throws -> (AppDatabase, Int64) {
        let db = try AppDatabase(path: ":memory:")
        var folder = Folder(name: "f", diskPath: "/tmp")
        try db.createFolder(&folder)
        let fid = try XCTUnwrap(folder.id)
        var session = SessionRecord(folderId: fid, name: "s", initialCwd: "/tmp",
                                    currentCwd: "/tmp", shellPath: "/bin/zsh")
        try db.createSession(&session)
        let sid = try XCTUnwrap(session.id)
        return (db, sid)
    }

    func testRecentCommandsOrderDesc() throws {
        let (db, sid) = try makeSession()
        let svc = HistoryService(db: db)
        _ = try svc.recordRun(sessionId: sid, source: .userDirect, userInput: nil,
                              command: "echo a", cwdBefore: "/tmp", cwdAfter: "/tmp",
                              risk: .low, confirmation: "auto", exitCode: 0, output: "a")
        _ = try svc.recordRun(sessionId: sid, source: .userDirect, userInput: nil,
                              command: "echo b", cwdBefore: "/tmp", cwdAfter: "/tmp",
                              risk: .low, confirmation: "auto", exitCode: 0, output: "b")
        _ = try svc.recordRun(sessionId: sid, source: .userDirect, userInput: nil,
                              command: "echo c", cwdBefore: "/tmp", cwdAfter: "/tmp",
                              risk: .low, confirmation: "auto", exitCode: 0, output: "c")

        let recent = try svc.recentCommands(sessionId: sid, limit: 10)
        XCTAssertEqual(recent.count, 3)
        XCTAssertEqual(recent.first?.commandText, "echo c")
        XCTAssertEqual(recent.last?.commandText, "echo a")
    }

    func testSearchByKeyword() throws {
        let (db, sid) = try makeSession()
        let svc = HistoryService(db: db)
        _ = try svc.recordRun(sessionId: sid, source: .userDirect, userInput: nil,
                              command: "git status", cwdBefore: nil, cwdAfter: nil,
                              risk: .low, confirmation: "auto", exitCode: 0, output: "ok")
        _ = try svc.recordRun(sessionId: sid, source: .userDirect, userInput: nil,
                              command: "ls -la", cwdBefore: nil, cwdAfter: nil,
                              risk: .low, confirmation: "auto", exitCode: 0, output: "files")

        let hits = try svc.searchCommands(sessionId: sid, keyword: "git")
        XCTAssertEqual(hits.count, 1)
        XCTAssertEqual(hits.first?.commandText, "git status")

        let all = try svc.searchCommands(sessionId: nil, keyword: "git")
        XCTAssertEqual(all.count, 1)
    }

    func testStoredOutputIsSummarized() throws {
        let (db, sid) = try makeSession()
        let svc = HistoryService(db: db)
        let bigOutput = (1...300).map { "out line \($0)" }.joined(separator: "\n")
        _ = try svc.recordRun(sessionId: sid, source: .aiSuggested, userInput: "list",
                              command: "dump", cwdBefore: nil, cwdAfter: nil,
                              risk: .medium, confirmation: "confirmed", exitCode: 0, output: bigOutput)

        let recent = try svc.recentCommands(sessionId: sid, limit: 5)
        let run = try XCTUnwrap(recent.first)
        XCTAssertLessThanOrEqual(run.outputExcerpt.components(separatedBy: "\n").count, OutputSummarizer.maxLines)
        XCTAssertTrue(run.outputExcerptTruncated)
    }
}
