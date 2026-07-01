import Foundation
import GRDB

public struct AppSetting: Codable, FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "app_settings"
    public var key: String
    public var value: String
    public var updatedAt: Date
    enum CodingKeys: String, CodingKey { case key, value; case updatedAt = "updated_at" }
    public init(key: String, value: String, updatedAt: Date = Date()) {
        self.key = key; self.value = value; self.updatedAt = updatedAt
    }
}

public final class SettingsService {
    private let db: AppDatabase
    public enum Key {
        public static let aiMode = "ai.mode", aiProvider = "ai.provider"
        public static let apiBaseUrl = "ai.api_base_url", apiKeyRef = "ai.api_key_ref"
        public static let model = "ai.model", strongModel = "ai.strong_model", routingPolicy = "ai.routing_policy"
        public static let defaultShell = "terminal.default_shell", tmuxNamespace = "terminal.tmux_namespace"
        public static let outputExcerptLimit = "history.output_excerpt_limit"
        public static let confirmationPolicy = "risk.confirmation_policy", keywordMatchLimit = "few_shot.keyword_match_limit"
    }
    public init(db: AppDatabase) { self.db = db }

    public func getString(_ key: String, default fallback: String) -> String { read(key) ?? fallback }
    public func getInt(_ key: String, default fallback: Int) -> Int { read(key).flatMap(Int.init) ?? fallback }
    public func setString(_ key: String, _ value: String) throws {
        try db.dbQueue.write { conn in
            try conn.execute(sql: """
                INSERT INTO app_settings (key, value, updated_at) VALUES (?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
                """, arguments: [key, value, Date()])
        }
    }
    private func read(_ key: String) -> String? {
        try? db.dbQueue.read { conn in
            try AppSetting.fetchOne(conn, sql: "SELECT * FROM app_settings WHERE key = ?", arguments: [key])?.value
        }
    }
    public var aiMode: AiMode { AiMode(rawValue: getString(Key.aiMode, default: AiMode.suggest.rawValue)) ?? .suggest }
    public var apiBaseUrl: String { getString(Key.apiBaseUrl, default: "https://api.deepseek.com") }
    public var model: String { getString(Key.model, default: "deepseek-v4-flash") }
    public var strongModel: String { getString(Key.strongModel, default: "deepseek-v4-flash") }
    public var apiKeyRef: String { getString(Key.apiKeyRef, default: "env:DEEPSEEK_API_KEY") }
    public var defaultShell: String { getString(Key.defaultShell, default: "/bin/zsh") }
    public var tmuxNamespace: String { getString(Key.tmuxNamespace, default: "converse") }
    public var outputExcerptLimit: Int { getInt(Key.outputExcerptLimit, default: 8192) }
    public var confirmationPolicy: ConfirmationPolicy {
        ConfirmationPolicy(rawValue: getString(Key.confirmationPolicy, default: ConfirmationPolicy.standard.rawValue)) ?? .standard
    }
    public var keywordMatchLimit: Int { getInt(Key.keywordMatchLimit, default: 3) }
    public var routingPolicy: String { getString(Key.routingPolicy, default: "default") }
}
