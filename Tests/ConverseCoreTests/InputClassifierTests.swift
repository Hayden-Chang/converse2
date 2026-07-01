import XCTest
@testable import ConverseCore

final class InputClassifierTests: XCTestCase {

    private let emptyPath = InputClassifier(pathDirs: [])

    func testEmptyInputIsNaturalLanguage() {
        XCTAssertEqual(emptyPath.classify(""), .naturalLanguage)
    }

    func testWhitespaceOnlyInputIsNaturalLanguage() {
        XCTAssertEqual(emptyPath.classify("    \t  "), .naturalLanguage)
    }

    func testBuiltinLsIsShellCommand() {
        XCTAssertEqual(emptyPath.classify("ls -la"), .shellCommand)
    }

    func testBuiltinCdIsShellCommand() {
        XCTAssertEqual(emptyPath.classify("cd .."), .shellCommand)
    }

    func testBuiltinExportIsShellCommand() {
        XCTAssertEqual(emptyPath.classify("export FOO=bar"), .shellCommand)
    }

    func testBuiltinEchoIsShellCommand() {
        XCTAssertEqual(emptyPath.classify("echo hi"), .shellCommand)
    }

    func testBuiltinPwdNoArgsIsShellCommand() {
        XCTAssertEqual(emptyPath.classify("pwd"), .shellCommand)
    }

    func testAbsolutePathIsShellCommand() {
        XCTAssertEqual(emptyPath.classify("/bin/ls"), .shellCommand)
    }

    func testRelativePathIsShellCommand() {
        XCTAssertEqual(emptyPath.classify("./build.sh"), .shellCommand)
        XCTAssertEqual(emptyPath.classify("../scripts/run.sh --fast"), .shellCommand)
        XCTAssertEqual(emptyPath.classify("scripts/foo"), .shellCommand)
    }

    func testUnknownTokenWithEmptyPathIsNaturalLanguage() {
        XCTAssertEqual(emptyPath.classify("git status"), .naturalLanguage)
        XCTAssertEqual(emptyPath.classify("some-unknown-cmd --flag"), .naturalLanguage)
    }

    func testPathHitMakesShellCommand() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let fakeGit = tmp.appendingPathComponent("git")
        let created = FileManager.default.createFile(atPath: fakeGit.path, contents: Data())
        XCTAssertTrue(created)

        let classifier = InputClassifier(pathDirs: [tmp.path])
        XCTAssertEqual(classifier.classify("git status"), .shellCommand)
        XCTAssertEqual(classifier.classify("git push origin main"), .shellCommand)
    }

    func testPathMissStaysNaturalLanguage() {
        let classifier = InputClassifier(pathDirs: ["/this/does/not/exist"])
        XCTAssertEqual(classifier.classify("git status"), .naturalLanguage)
    }

    func testPureCJKSingleTokenIsNaturalLanguage() {
        XCTAssertEqual(emptyPath.classify("列出大文件"), .naturalLanguage)
    }

    func testMixedCommandPlusCJKIsNaturalLanguage() {
        XCTAssertEqual(emptyPath.classify("git 看看状态"), .naturalLanguage)
        XCTAssertEqual(emptyPath.classify("open 当前目录"), .naturalLanguage)
        XCTAssertEqual(emptyPath.classify("ls 显示所有文件"), .naturalLanguage)
    }

    func testMixedCommandPlusCJKEvenWhenInPathIsNaturalLanguage() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        _ = FileManager.default.createFile(
            atPath: tmp.appendingPathComponent("git").path, contents: Data())

        let classifier = InputClassifier(pathDirs: [tmp.path])
        XCTAssertEqual(classifier.classify("git 看看状态"), .naturalLanguage)
    }

    func testQuotedFirstToken() {
        XCTAssertEqual(emptyPath.classify("\"my file.txt\" foo bar"), .naturalLanguage)
    }

    func testContainsCJKStaticHelper() {
        XCTAssertFalse(InputClassifier.containsCJK(""))
        XCTAssertFalse(InputClassifier.containsCJK("ls -la git status"))
        XCTAssertTrue(InputClassifier.containsCJK("看看状态"))
        XCTAssertTrue(InputClassifier.containsCJK("abc 你好 def"))
        XCTAssertFalse(InputClassifier.containsCJK("カタカナ only kana"))
    }

    func testFirstTokenStaticHelper() {
        XCTAssertNil(InputClassifier.firstToken(""))
        XCTAssertNil(InputClassifier.firstToken("   "))
        XCTAssertEqual(InputClassifier.firstToken("ls -la"), "ls")
        XCTAssertEqual(InputClassifier.firstToken("/bin/ls"), "/bin/ls")
        XCTAssertEqual(InputClassifier.firstToken("pwd"), "pwd")
        XCTAssertEqual(InputClassifier.firstToken("\"my file\" x"), "my file")
        XCTAssertEqual(InputClassifier.firstToken("'single word' y"), "single word")
        XCTAssertEqual(InputClassifier.firstToken("\"unclosed quote"), "unclosed quote")
    }

    func testIsInPathStaticHelperWithEmptyEnv() {
        XCTAssertFalse(InputClassifier.isInPath("definitely-not-a-real-cmd-xyz"))
    }
}
