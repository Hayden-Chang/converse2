import Foundation
import GRDB

public struct Folder: Identifiable, Codable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "folders"
    public var id: Int64?
    public var name: String
    public var diskPath: String
    public var createdAt: Date
    public var updatedAt: Date
    public var sortOrder: Int
    public var isArchived: Bool
    enum CodingKeys: String, CodingKey {
        case id, name
        case diskPath = "disk_path", createdAt = "created_at", updatedAt = "updated_at"
        case sortOrder = "sort_order", isArchived = "is_archived"
    }
    public init(id: Int64? = nil, name: String, diskPath: String,
                createdAt: Date = Date(), updatedAt: Date = Date(), sortOrder: Int = 0, isArchived: Bool = false) {
        self.id = id; self.name = name; self.diskPath = diskPath
        self.createdAt = createdAt; self.updatedAt = updatedAt
        self.sortOrder = sortOrder; self.isArchived = isArchived
    }
    public mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}
