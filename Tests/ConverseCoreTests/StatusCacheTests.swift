import XCTest
@testable import ConverseApp
import ConverseCore

/// 回归测试：status(for:) 必须读 DB 缓存值，不能在视图渲染期 spawn tmux（曾导致
/// SidebarView body 中同步 tmux has-session 阻塞主线程 → SwiftUI precondition_failure 崩溃）。
final class StatusCacheTests: XCTestCase {

    @MainActor
    func testStatusReadsCachedDBValueNotLiveTmux() throws {
        let state = AppState(dbPath: ":memory:")

        var folder = Folder(name: "T", diskPath: "/tmp", sortOrder: 1, isArchived: false)
        _ = try state.db.createFolder(&folder)
        let fid = try XCTUnwrap(folder.id)

        var session = SessionRecord(
            folderId: fid, name: "s",
            initialCwd: "/tmp", currentCwd: "/tmp",
            shellPath: "/bin/zsh", tmuxSessionName: "conv_test_no_such_session_12345",
            status: .running, restorePolicy: "keep_alive", sortOrder: 1
        )
        _ = try state.db.createSession(&session)

        XCTAssertEqual(state.status(for: session), .running)
    }

    @MainActor
    func testStatusDefaultsToMissingForGarbageValue() throws {
        let state = AppState(dbPath: ":memory:")

        var folder = Folder(name: "T", diskPath: "/tmp", sortOrder: 1, isArchived: false)
        _ = try state.db.createFolder(&folder)
        let fid = try XCTUnwrap(folder.id)

        var session = SessionRecord(
            folderId: fid, name: "s",
            initialCwd: "/tmp", currentCwd: "/tmp",
            shellPath: "/bin/zsh", tmuxSessionName: "x",
            status: .running, restorePolicy: "keep_alive", sortOrder: 1
        )
        session.status = "garbage"
        _ = try state.db.createSession(&session)

        XCTAssertEqual(state.status(for: session), .missing)
    }
}
