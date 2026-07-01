import Foundation
import GRDB

public struct SessionRecord: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "sessions"
    public var id: Int64?
    public var folderId: Int64
    public var name: String
    public var initialCwd: String
    public var currentCwd: String
    public var shellPath: String
    public var tmuxSessionName: String?
    public var tmuxWindowId: String?
    public var tmuxPaneId: String?
    public var status: String
    public var restorePolicy: String
    public var createdAt: Date
    public var lastActiveAt: Date
    public var closedAt: Date?
    public var sortOrder: Int
    enum CodingKeys: String, CodingKey {
        case id, name, status
        case folderId = "folder_id", initialCwd = "initial_cwd", currentCwd = "current_cwd"
        case shellPath = "shell_path", tmuxSessionName = "tmux_session_name"
        case tmuxWindowId = "tmux_window_id", tmuxPaneId = "tmux_pane_id", restorePolicy = "restore_policy"
        case createdAt = "created_at", lastActiveAt = "last_active_at", closedAt = "closed_at", sortOrder = "sort_order"
    }
    public init(id: Int64? = nil, folderId: Int64, name: String, initialCwd: String, currentCwd: String,
                shellPath: String, tmuxSessionName: String? = nil, tmuxWindowId: String? = nil, tmuxPaneId: String? = nil,
                status: SessionStatus = .running, restorePolicy: String = "ask",
                createdAt: Date = Date(), lastActiveAt: Date = Date(), closedAt: Date? = nil, sortOrder: Int = 0) {
        self.id = id; self.folderId = folderId; self.name = name
        self.initialCwd = initialCwd; self.currentCwd = currentCwd; self.shellPath = shellPath
        self.tmuxSessionName = tmuxSessionName; self.tmuxWindowId = tmuxWindowId; self.tmuxPaneId = tmuxPaneId
        self.status = status.rawValue; self.restorePolicy = restorePolicy
        self.createdAt = createdAt; self.lastActiveAt = lastActiveAt; self.closedAt = closedAt; self.sortOrder = sortOrder
    }
    public var statusEnum: SessionStatus { SessionStatus(rawValue: status) ?? .missing }
    public mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}
