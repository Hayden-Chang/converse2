import XCTest
@testable import ConverseApp

final class TmuxParsingTests: XCTestCase {

    func testSessionNameConstruction() {
        XCTAssertEqual(TmuxManager.sessionName(for: "main"), "converse_main")
        XCTAssertEqual(TmuxManager.sessionName(for: "abc_123"), "converse_abc_123")
        XCTAssertEqual(TmuxManager.sessionName(for: ""), "converse_")
    }

    func testParseConverseSessionsFromLines() {
        let lines = [
            "8: 1 windows",
            "converse_main: 1 windows",
            "PNP: 3 windows",
            "converse_poc: 1 windows"
        ]
        XCTAssertEqual(TmuxManager.parseConverseSessionIDs(lines: lines), ["main", "poc"])
    }

    func testParseConverseSessionsFromRaw() {
        let raw = "8: 1 windows (created)\nconverse_main: 1 windows\nfoo: 2 windows\nconverse_poc: 1 windows\n"
        XCTAssertEqual(TmuxManager.parseConverseSessionIDs(rawLsOutput: raw), ["main", "poc"])
    }

    func testParseEmptyAndNone() {
        XCTAssertEqual(TmuxManager.parseConverseSessionIDs(lines: []), [])
        XCTAssertEqual(TmuxManager.parseConverseSessionIDs(lines: ["8: 1 windows", "foo: 2 windows"]), [])
    }

    func testParseSkipsNonConverseWithColonInName() {
        XCTAssertEqual(
            TmuxManager.parseConverseSessionIDs(lines: ["weird:name: 1 windows", "converse_x: 1 windows"]),
            ["x"]
        )
    }
}
