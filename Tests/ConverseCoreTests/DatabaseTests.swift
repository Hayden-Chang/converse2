import XCTest
@testable import ConverseCore

final class DatabaseTests: XCTestCase {

    private func makeDb() throws -> AppDatabase {
        try AppDatabase(path: ":memory:")
    }

    func testFolderInsertAndReadBack() throws {
        let db = try makeDb()
        var folder = Folder(name: "proj-A", diskPath: "/tmp/proj-a", sortOrder: 2, isArchived: true)
        try db.createFolder(&folder)
        XCTAssertNotNil(folder.id)
        let read = try db.allFolders()
        XCTAssertEqual(read.count, 1)
        let f = try XCTUnwrap(read.first)
        XCTAssertEqual(f.name, "proj-A")
        XCTAssertEqual(f.diskPath, "/tmp/proj-a")
        XCTAssertEqual(f.sortOrder, 2)
        XCTAssertTrue(f.isArchived)
        XCTAssertNotNil(f.createdAt)
    }

    func testSessionInsertAndFilterByFolder() throws {
        let db = try makeDb()
        var folder = Folder(name: "f1", diskPath: "/tmp/f1")
        try db.createFolder(&folder)
        let fid = try XCTUnwrap(folder.id)

        var s1 = SessionRecord(folderId: fid, name: "s1", initialCwd: "/tmp/f1",
                               currentCwd: "/tmp/f1", shellPath: "/bin/zsh")
        var s2 = SessionRecord(folderId: fid, name: "s2", initialCwd: "/tmp/f1",
                               currentCwd: "/tmp/f1/sub", shellPath: "/bin/zsh",
                               status: .missing, sortOrder: 1)
        try db.createSession(&s1)
        try db.createSession(&s2)
        XCTAssertNotNil(s1.id)
        XCTAssertNotNil(s2.id)

        let sessions = try db.sessions(folderId: fid)
        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions.map(\.name).sorted(), ["s1", "s2"])
        XCTAssertEqual(sessions.first(where: { $0.name == "s2" })?.statusEnum, .missing)
        XCTAssertEqual(s2.tmuxSessionName, nil)
    }

    func testSettingsDefaultsAndWriteRead() throws {
        let db = try makeDb()
        let settings = SettingsService(db: db)
        XCTAssertEqual(settings.aiMode, .suggest)
        XCTAssertEqual(settings.defaultShell, "/bin/zsh")
        XCTAssertEqual(settings.apiBaseUrl, "https://api.deepseek.com")
        XCTAssertEqual(settings.model, "deepseek-v4-flash")
        XCTAssertEqual(settings.apiKeyRef, "env:DEEPSEEK_API_KEY")
        XCTAssertEqual(settings.outputExcerptLimit, 8192)
        XCTAssertEqual(settings.confirmationPolicy, .standard)
        XCTAssertEqual(settings.keywordMatchLimit, 3)

        try settings.setString(SettingsService.Key.aiMode, AiMode.off.rawValue)
        XCTAssertEqual(settings.aiMode, .off)

        try settings.setString(SettingsService.Key.outputExcerptLimit, "4096")
        XCTAssertEqual(settings.outputExcerptLimit, 4096)

        try settings.setString(SettingsService.Key.aiMode, AiMode.errorAssist.rawValue)
        XCTAssertEqual(settings.aiMode, .errorAssist)
    }

    func testKeychainRoundTrip() throws {
        let account = "test_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(6))"
        let value = "sk-secret-\(UUID().uuidString)"
        KeychainStore.delete(account)
        KeychainStore.set(value, for: account)
        let got = KeychainStore.get(account)
        XCTAssertEqual(got, value)
        KeychainStore.delete(account)
        let afterDelete = KeychainStore.get(account)
        XCTAssertNil(afterDelete)
    }

    func testKeychainResolveEnvRef() {
        let key = "MY_KEY_\(UUID().uuidString.prefix(6))"
        let value = "env-value"
        let ref = "env:\(key)"
        XCTAssertEqual(KeychainStoreResolve.resolveApiKey(ref: ref, env: [key: value]), value)
        XCTAssertNil(KeychainStoreResolve.resolveApiKey(ref: ref, env: [:]))
    }
}
