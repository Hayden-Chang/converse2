import Foundation
import GRDB

public final class AppDatabase {
    public let dbQueue: DatabaseQueue

    public init(path: String) throws {
        if path != ":memory:" {
            let dir = (path as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
        dbQueue = try DatabaseQueue(path: path)
        try migrator.migrate(dbQueue)
    }

    public static func shared() throws -> AppDatabase {
        let fm = FileManager.default
        let appSupport = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = appSupport.appendingPathComponent("converse", isDirectory: true)
        return try AppDatabase(path: dir.appendingPathComponent("converse.sqlite").path)
    }

    private var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.create(table: "folders") { t in
                t.column("id", .integer).primaryKey(autoincrement: true)
                t.column("name", .text).notNull()
                t.column("disk_path", .text).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("sort_order", .integer).notNull().defaults(to: 0)
                t.column("is_archived", .integer).notNull().defaults(to: false)
            }
            try db.create(table: "sessions") { t in
                t.column("id", .integer).primaryKey(autoincrement: true)
                t.column("folder_id", .integer).notNull()
                t.column("name", .text).notNull()
                t.column("initial_cwd", .text).notNull()
                t.column("current_cwd", .text).notNull()
                t.column("shell_path", .text).notNull()
                t.column("tmux_session_name", .text); t.column("tmux_window_id", .text); t.column("tmux_pane_id", .text)
                t.column("status", .text).notNull()
                t.column("restore_policy", .text).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("last_active_at", .datetime).notNull()
                t.column("closed_at", .datetime)
                t.column("sort_order", .integer).notNull().defaults(to: 0)
            }
            try db.create(table: "command_runs") { t in
                t.column("id", .integer).primaryKey(autoincrement: true)
                t.column("session_id", .integer).notNull()
                t.column("source", .text).notNull(); t.column("user_input", .text)
                t.column("command_text", .text).notNull()
                t.column("cwd_before", .text); t.column("cwd_after", .text)
                t.column("risk_level", .text).notNull(); t.column("confirmation_status", .text).notNull()
                t.column("started_at", .datetime).notNull(); t.column("ended_at", .datetime); t.column("exit_code", .integer)
                t.column("output_excerpt", .text).notNull()
                t.column("output_excerpt_truncated", .integer).notNull().defaults(to: false)
            }
            try db.create(table: "ai_suggestions") { t in
                t.column("id", .integer).primaryKey(autoincrement: true)
                t.column("session_id", .integer).notNull(); t.column("command_run_id", .integer)
                t.column("provider", .text).notNull(); t.column("model", .text).notNull()
                t.column("prompt_version", .text).notNull()
                t.column("natural_language_input", .text).notNull()
                t.column("generated_command", .text).notNull(); t.column("explanation", .text)
                t.column("risk_level", .text).notNull(); t.column("status", .text).notNull()
                t.column("created_at", .datetime).notNull()
            }
            try db.create(table: "git_snapshots") { t in
                t.column("id", .integer).primaryKey(autoincrement: true)
                t.column("folder_id", .integer).notNull()
                t.column("repo_path", .text).notNull(); t.column("branch", .text)
                t.column("status_json", .text).notNull(); t.column("selected_file", .text)
                t.column("captured_at", .datetime).notNull()
            }
            try db.create(table: "app_settings") { t in
                t.column("key", .text).primaryKey()
                t.column("value", .text).notNull(); t.column("updated_at", .datetime).notNull()
            }
            try db.create(index: "idx_sessions_folder", on: "sessions", columns: ["folder_id"])
            try db.create(index: "idx_command_runs_session", on: "command_runs", columns: ["session_id"])
            try db.create(index: "idx_ai_suggestions_session", on: "ai_suggestions", columns: ["session_id"])
        }
        return m
    }
}

public extension AppDatabase {
    @discardableResult
    func createFolder(_ folder: inout Folder) throws -> Folder {
        try dbQueue.write { try folder.insert($0); return folder }
    }
    func allFolders() throws -> [Folder] {
        try dbQueue.read { try Folder.order(Column("sort_order")).fetchAll($0) }
    }
    @discardableResult
    func createSession(_ session: inout SessionRecord) throws -> SessionRecord {
        try dbQueue.write { try session.insert($0); return session }
    }
    func sessions(folderId: Int64) throws -> [SessionRecord] {
        try dbQueue.read { try SessionRecord.filter(sql: "folder_id = ?", arguments: [folderId]).order(Column("sort_order")).fetchAll($0) }
    }
    func updateFolderSortOrders(_ orders: [(id: Int64, sortOrder: Int)]) throws {
        try dbQueue.write { db in
            for o in orders {
                try db.execute(sql: "UPDATE folders SET sort_order = ? WHERE id = ?", arguments: [o.sortOrder, o.id])
            }
        }
    }
    func renameSession(_ id: Int64, to name: String) throws {
        try dbQueue.write { db in
            try db.execute(sql: "UPDATE sessions SET name = ? WHERE id = ?", arguments: [name, id])
        }
    }
    func deleteSession(_ id: Int64) throws {
        try dbQueue.write { db in _ = try SessionRecord.deleteOne(db, key: id) }
    }
    func deleteFolder(_ id: Int64) throws {
        try dbQueue.write { db in _ = try Folder.deleteOne(db, key: id) }
    }
    func updateSessionStatus(_ id: Int64, _ status: SessionStatus) throws {
        try dbQueue.write { db in
            try db.execute(sql: "UPDATE sessions SET status = ? WHERE id = ?", arguments: [status.rawValue, id])
        }
    }
    func maxFolderSortOrder() throws -> Int {
        try dbQueue.read { db in try Int.fetchOne(db, sql: "SELECT COALESCE(MAX(sort_order), 0) FROM folders") ?? 0 }
    }
    func maxSessionSortOrder(folderId: Int64) throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COALESCE(MAX(sort_order), 0) FROM sessions WHERE folder_id = ?", arguments: [folderId]) ?? 0
        }
    }
}
