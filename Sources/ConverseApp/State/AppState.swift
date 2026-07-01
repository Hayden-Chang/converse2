import SwiftUI
import ConverseCore

@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var showSettings = false
    @Published var showCommandPalette = false
    @Published var aiMode: AiMode = .suggest
    @Published var inputDraft: String = ""
    @Published var inputFocusToken: Int = 0
    @Published var paletteInitialTab: PaletteTab = .sessions

    @Published var folders: [Folder] = []
    @Published var selectedFolderID: Int64?
    @Published var selectedSessionID: String?

    let db: AppDatabase
    let tmux = TmuxManager()

    init() {
        self.db = (try? AppDatabase.shared()) ?? (try! AppDatabase(path: ":memory:"))
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "converse.onboarded")
        reload()
    }

    internal init(dbPath: String) {
        self.db = (try? AppDatabase(path: dbPath)) ?? (try! AppDatabase(path: ":memory:"))
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "converse.onboarded")
        reload()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "converse.onboarded")
    }

    var settings: SettingsService { SettingsService(db: db) }

    func fillInput(_ text: String) {
        inputDraft = text
        inputFocusToken += 1
    }

    func reload() {
        folders = (try? db.allFolders()) ?? []
        syncStatuses()
        let orphaned = tmux.orphanedConverseSessions(recordedIDs: allRecordedShortIDs())
        if !orphaned.isEmpty {
            print("[Converse] \(orphaned.count) orphaned converse_ tmux session(s) detected (not auto-cleaned).")
        }
    }

    func syncStatuses() {
        for folder in folders {
            for session in sessions(in: folder) {
                guard let id = session.id else { continue }
                let live = tmux.hasSession(id: tmuxShortID(for: session))
                try? db.updateSessionStatus(id, live ? .running : .missing)
            }
        }
    }

    private func allRecordedShortIDs() -> [String] {
        folders.flatMap { sessions(in: $0) }.map { tmuxShortID(for: $0) }
    }

    func hasRunningSessions(in folder: Folder) -> Bool {
        sessions(in: folder).contains { status(for: $0) == .running }
    }

    func recreateSession(_ session: SessionRecord) {
        guard let id = session.id else { return }
        let sid = tmuxShortID(for: session)
        guard !tmux.hasSession(id: sid) else { reload(); return }
        do {
            try tmux.ensureSession(id: sid, cwd: session.currentCwd, shell: session.shellPath)
            try db.updateSessionStatus(id, .running)
        } catch {
            try? db.updateSessionStatus(id, .missing)
        }
        reload()
    }

    func forceCloseSession(_ session: SessionRecord) {
        guard let id = session.id else { return }
        let sid = tmuxShortID(for: session)
        tmux.killSession(id: sid)
        try? db.deleteSession(id)
        if selectedSessionID == sid { selectedSessionID = nil }
        reload()
    }

    func addFolder(name: String, diskPath: String) {
        let order = (try? db.maxFolderSortOrder()) ?? 0
        var f = Folder(name: name, diskPath: diskPath, sortOrder: order + 1, isArchived: false)
        _ = try? db.createFolder(&f)
        reload()
    }

    func sessions(in folder: Folder) -> [SessionRecord] {
        guard let fid = folder.id else { return [] }
        return (try? db.sessions(folderId: fid)) ?? []
    }

    func createSession(in folder: Folder, name: String, shell: String? = nil) {
        guard let fid = folder.id else { return }
        let order = (try? db.maxSessionSortOrder(folderId: fid)) ?? 0
        let shortID = "f\(fid)_\(Int(Date().timeIntervalSince1970))"
        let shellPath = shell ?? settings.defaultShell
        var status: SessionStatus = .running
        do {
            try tmux.ensureSession(id: shortID, cwd: folder.diskPath, shell: shellPath)
        } catch {
            status = .missing
        }
        var s = SessionRecord(
            folderId: fid, name: name,
            initialCwd: folder.diskPath, currentCwd: folder.diskPath,
            shellPath: shellPath, tmuxSessionName: shortID,
            status: status, restorePolicy: "keep_alive",
            sortOrder: order + 1
        )
        _ = try? db.createSession(&s)
        selectedFolderID = fid
        selectedSessionID = shortID
        reload()
    }

    func closeSession(_ session: SessionRecord) {
        guard let id = session.id else { return }
        let sid = tmuxShortID(for: session)
        tmux.killSession(id: sid)
        try? db.deleteSession(id)
        if selectedSessionID == sid { selectedSessionID = nil }
        reload()
    }

    func deleteFolder(_ folder: Folder) {
        guard let fid = folder.id else { return }
        for s in sessions(in: folder) { closeSession(s) }
        try? db.deleteFolder(fid)
        if selectedFolderID == fid { selectedFolderID = nil }
        reload()
    }

    func status(for session: SessionRecord) -> SessionStatus {
        session.statusEnum
    }

    func tmuxShortID(for session: SessionRecord) -> String {
        session.tmuxSessionName ?? (session.id.map(String.init) ?? "")
    }

    func selectedSession() -> SessionRecord? {
        guard let selected = selectedSessionID else { return nil }
        for f in folders {
            guard let fid = f.id else { continue }
            let list = (try? db.sessions(folderId: fid)) ?? []
            if let s = list.first(where: { tmuxShortID(for: $0) == selected }) {
                return s
            }
        }
        return nil
    }

    func runningCount() -> Int {
        folders.reduce(0) { $0 + sessions(in: $1).filter { status(for: $0) == .running }.count }
    }

    func missingCount() -> Int {
        folders.reduce(0) { $0 + sessions(in: $1).filter { status(for: $0) == .missing }.count }
    }
}
