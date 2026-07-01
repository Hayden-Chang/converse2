import Foundation
import GRDB

public struct GitSnapshot: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "git_snapshots"
    public var id: Int64?
    public var folderId: Int64
    public var repoPath: String
    public var branch: String?
    public var statusJson: String
    public var selectedFile: String?
    public var capturedAt: Date
    enum CodingKeys: String, CodingKey {
        case id, branch
        case folderId = "folder_id", repoPath = "repo_path", statusJson = "status_json"
        case selectedFile = "selected_file", capturedAt = "captured_at"
    }
    public init(id: Int64? = nil, folderId: Int64, repoPath: String, branch: String? = nil,
                statusJson: String, selectedFile: String? = nil, capturedAt: Date = Date()) {
        self.id = id; self.folderId = folderId; self.repoPath = repoPath
        self.branch = branch; self.statusJson = statusJson; self.selectedFile = selectedFile
        self.capturedAt = capturedAt
    }
    public mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}
