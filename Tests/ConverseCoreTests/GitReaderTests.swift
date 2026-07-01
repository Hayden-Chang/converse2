import XCTest
@testable import ConverseCore

final class GitReaderTests: XCTestCase {

    func testParsePorcelainMixed() {
        let out = " M README.md\n?? new.txt\nA  staged.txt\nD  gone.txt\n"
        let changes = GitReader.parsePorcelain(out)
        XCTAssertEqual(changes.count, 4)

        XCTAssertEqual(changes[0].path, "README.md")
        XCTAssertEqual(changes[0].stagedStatus, " ")
        XCTAssertEqual(changes[0].worktreeStatus, "M")
        XCTAssertFalse(changes[0].isUntracked)

        XCTAssertEqual(changes[1].path, "new.txt")
        XCTAssertEqual(changes[1].stagedStatus, "?")
        XCTAssertEqual(changes[1].worktreeStatus, "?")
        XCTAssertTrue(changes[1].isUntracked)

        XCTAssertEqual(changes[2].path, "staged.txt")
        XCTAssertEqual(changes[2].stagedStatus, "A")
        XCTAssertEqual(changes[2].worktreeStatus, " ")

        XCTAssertEqual(changes[3].path, "gone.txt")
        XCTAssertEqual(changes[3].stagedStatus, "D")
        XCTAssertEqual(changes[3].worktreeStatus, " ")
    }

    func testParsePorcelainEmpty() {
        XCTAssertEqual(GitReader.parsePorcelain(""), [])
    }

    func testParsePorcelainSkipsBlankLines() {
        let out = "\n M a.txt\n\n?? b.txt\n"
        let changes = GitReader.parsePorcelain(out)
        XCTAssertEqual(changes.count, 2)
        XCTAssertEqual(changes[0].path, "a.txt")
        XCTAssertEqual(changes[1].path, "b.txt")
    }

    func testLabels() {
        XCTAssertEqual(GitFileChange(path: "a", stagedStatus: " ", worktreeStatus: "M").label, "修改")
        XCTAssertEqual(GitFileChange(path: "a", stagedStatus: "A", worktreeStatus: " ").label, "新增")
        XCTAssertEqual(GitFileChange(path: "a", stagedStatus: "D", worktreeStatus: " ").label, "删除")
        XCTAssertEqual(GitFileChange(path: "a", stagedStatus: "?", worktreeStatus: "?").label, "未跟踪")
    }
}
