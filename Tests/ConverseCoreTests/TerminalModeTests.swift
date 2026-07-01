import XCTest
@testable import ConverseApp

final class TerminalModeTests: XCTestCase {

    private func makeController() -> TerminalController {
        TerminalController()
    }

    func testTuiCommandEntersTerminalMode() {
        let c = makeController()
        c.notifyCommandSent("vim main.swift")
        XCTAssertTrue(c.terminalMode, "vim 应进入终端模式")
        XCTAssertFalse(c.awaitingPassword)
    }

    func testNonTuiCommandDoesNotEnterTerminalMode() {
        let c = makeController()
        c.notifyCommandSent("ls -la")
        XCTAssertFalse(c.terminalMode)
        XCTAssertFalse(c.awaitingPassword)
    }

    func testFullPathTuiCommandEntersTerminalMode() {
        let c = makeController()
        c.notifyCommandSent("/usr/bin/top")
        XCTAssertTrue(c.terminalMode, "带路径的 top 应进入终端模式")
    }

    func testCaseInsensitiveTuiCommand() {
        let c = makeController()
        c.notifyCommandSent("VIM file.txt")
        XCTAssertTrue(c.terminalMode, "大写 VIM 应进入终端模式")
    }

    func testSudoSetsAwaitingPassword() {
        let c = makeController()
        c.notifyCommandSent("sudo apt update")
        XCTAssertTrue(c.awaitingPassword, "sudo 命令应进入密码态")
        XCTAssertFalse(c.terminalMode, "sudo apt 不是 TUI，不应进入终端模式")
    }

    func testSudoTuiCommandSetsBoth() {
        let c = makeController()
        c.notifyCommandSent("sudo vim /etc/hosts")
        XCTAssertTrue(c.awaitingPassword, "sudo 应进入密码态")
        XCTAssertTrue(c.terminalMode, "sudo vim 应进入终端模式")
    }

    func testPasswordStateResetsOnNextRun() {
        let c = makeController()
        c.notifyCommandSent("sudo ls")
        XCTAssertTrue(c.awaitingPassword)
        c.notifyCommandSent("echo hi")
        XCTAssertFalse(c.awaitingPassword, "下次 run 非 sudo 时密码态应重置")
    }

    func testExitTerminalMode() {
        let c = makeController()
        c.notifyCommandSent("python3")
        XCTAssertTrue(c.terminalMode)
        c.exitTerminalMode()
        XCTAssertFalse(c.terminalMode)
    }

    func testClearPasswordState() {
        let c = makeController()
        c.notifyCommandSent("sudo whoami")
        XCTAssertTrue(c.awaitingPassword)
        c.clearPasswordState()
        XCTAssertFalse(c.awaitingPassword)
    }

    func testEmptyCommandDoesNothing() {
        let c = makeController()
        c.notifyCommandSent("   ")
        XCTAssertFalse(c.terminalMode)
        XCTAssertFalse(c.awaitingPassword)
    }

    func testRunInvokesNotifyCommandSent() {
        let c = makeController()
        c.run("less README.md")
        XCTAssertTrue(c.terminalMode, "run 应内部调用 notifyCommandSent 进入终端模式")
    }
}
