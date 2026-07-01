import SwiftUI
import ConverseCore

@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var showSettings = false
    @Published var showCommandPalette = false
    @Published var aiMode: AiMode = .suggest

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

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "converse.onboarded")
    }

    var settings: SettingsService { SettingsService(db: db) }

    func reload() {
        folders = (try? db.allFolders()) ?? []
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
        tmux.hasSession(id: tmuxShortID(for: session)) ? .running : .missing
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
